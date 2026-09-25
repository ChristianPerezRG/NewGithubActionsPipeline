# Handoff — Flyway Desktop + GitHub Actions pipeline

**Target repo:** https://github.com/ChristianPerezRG/NewGithubActionsPipeline
**Goal:** a working Flyway Enterprise pipeline against real SQL Server databases on `localhost`,
using Redgate's official GitHub Actions sample workflows unmodified, with the **schema model as
the source of truth** and all migration scripts generated from it (Flyway Desktop flow).

---

## What's here

```
.github/workflows/
  deploy-build.yml     # TRIGGERED (push to main touching migrations/**): Build Database -> QA Check Report -> calls deploy-qa -> calls deploy-prod
  deploy-qa.yml        # workflow_call: Deploy QA -> Production Check Report
  deploy-prod.yml      # workflow_call: Production Check Report -> [approval] -> Deploy Prod
schema-model/          # SOURCE OF TRUTH. Northwind + loyalty change. Tables/, Views/, Stored Procedures/
migrations/            # GENERATED from schema-model, in this order:
  B001_20260925101351__baseline.sql              # baseline (schema only), from the model vs empty shadow
  V002_20260925101444__add_customer_loyalty.sql  # versioned, from the model vs shadow built to B001
  U002_20260925101444__add_customer_loyalty.sql  # paired undo, generated with V002
Filter.scpf            # Redgate compare filter (default). Committed - Flyway Desktop expects it.
flyway.toml            # project config incl. [flywayDesktop] + [redgateCompare] sections
flyway.user.toml       # GITIGNORED - local sa credentials for all local databases
setup/
  provision.ps1        # creates and seeds the five pipeline databases
  README.md            # Flyway Desktop flow, Variables/Secrets values, runner requirements
HANDOFF.md             # this file
```

### How the contents were produced (2026-09-25, Flyway 13.4.0 Enterprise CLI)

Order matters and mirrors what a developer does in Flyway Desktop:

1. `Northwind_Dev` seeded with the stock Microsoft Northwind script (the "existing database").
2. `flyway diff model -diff.source=development -diff.target=schemaModel` → `schema-model/` (35 objects).
3. `flyway diff generate -diff.source=schemaModel -diff.target=migrations -diff.buildEnvironment=shadow -generate.types=baseline -generate.version=001_20260925101351 -generate.description=baseline` → `B001…__baseline.sql`.
4. Loyalty change applied to `Northwind_Dev` (LoyaltyTier column on Customers, CustomerLoyaltyLog table, FK, index).
5. `flyway diff model …` again → schema model updated (2 files).
6. `flyway diff generate … -generate.types=versioned,undo -generate.version=002_20260925101444 -generate.description=add_customer_loyalty` → `V002…` and `U002…`.

An earlier iteration hand-wrote V001/V002/U002 with data. That was thrown away.

### Three files matching Azure Simple-Workflow, shown as ONE run

Per the user's requests: (a) three .yml files that mirror
[red-gate/Flyway-Sample-Pipelines → Azure/Simple-Workflow](https://github.com/red-gate/Flyway-Sample-Pipelines/tree/main/Azure/Simple-Workflow)
command for command (plain Flyway CLI: `info clean info`, `migrate info`, `undo info`,
`check -code -changes -drift -dryrun`); (b) one consolidated run view - `deploy-build.yml` is
triggered by a push to `main` touching `migrations/**` and chains `deploy-qa.yml` then
`deploy-prod.yml` via `workflow_call` + `secrets: inherit`, so Build, QA and Production appear on
one page; (c) no Prod2. The approval before Deploy Prod is the `production` GitHub Environment
(required reviewer: ChristianPerezRG; deployment branch rules: `main`, `Production`).
Earlier iterations: `flyway-actions` composite-action samples verbatim; three Azure-shaped
workflows on Development/QA/Production branches; a single flyway-pipeline.yml. The old branches
are dormant (no workflow files) and can be deleted.

---

## Environment (machine `US-LT-CHRISTIAN`)

| Thing | Where / value |
|---|---|
| SQL Server | **SQL Server 2022 Express (16.0.1000.6)**, default instance `MSSQLSERVER`, TCP **1433** fixed, SQL + Windows auth, auto-start. `RED-GATE\Christian.Perez` is sysadmin. |
| `sa` password | `C:\Users\christian.perez\tools\sa-password.txt` (also in the gitignored `flyway.user.toml`) |
| Pipeline DBs | `Northwind_Build`, `Northwind_Check` (empty); `Northwind_QA`, `Northwind_Prod1`, `Northwind_Prod2` (seeded, 13 tables, **no** schema history until first deploy) |
| Dev DBs | `Northwind_Dev` (Northwind + loyalty change = current schema model), `Northwind_Shadow` (throwaway) |
| Flyway CLI | `C:\Users\christian.perez\tools\flyway-13.4.0\flyway.cmd` — licensed **Enterprise** via `flyway auth`. Not on PATH. |
| PowerShell 7 | `C:\Program Files\PowerShell\7\pwsh.exe` (7.6.6), machine-wide. Required by the workflows' `shell: pwsh` step. |
| GitHub CLI | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GitHub.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\gh.exe`, logged in as ChristianPerezRG. |
| Runner | `C:\actions-runner`, Windows service `actions.runner.ChristianPerezRG-NewGithubActionsPipeline.US-LT-CHRISTIAN` (NETWORK SERVICE). Labels `self-hosted,Windows,X64,sqlserver-local`. |
| Install media | `C:\Users\christian.perez\SQLExpressMedia`, `C:\Users\christian.perez\tools\PowerShell-win-x64.msi` — can be deleted. |

### GitHub repo state

- **Variables:** `USER_EMAIL`, `BASELINE_VERSION`, `JDBC_BUILD`, `JDBC_QA`, `JDBC_CHECK`, `JDBC_PROD1`, `JDBC_PROD2`
- **Secrets:** `FLYWAY_TOKEN`, `FIRST_UNDO_SCRIPT` (= `002.20260925101444`), `DB_USER_*` (= `sa`) and
  `DB_USER_PW_*` for BUILD/QA/CHECK/PROD1/PROD2
- Branches: `main` is the only branch that triggers the pipeline.

---

## Verified locally against real databases

| Check | Result |
|---|---|
| Schema model vs migrations (`flyway diff`, shadow build) | No differences — model and scripts agree. |
| Build from empty (`clean` + `migrate`) | B001 then V002 applied. |
| `undo -target=002.20260925101444` | Undoes V002, Build left at 001. |
| `check -changes -drift -dryrun -code` with the exact flags the checks action passes, against a seeded no-history copy | Exit 0, HTML/JSON/SARIF produced. |
| `migrate` against the seeded copy (what deploy-qa does) | Baselined at 001, V002 applied, B001 shown `Ignored (Baseline)`. |

## Things that bit, and their fixes

- **`pwsh: command not found`** on the runner — the workflows' "Add Git Bash to PATH" step uses
  `shell: pwsh`. Fixed by installing PowerShell 7 machine-wide and restarting the runner service.
- **Baseline must be a `B` migration.** With a plain `V001` as baseline, `flyway check` cannot
  rebuild the Check DB to match a baselined target (V001 skipped, V002 fails). Flyway Desktop's
  baseline generation produces a `B` script for exactly this reason.
- **`FIRST_UNDO_SCRIPT` is the first version that has an undo script**, i.e. `002.…`, because
  `undo -target` is inclusive.
- **New branches don't trigger path-filtered workflows** on their first push. The next push that
  touches `migrations/**` does.
- **`flyway check -drift` writes `drift-resolution/`** into the working directory; gitignored.
- **First-run drift.** Until QA/Prod have been deployed once (and a snapshot saved), the check
  reports show the entire Northwind schema as drift. `fail-on-drift: false` keeps those jobs green.
  The deploy action skips the drift check on a first deployment ("no snapshot in database").
- **Installing SQL Server** hit Windows Installer 1706 twice: the cached sources for the already
  installed ODBC Driver 17 (17.10.6.1) and OLE DB Driver 18 (18.7.4.0) were gone. Fix: download
  those exact MSIs, name them `msodbcsql.msi` / `msoledbsql.msi`, `msiexec /i` to re-register.
- **Runner service install failed** with "ACL not in canonical form" because the folder was created
  from Git Bash. `icacls C:\actions-runner /reset /T` then reconfigure.
- **Flyway Desktop rewrites `flyway.toml` on first open** (drops comments, reorders keys, adds `id`). On 2026-09-25 it also left a fragment of the old file after its own content, producing "Error parsing config file ... filterFile". Fix: keep its normalized version and delete everything after `[redgateCompare]`.

---
- **Old Flyway Desktop writes `[flyway.check] majorTolerance = 0`**, which Flyway 13 rejects ("Removed: flyway.check.majorTolerance"). The pipelines pin 13.4.0, so delete that section if it reappears, and update Flyway Desktop.

## Open questions

1. **Baseline has no data.** Flyway Desktop's baseline is schema-only, so Build/Check/Shadow have
   empty tables while QA/Prod carry Northwind data. Fine for this pipeline; use Flyway Desktop's
   static-data tracking if reference data should be versioned too.
2. **No approval gate on production.** `environment: production` on the two deploy jobs is the one
   upstream edit worth making — see `setup/README.md` §6. Deliberately not applied.
3. **`sa` everywhere.** Config-only to tighten.
4. **`localhost` in the JDBC strings** only works because the runner is on the SQL Server machine.
5. **`instructions.md` (in Downloads, not the repo)** still lists `DB_USER_NAME_QA` / `DB_NAME_PROD_2`
   and `FIRST_UNDO_SCRIPT = 001`; the official workflows use the values in `setup/README.md`.
