# Setup

Everything needed to make the three workflows in `.github/workflows/` run against real databases.

The three workflows in `.github/workflows/` are a GitHub Actions port of Redgate's
[Flyway-Sample-Pipelines/Azure/Simple-Workflow](https://github.com/red-gate/Flyway-Sample-Pipelines/tree/main/Azure/Simple-Workflow)
(`deploy-build.yml`, `deploy-qa.yml`, `deploy-prod.yml`): same stages, same Flyway CLI commands,
same variables. Azure stages are GitHub jobs chained with `needs`; Azure variable groups are repo
Variables/Secrets; the Azure `ManualValidation` stage is the `production` GitHub Environment with a
required reviewer; `PublishBuildArtifacts` is `actions/upload-artifact`. `red-gate/setup-flyway`
installs Flyway 13.4.0 on the runner per job, so nothing is pre-installed.

**One run, not three.** `deploy-build.yml` is the only file with push/pull_request triggers. After its Build
stages pass it calls `deploy-qa.yml`, then `deploy-prod.yml`, as reusable workflows
(`workflow_call`), so every stage shows on a single run page - no clicking from Build to QA to
Production. `deploy-qa.yml` / `deploy-prod.yml` can still be queued alone with *Run workflow*.

**Branch flow and triggers** (`migrations/**` must have changed in both cases):

| Event | What runs |
|---|---|
| Pull request from a feature branch **into `Dev`** | Build Database + QA Check Report only. Validates the scripts and attaches the QA report to the PR for the reviewer. Nothing is deployed. |
| Pull request **merged into `Dev`** (a push to `Dev`) | The full pipeline: Build Database → QA Check Report → Deploy QA → Production Check Report → approval → Deploy Prod. |
| *Run workflow* on "Flyway Pipeline" | Full pipeline, manually. |

Runs are serialized (`concurrency: flyway-pipeline`) because Build and Check are shared databases.

| File | Jobs |
|---|---|
| `deploy-build.yml` | **Build Database** (`info clean info` → `migrate info` → `undo info -target=FIRST_UNDO_SCRIPT`) → **QA Check Report** (artifact `qa-check-report`) → calls QA → calls Production |
| `deploy-qa.yml` | **Deploy QA** (`info migrate info`) → **Production Check Report** (promotion preview, artifact `prod-check-report-after-qa`) |
| `deploy-prod.yml` | **Production Check Report** (fresh, artifact `prod-check-report`) → **Deploy Prod** (waits for approval on the `production` environment). No second tenant. |

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
5. Commit to a **feature branch**, push, open a pull request into `Dev`. The PR runs the Build
   stages and attaches the QA check report. Merging the PR starts the full pipeline.

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
| `Northwind_Build` | empty | job 1 — wiped and rebuilt every run |
| `Northwind_Check` | empty | jobs 2 and 4 — erased every run |
| `Northwind_QA` | seeded with Northwind | jobs 2 and 3 |
| `Northwind_Prod1` | seeded with Northwind | jobs 4 and 5 |
| `Northwind_Prod2` | seeded with Northwind | not used by the consolidated pipeline (was the second tenant) |

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
| `BASELINE_VERSION` | `001.20260925101351` — version of the B001 baseline migration (Azure `BASELINE_VERSION`) |
| `JDBC_BUILD` | `jdbc:sqlserver://localhost;databaseName=Northwind_Build;encrypt=true;trustServerCertificate=true` |
| `JDBC_QA` | `jdbc:sqlserver://localhost;databaseName=Northwind_QA;encrypt=true;trustServerCertificate=true` |
| `JDBC_CHECK` | `jdbc:sqlserver://localhost;databaseName=Northwind_Check;encrypt=true;trustServerCertificate=true` |
| `JDBC_PROD1` | `jdbc:sqlserver://localhost;databaseName=Northwind_Prod1;encrypt=true;trustServerCertificate=true` |

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

The workflows keep a separate login per environment so you can grant least privilege in a real
deployment. For this demo they're all `sa`; in production the Check and report logins should be
read-only against the environments they inspect.

---

## 4. Self-hosted runner

All three workflows use `runs-on: self-hosted`, so a runner must be registered to the repo:
*Settings > Actions > Runners > New self-hosted runner* (Windows). Install it as a service.

The runner does **not** need Flyway pre-installed — `red-gate/setup-flyway@v3` downloads and
licenses Flyway 13.4.0 per job. Steps run under `shell: cmd`, like Azure `script` steps on a
Windows agent, so no Git Bash or PowerShell 7 requirement.

---

## 5. Branches

| Branch | Role |
|---|---|
| `feature/*` (any name) | Developer work. Flyway Desktop commits (schema model + generated migrations) land here. |
| `Dev` | Default branch and the pipeline trigger. Changes arrive only by merging a pull request. A merge runs Build → QA → approval → Production. |
| `main` | Kept as a stable copy; not watched by the pipeline. Promote `Dev` → `main` however the team prefers. |

Note: GitHub does not evaluate the `paths` filter on the *first* push of a brand-new branch.

---

## 6. Approval gate

`Deploy Prod` has `environment: production`, and that environment (*Settings > Environments >
production*) has **Required reviewers** set. The run pauses after the Production Check Report;
open the run, read the `prod-check-report` artifact, then *Review deployments* → approve.

The environment's deployment branch rules allow `Dev` (and `main`). Both were created with the GitHub API;
to recreate by hand: create environment `production`, tick *Required reviewers* and add
yourself, and under *Deployment branches* add `main`.

---

## 7. Reusing this for PostgreSQL

The workflows contain nothing SQL Server specific; the database comes from the JDBC URLs and
`flyway.toml`. For a Postgres copy of this pipeline:

- **Separate repo/project per database.** A Flyway Desktop project is one database type
  (`databaseType` in `flyway.toml`), and the schema model format differs between SQL Server and
  Postgres. Clone this repo and regenerate `schema-model/` + `B001` from the Postgres dev database.
- **JDBC variables**: `jdbc:postgresql://<host>:5432/<db>` for `JDBC_BUILD/QA/CHECK/PROD1`; a
  Postgres login per environment in the `DB_USER_*` / `DB_USER_PW_*` secrets. The Postgres driver
  ships inside Flyway; nothing to install on the runner.
- **Schemas**: Postgres environments should pin `schemas = ["public"]` (or the app schema) in
  `flyway.toml`, otherwise `clean` and the check reports act on the login's default search path.
- **`-errorOverrides=S0001:0:I-`** only matters for SQL Server `PRINT` output; it is harmless on
  Postgres and can be removed from the `FLYWAY` variable.
- **Undo scripts**: Flyway Desktop generates them for Postgres too; `FIRST_UNDO_SCRIPT` and
  `BASELINE_VERSION` are set exactly the same way.
- **Runner**: the steps use `shell: cmd` and Windows paths because the runner is Windows. On a
  Linux runner switch the four `shell: cmd` lines to `bash` and the `\` in the two `-locations`
  / `-configFiles` / `-reportFilename` paths to `/` (or let Flyway resolve relative paths).
