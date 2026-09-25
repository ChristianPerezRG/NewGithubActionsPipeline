# Handoff — Flyway + GitHub Actions pipeline

Context for picking this up in Claude Code CLI, where the shell can actually reach SQL Server.

**Target repo:** https://github.com/ChristianPerezRG/NewGithubActionsPipeline (currently empty)
**Goal:** a working Flyway Enterprise pipeline against real SQL Server databases on `localhost`,
using Redgate's official GitHub Actions sample workflows unmodified.

---

## What's here

```
.github/workflows/
  deploy-build.yml     # Development branch -> Build DB
  deploy-qa.yml        # QA branch          -> QA DB
  deploy-prod.yml      # Production branch  -> Prod1 + Prod2
flyway.toml            # committed project config
.gitignore
migrations/
  V001_20260925090000__baseline_northwind.sql          # Northwind schema + data (~1 MB)
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

## Status: verified vs. not

### Verified (statically)

- All three workflows parse as valid YAML; jobs and dependencies resolve
- Migration filenames match the enforced `V{version}_{timestamp}__{description}.sql` pattern
- V002 and U002 pair correctly on version `002.20260925091500`
- `baselineVersion` in `flyway.toml` matches V001's resolved version `001.20260925090000`
- V001 is clean UTF-8, 408 `GO` batches, no NUL bytes or replacement characters
- Every migration starts with the required `SET NUMERIC_ROUNDABORT OFF` header
- The 6 variables and 12 secrets referenced by the workflows are all documented in `setup/README.md`

### NOT verified — nothing has touched a database

- `provision.ps1` has **never been executed**. Written blind, not debugged.
- V001 has never been run against SQL Server. It's the stock Microsoft Northwind script with a
  header prepended, but Flyway's SQL Server parser has not been asked to chew through it.
- V002/U002 have never been run. The `sp_refreshview` calls name five views by string; if any name
  is wrong it fails at runtime, not at parse time.
- `baselineVersion` is the highest-risk guess in the whole setup. One `flyway info` settles it.
- No self-hosted runner exists yet.

---

## Run this first

```powershell
# 1. Provision. Expect to debug this — it's never been run.
cd setup
.\provision.ps1 -Password (Read-Host -AsSecureString "sa password")

# 2. Prove V001 builds from empty, against the Build DB.
flyway migrate -url="jdbc:sqlserver://localhost;databaseName=Northwind_Build;encrypt=true;trustServerCertificate=true" `
               -user=sa -password=<pw> -locations="filesystem:migrations"

# 3. Prove the undo works — this is what deploy-build.yml validates.
flyway undo -target=001.20260925090000 -url="...Northwind_Build..." -user=sa -password=<pw> `
            -locations="filesystem:migrations"

# 4. THE IMPORTANT ONE. Against a seeded DB, V001 must show as 'Baseline' or 'Ignored'
#    and V002 as 'Pending'. If V001 shows 'Pending', baselineVersion is wrong.
flyway info -url="jdbc:sqlserver://localhost;databaseName=Northwind_QA;encrypt=true;trustServerCertificate=true" `
            -user=sa -password=<pw> -locations="filesystem:migrations"
```

Steps 2–4 catch everything that could go wrong before a runner is involved at all.

---

## Open questions

1. **`instructions.md` conflicts with the official workflows on secret names.** It specifies
   `DB_USER_NAME_QA` / `DB_USER_PW_QA` / `DB_NAME_PROD_2`; the workflows use twelve per-environment
   secrets and no `DB_NAME_PROD_2`. Resolved in favour of the workflows. Confirm that's right, and
   consider updating `instructions.md` so the repo doesn't ship contradicting itself.

2. **No approval gate on production.** The upstream `deploy-prod.yml` only comments on the option.
   Adding `environment: production` to the two deploy jobs is the one upstream edit worth making —
   see `setup/README.md` §6. Deliberately not applied.

3. **`sa` everywhere.** Fine for a local demo; wrong for a ProServ reference. The workflows already
   separate logins per environment, so tightening this is config-only — Check and report logins
   should be read-only.

4. **`localhost` in the JDBC strings** only works if the runner is on the same machine as SQL Server.

5. **Northwind vs. the `instructions.md` DemoDB naming.** Databases are `Northwind_*`. Rename if the
   ProServ demo should read as `DemoDB`.

---

## Things that will bite

- **Git Bash on PATH.** Each workflow prepends `C:\Program Files\Git\bin` because the Redgate actions
  run under `shell: bash`, and Git for Windows' default install exposes only `Git\cmd`. Without it,
  `bash` resolves to WSL and can't read Windows paths. Don't remove those steps.
- **`provisioner = "clean"` on `[environments.build]`** is required — `deploy-build.yml` uses
  `provision-mode: reprovision`, which is what actually wipes the Build DB. Remove it and the build
  stops being a real from-scratch test, silently.
- **`cleanDisabled`** is `true` globally and overridden for Build only, inline in the workflow.
- **V001 is ~1 MB / 9,376 lines.** Slow first Build run. Not a hang.
- **Flyway reads `_` as a version separator**, so `V001_20260925090000` is version
  `001.20260925090000`, not `001`. This is why `baselineVersion` and `FIRST_UNDO_SCRIPT` are both
  full dotted versions rather than `001`.
