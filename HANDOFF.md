# Handoff — Flyway + GitHub Actions pipeline

**Target repo:** https://github.com/ChristianPerezRG/NewGithubActionsPipeline
**Goal:** a working Flyway Enterprise pipeline against real SQL Server databases on `localhost`,
using Redgate's official GitHub Actions sample workflows unmodified.

---

## What's here

```
.github/workflows/
  deploy-build.yml     # Development branch -> Build DB (clean/migrate/undo) + QA check report
  deploy-qa.yml        # QA branch          -> QA DB
  deploy-prod.yml      # Production branch  -> report vs Prod2, then Prod1 + Prod2
flyway.toml            # committed project config
flyway.user.toml       # GITIGNORED - local sa credentials for the five databases
.gitignore
migrations/
  B001_20260925090000__baseline_northwind.sql          # Northwind schema + data (~1 MB), BASELINE migration
  V002_20260925091500__add_customer_loyalty.sql        # demo change
  U002_20260925091500__UNDO-add_customer_loyalty.sql   # paired undo
setup/
  provision.ps1        # creates and seeds the five databases
  README.md            # exact Variables/Secrets values, runner setup
HANDOFF.md             # this file
```

### The three workflows are upstream files, used verbatim

They come from
[red-gate/Flyway-Sample-Pipelines → github-actions/workflows/flyway-actions](https://github.com/red-gate/Flyway-Sample-Pipelines/tree/main/github-actions/workflows/flyway-actions)
and are **not to be rewritten**. They use `red-gate/setup-flyway@v3` (pinned to Flyway 13.4.0) plus
`red-gate/flyway-actions@v2` composite actions, so the runner needs no pre-installed Flyway CLI.

Everything else in the repo exists to satisfy what those files expect. If something doesn't line
up, change the supporting config — not the workflows.

---

## Environment (machine `US-LT-CHRISTIAN`, set up 2026-09-25)

| Thing | Where / value |
|---|---|
| SQL Server | **SQL Server 2022 Express (16.0.1000.6)**, default instance `MSSQLSERVER`, TCP **1433** fixed, SQL + Windows auth. Service auto-start. `RED-GATE\Christian.Perez` is sysadmin. |
| `sa` password | `C:\Users\christian.perez\tools\sa-password.txt` (also in the gitignored `flyway.user.toml`) |
| Databases | `Northwind_Build`, `Northwind_Check` (empty); `Northwind_QA`, `Northwind_Prod1`, `Northwind_Prod2` (seeded, 13 tables, **no** schema history yet) |
| Flyway CLI | `C:\Users\christian.perez\tools\flyway-13.4.0\flyway.cmd` — licensed **Enterprise** via `flyway auth` (Redgate online auth). Not on PATH. |
| GitHub CLI | `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GitHub.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\gh.exe`, logged in as ChristianPerezRG. Not on PATH until a new shell. |
| Runner | `C:\actions-runner`, Windows service `actions.runner.ChristianPerezRG-NewGithubActionsPipeline.US-LT-CHRISTIAN` (NETWORK SERVICE, delayed auto-start). Labels `self-hosted,Windows,X64,sqlserver-local`. |
| Install media | `C:\Users\christian.perez\SQLExpressMedia` — can be deleted. |

### GitHub repo state

- `main` pushed with everything above.
- **Variables set:** `USER_EMAIL`, `JDBC_BUILD`, `JDBC_QA`, `JDBC_CHECK`, `JDBC_PROD1`, `JDBC_PROD2`
- **Secrets set:** `FIRST_UNDO_SCRIPT` (= `002.20260925091500`), `DB_USER_*` (= `sa`) and `DB_USER_PW_*` for BUILD/QA/CHECK/PROD1/PROD2
- **Secret NOT yet set:** `FLYWAY_TOKEN` — needs a Flyway Enterprise personal access token from
  https://identityprovider.red-gate.com/personaltokens for the `USER_EMAIL` account. Every job fails at
  "Setup Flyway" until this exists.
- Branches `Development`, `QA`, `Production` exist locally, not yet pushed (pushing triggers the runs).

---

## Verified against real databases (Flyway 13.4.0 Enterprise, local CLI)

| Check | Result |
|---|---|
| `provision.ps1` | Works first time. 5 DBs, 3 seeded with 13 tables. |
| Build from empty (`clean` + `migrate`) | B001 then V002 applied, ~1.5 s. |
| `undo -target=002.20260925091500` | Undoes V002 cleanly, Build left at 001. |
| `migrate` against a seeded copy (what deploy-qa does) | "Successfully baselined schema with version 001.20260925090000", V002 applied, B001 shown as `Ignored (Baseline)`. `baselineVersion` is right. |
| `check -changes -drift -dryrun -code` with build env `check`, invoked with the exact flags the checks action passes | Exit 0 both against a not-yet-deployed seeded copy and against a baselined + V002 copy. HTML/JSON/SARIF produced. |

## Two things the first handoff got wrong (fixed)

1. **V001 had to become B001.** With a plain versioned V001 as the baseline, `flyway check`
   could not rebuild the Check DB to match a baselined target: Flyway skips V001 (below/at
   baseline) and V002 then fails with "Cannot find the object dbo.Customers". A Flyway
   *baseline migration* (`B` prefix) is designed for exactly this: it runs on empty databases
   (Build, Check) and is skipped on databases baselined at that version (QA, Prod). Reproduced
   and verified.
2. **`FIRST_UNDO_SCRIPT` is `002.20260925091500`, not `001…`.** `undo -target` is inclusive —
   targeting 001 tries to undo the baseline itself and errors "no corresponding undo migration".

## Expected behaviour on the first pipeline runs

- **Development → deploy-build:** Build is reprovisioned (clean) and rebuilt, V002 undone, then
  the QA check report runs. On this very first run the drift section will report the whole
  Northwind schema as drift, because QA has no schema history / snapshot yet. `fail-on-drift`
  is `false` there, so the job still passes. A `drift-resolution` artifact is uploaded. After
  QA has been deployed once (snapshot saved), later reports should show no drift.
- **QA → deploy-qa:** baselines QA at 001, applies V002, saves a snapshot. The deploy action
  logs "Drift check not run - skipped because no snapshot in database (expected for initial
  deployment)".
- **Production → deploy-prod:** report vs Prod2 (same first-run drift caveat), then Prod1 and
  Prod2 deploy in parallel, same as QA.

---

## Open questions

1. **`instructions.md` (in Downloads, not in the repo) conflicts with the official workflows** on
   secret names (`DB_USER_NAME_QA` / `DB_NAME_PROD_2`) and on `FIRST_UNDO_SCRIPT` (`001`).
   Resolved in favour of the workflows. Update or drop `instructions.md`.
2. **No approval gate on production.** Adding `environment: production` to the two deploy jobs
   is the one upstream edit worth making — see `setup/README.md` §6. Deliberately not applied.
3. **`sa` everywhere.** Fine for a local demo; wrong for a ProServ reference. Config-only fix.
4. **`localhost` in the JDBC strings** only works because the runner is on the SQL Server machine.
5. **Northwind vs. `DemoDB` naming.** Databases are `Northwind_*`.

---

## Things that will bite

- **Git Bash on PATH.** Each workflow prepends `C:\Program Files\Git\bin` because the Redgate
  actions run under `shell: bash`. Don't remove those steps.
- **`provisioner = "clean"` on `[environments.build]`** is required for `provision-mode: reprovision`.
- **`cleanDisabled`** is `true` globally; the Build step overrides it inline, and the checks action
  passes `-environments.check.flyway.cleanDisabled=false` because of `build-ok-to-erase: true`.
- **`flyway check -drift` writes a `drift-resolution/` folder into the working directory.**
  It's gitignored now; it slipped into an early commit once.
- **Flyway reads `_` as a version separator**, so `B001_20260925090000` is version
  `001.20260925090000`. `baselineVersion` and `FIRST_UNDO_SCRIPT` are full dotted versions.
- **Installing SQL Server on this laptop** failed twice on Windows Installer error 1706 because the
  cached sources for the already-installed ODBC Driver 17 (17.10.6.1) and OLE DB Driver 18
  (18.7.4.0) were gone. Fix was to download those exact MSIs, name them `msodbcsql.msi` /
  `msoledbsql.msi`, and re-run `msiexec /i` to re-register the source before SQL setup.
