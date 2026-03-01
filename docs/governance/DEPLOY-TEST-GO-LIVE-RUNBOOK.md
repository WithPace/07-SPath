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
4. You are on the release commit intended for go-live.

## Preflight

```bash
bash scripts/db/preflight.sh
```

Expected:
- prints `project_ref=<ref>`
- no missing key failures

## Dry Run (No External Changes)

```bash
DRY_RUN=1 bash scripts/governance/check_phase2_signoff_gate.sh
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
1. `bash scripts/ci/deploy_functions.sh`
2. `bash scripts/ci/final_gate.sh`
3. `bash tests/governance/test_docs_presence.sh`
4. `bash tests/governance/test_e2e_governance.sh`

To hard-block release unless all sign-offs are approved:

```bash
REQUIRE_FULL_SIGNOFF=1 bash scripts/governance/check_phase2_signoff_gate.sh
REQUIRE_FULL_SIGNOFF=1 bash scripts/ci/release_go_live.sh
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
