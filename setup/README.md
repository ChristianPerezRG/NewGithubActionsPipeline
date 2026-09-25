# Setup

Everything needed to make the three workflows in `.github/workflows/` run against real databases.

The workflows are the official Redgate samples from
[Flyway-Sample-Pipelines/github-actions/workflows/flyway-actions](https://github.com/red-gate/Flyway-Sample-Pipelines/tree/main/github-actions/workflows/flyway-actions),
used unmodified. Everything below exists to satisfy what they expect.

---

## 1. Databases

`provision.ps1` creates five databases on `localhost`:

| Database | State | Used by |
|---|---|---|
| `Northwind_Build` | empty | `deploy-build.yml` — wiped and rebuilt every run |
| `Northwind_Check` | empty | check reports in `deploy-build.yml` and `deploy-prod.yml` — erased every run |
| `Northwind_QA` | seeded with Northwind | `deploy-qa.yml` |
| `Northwind_Prod1` | seeded with Northwind | `deploy-prod.yml` |
| `Northwind_Prod2` | seeded with Northwind | `deploy-prod.yml`, and the target of the prod check report |

Build and Check start **empty** on purpose — they're throwaway. QA and the two Prods start at
the `V001` state so that `V002` is genuinely pending against them.

```powershell
cd setup
.\provision.ps1 -Password (Read-Host -AsSecureString "sa password")

# Start over:
.\provision.ps1 -Password (Read-Host -AsSecureString "sa password") -Force
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
| `FLYWAY_TOKEN` | Flyway Enterprise personal access token from the Redgate portal |
| `FIRST_UNDO_SCRIPT` | `001.20260925090000` |
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

> **`instructions.md` is out of date on this.** It lists `DB_USER_NAME_QA`, `DB_USER_PW_QA` and
> `DB_NAME_PROD_2`. The official workflows use the twelve secrets above instead, and never
> reference `DB_NAME_PROD_2` — the report artifact is named by the action, not by a variable.

---

## 4. Self-hosted runner

All three workflows use `runs-on: self-hosted`, so a runner must be registered to the repo:
*Settings > Actions > Runners > New self-hosted runner* (Windows).

The runner does **not** need Flyway pre-installed — `red-gate/setup-flyway@v3` downloads and
licenses Flyway 13.4.0 per job. It does need Git for Windows, and each workflow prepends Git Bash
to `PATH` because the Redgate actions run their steps under `shell: bash`.

---

## 5. Branches

| Branch | Workflow | Trigger |
|---|---|---|
| `Development` | `deploy-build.yml` | push touching `migrations/**` |
| `QA` | `deploy-qa.yml` | push touching `migrations/**` |
| `Production` | `deploy-prod.yml` | push touching `migrations/**` |

---

## 6. Approval gate (optional)

`deploy-prod.yml` ships with no approval gate — the upstream sample only comments on the option.
To add one: create a `production` GitHub Environment with required reviewers, then add
`environment: production` to the `flyway-deploy-prod-1` and `flyway-deploy-prod-2` jobs. Leave
`flyway-report` outside it so reviewers can read the report before approving.

This is the one change worth making to the upstream files. It's deliberately not applied yet.
