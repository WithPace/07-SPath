# Deploy Test Go-Live Runbook

## Purpose

This runbook defines the production deployment execution chain for Supabase Edge Functions in this repository.

## Prerequisites

1. Local `.env` exists and includes at least:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_DB_PASSWORD`
   - `DOUBAO_API_KEY`
   - `KIMI_API_KEY`
2. `SUPABASE_PROJECT_REF` is exported in shell or defined in `.env`.
3. Supabase CLI is installed and authenticated (`supabase login`), and your workspace is linked if required by your org policy.
   - default expected CLI version: `2.75.0` (managed by `scripts/ci/check_supabase_cli_version.sh`)
4. You are on the release commit intended for go-live.

## Preflight

```bash
bash scripts/db/preflight.sh
```

Expected:
- prints `project_ref=<ref>`
- no missing key failures
- if local CLI version is not `2.75.0`, prints warning (`WARN: must update supabase cli ...`) unless strict mode is enabled

Enable strict local blocking for version mismatch:

```bash
ENFORCE_SUPABASE_CLI_VERSION=1 bash scripts/db/preflight.sh
```

## Dry Run (No External Changes)

```bash
DRY_RUN=1 bash scripts/governance/check_phase2_signoff_gate.sh
DRY_RUN=1 bash scripts/governance/check_phase3_drill_signoff_gate.sh
DRY_RUN=1 bash scripts/ci/deploy_functions.sh
DRY_RUN=1 bash scripts/ci/release_go_live.sh
```

Expected:
- all commands are printed with `[DRY_RUN]`
- no deploy or test command is actually executed

## Deploy Functions Only

```bash
bash scripts/ci/deploy_functions.sh
```

Deploy target modules:
- `orchestrator`
- `chat-casual`
- `assessment`
- `training`
- `training-advice`
- `training-record`
- `dashboard`

## Full Go-Live Gate Sequence

```bash
bash scripts/ci/release_go_live.sh
```

This executes:
1. `bash scripts/governance/check_phase2_signoff_gate.sh`
2. `bash scripts/governance/check_phase3_drill_signoff_gate.sh`
3. `bash scripts/ci/deploy_functions.sh`
4. `bash scripts/ci/final_gate.sh`
5. `bash tests/governance/test_docs_presence.sh`
6. `bash tests/governance/test_e2e_governance.sh`
7. `bash scripts/governance/update_phase2_release_record.sh`

On success, step 7 updates `docs/governance/PHASE-2-RELEASE-RECORD.md` with:
- `commit_sha` (current `HEAD`)
- `executed_at_utc` (current UTC timestamp)
- `release_operator` (from local git user name unless overridden by env)
- `project_ref` (only when `SUPABASE_PROJECT_REF` is provided in environment)

`release_go_live.sh` defaults to strict sign-off gates:
- `REQUIRE_FULL_SIGNOFF=1`
- `REQUIRE_PHASE3_DRILL_SIGNOFF=1`

For pre-release preview with pending sign-off, override explicitly:

```bash
REQUIRE_FULL_SIGNOFF=0 REQUIRE_PHASE3_DRILL_SIGNOFF=0 DRY_RUN=1 bash scripts/ci/release_go_live.sh
```

## Rollback and Incident Drills

Run drills before or immediately after release windows:

```bash
DRY_RUN=1 bash scripts/ops/run_phase2_rollback_drill.sh
DRY_RUN=1 bash scripts/ops/run_phase3_rollback_drill.sh
DRY_RUN=1 bash scripts/ops/run_phase3_incident_drill.sh
```

For real execution, set `DRY_RUN=0` and provide required environment values.

## Frontend Simulator Scope

This repository currently contains backend/governance delivery for Supabase functions and release gates. Frontend simulator execution requires a separate frontend project/repository.

## Remote Publish Preparation (No Push)

After local main-branch integration and strict gate success, run:

```bash
RELEASE_TAG=release-main-2026-03-03 REQUIRE_ORIGIN=0 bash scripts/ci/prepare_remote_publish.sh
```

This command only validates cross-repo readiness and prints push commands; it does not execute push.

For strict mode that blocks when any repo lacks `origin` remote:

```bash
RELEASE_TAG=release-main-2026-03-03 REQUIRE_ORIGIN=1 bash scripts/ci/prepare_remote_publish.sh
```

Detailed remote publishing flow is documented in:
- `docs/governance/REMOTE-PUBLISH-RUNBOOK.md`
