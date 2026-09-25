# Setup

Everything needed to make the three workflows in `.github/workflows/` run against real databases.

The workflows are the official Redgate samples from
[Flyway-Sample-Pipelines/github-actions/workflows/flyway-actions](https://github.com/red-gate/Flyway-Sample-Pipelines/tree/main/github-actions/workflows/flyway-actions),
used unmodified. Everything below exists to satisfy what they expect.

---

## 0. How the repo is meant to be used (Flyway Desktop flow)

```
schema-model/     <- source of truth. Developers save their dev-database changes here.
migrations/       <- generated FROM the schema model by Flyway Desktop:
                     B001 baseline first, then V/U pairs for each change.
Filter.scpf       <- Redgate compare filter used by schema model / generate / check.
flyway.toml       <- project config: environments, baselineVersion, Flyway Desktop settings.
flyway.user.toml  <- gitignored. Your local development + shadow connection strings.
```

1. Open the repo in Flyway Desktop (it reads `flyway.toml` + `flyway.user.toml`).
2. Change the **development** database (`Northwind_Dev`).
3. *Schema model* tab → save the changes to `schema-model/`.
4. *Generate migrations* tab → Flyway Desktop compares the schema model with the **shadow**
   database (rebuilt from `migrations/`) and writes `V###_<timestamp>__desc.sql` plus the undo
   `U###_<timestamp>__desc.sql`.
5. Commit + push. Pushes to `Development` / `QA` / `Production` that touch `migrations/**`
   run the corresponding pipeline.

The same steps with the CLI (what produced the current contents):

```powershell
flyway diff model    -diff.source=development -diff.target=schemaModel
flyway diff generate -diff.source=schemaModel -diff.target=migrations -diff.buildEnvironment=shadow `
                     -generate.types=versioned,undo -generate.description=my_change -generate.version=003_<yyyyMMddHHmmss>
```

---

## 1. Databases

`provision.ps1` creates the pipeline databases on `localhost`:

| Database | State | Used by |
|---|---|---|
| `Northwind_Build` | empty | `deploy-build.yml` — wiped and rebuilt every run |
| `Northwind_Check` | empty | check reports in `deploy-build.yml` and `deploy-prod.yml` — erased every run |
| `Northwind_QA` | seeded with Northwind | `deploy-qa.yml` |
| `Northwind_Prod1` | seeded with Northwind | `deploy-prod.yml` |
| `Northwind_Prod2` | seeded with Northwind | `deploy-prod.yml`, and the target of the prod check report |

Plus, for local development with Flyway Desktop (not created by `provision.ps1`):

| Database | State | Used by |
|---|---|---|
| `Northwind_Dev` | Northwind + your in-progress changes | Flyway Desktop development environment |
| `Northwind_Shadow` | empty; rebuilt from `migrations/` on demand | Flyway Desktop shadow environment |

Build, Check and Shadow start **empty** on purpose — they're throwaway. QA and the two Prods start at
the B001 state so that V002 is genuinely pending against them.

```powershell
cd setup
.\provision.ps1 -Password (Read-Host -AsSecureString "sa password")

# Start over:
.\provision.ps1 -Password (Read-Host -AsSecureString "sa password") -Force
```

`flyway.user.toml` template (gitignored; put your real password in):

```toml
[environments.development]
url = "jdbc:sqlserver://localhost;databaseName=Northwind_Dev;encrypt=true;trustServerCertificate=true"
user = "sa"
password = "..."
displayName = "Development database"

[environments.shadow]
url = "jdbc:sqlserver://localhost;databaseName=Northwind_Shadow;encrypt=true;trustServerCertificate=true"
user = "sa"
password = "..."
displayName = "Shadow database"
```

---

## 2. GitHub Actions Variables

*Settings > Secrets and variables > Actions > Variables*

| Variable | Value |
|---|---|
| `USER_EMAIL` | your Redgate account email |
| `JDBC_BUILD` | `jdbc:sqlserver://localhost;databaseName=Northwind_Build;encrypt=true;trustServerCertificate=true` |
| `JDBC_QA` | `jdbc:sqlserver://localhost;databaseName=Northwind_QA;encrypt=true;trustServerCertificate=true` |
| `JDBC_CHECK` | `jdbc:sqlserver://localhost;databaseName=Northwind_Check;encrypt=true;trustServerCertificate=true` |
| `JDBC_PROD1` | `jdbc:sqlserver://localhost;databaseName=Northwind_Prod1;encrypt=true;trustServerCertificate=true` |
| `JDBC_PROD2` | `jdbc:sqlserver://localhost;databaseName=Northwind_Prod2;encrypt=true;trustServerCertificate=true` |

`localhost` only resolves correctly if the self-hosted runner is on the same machine as SQL Server.
If it isn't, swap in the machine name or IP.

---

## 3. GitHub Actions Secrets

*Settings > Secrets and variables > Actions > Secrets*

| Secret | Value |
|---|---|
| `FLYWAY_TOKEN` | Flyway Enterprise personal access token from https://identityprovider.red-gate.com/personaltokens |
| `FIRST_UNDO_SCRIPT` | `002.20260925101444` — the **first version that has an undo script**. `undo -target` is inclusive, so pointing it at the baseline fails. |
| `DB_USER_BUILD` | `sa` |
| `DB_USER_PW_BUILD` | your `sa` password |
| `DB_USER_QA` | `sa` |
| `DB_USER_PW_QA` | your `sa` password |
| `DB_USER_CHECK` | `sa` |
| `DB_USER_PW_CHECK` | your `sa` password |
| `DB_USER_PROD1` | `sa` |
| `DB_USER_PW_PROD1` | your `sa` password |
| `DB_USER_PROD2` | `sa` |
| `DB_USER_PW_PROD2` | your `sa` password |

The workflows keep a separate login per environment so you can grant least privilege in a real
deployment. For this demo they're all `sa`; in production the Check and report logins should be
read-only against the environments they inspect.

---

## 4. Self-hosted runner

All three workflows use `runs-on: self-hosted`, so a runner must be registered to the repo:
*Settings > Actions > Runners > New self-hosted runner* (Windows). Install it as a service.

The runner does **not** need Flyway pre-installed — `red-gate/setup-flyway@v3` downloads and
licenses Flyway 13.4.0 per job. It does need:

- **Git for Windows** — each workflow prepends Git Bash to `PATH` because the Redgate actions run
  their steps under `shell: bash`.
- **PowerShell 7 (`pwsh`)**, installed machine-wide — the "Add Git Bash to PATH" step uses
  `shell: pwsh`. Windows PowerShell 5.1 is not enough; the job fails with `pwsh: command not found`.

---

## 5. Branches

| Branch | Workflow | Trigger |
|---|---|---|
| `Development` | `deploy-build.yml` | push touching `migrations/**` |
| `QA` | `deploy-qa.yml` | push touching `migrations/**` |
| `Production` | `deploy-prod.yml` | push touching `migrations/**` |

Note: GitHub does not evaluate the `paths` filter on the *first* push of a brand-new branch, so
creating a branch does not by itself trigger a run — the next push that touches `migrations/**` does.

---

## 6. Approval gate (optional)

`deploy-prod.yml` ships with no approval gate — the upstream sample only comments on the option.
To add one: create a `production` GitHub Environment with required reviewers, then add
`environment: production` to the `flyway-deploy-prod-1` and `flyway-deploy-prod-2` jobs. Leave
`flyway-report` outside it so reviewers can read the report before approving.

This is the one change worth making to the upstream files. It's deliberately not applied yet.
