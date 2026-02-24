# Assessment Training Chain Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extend the current execution chain so `orchestrator` can route to `assessment` and `training-advice` with live model responses and writeback evidence.

**Architecture:** Keep the existing auth/RLS/writeback baseline, add modular routing in `orchestrator`, and implement two new edge functions mirroring `chat-casual` behavior but writing to domain tables (`assessments`, `training_plans`). Validate with live e2e and CI deployment updates.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), PostgreSQL (Supabase), Bash tests, curl/jq, GitHub Actions.

### Task 1: Add failing tests for new chain coverage

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Create: `tests/e2e/test_orchestrator_assessment_training_live.sh`
- Modify: `tests/ci/test_workflow_presence.sh`

**Step 1: Write the failing tests**

- Extend function-chain test to assert presence of:
  - `supabase/functions/assessment/index.ts`
  - `supabase/functions/training-advice/index.ts`
  - router mapping hooks in `supabase/functions/orchestrator/index.ts`
- Add e2e script existence assertions for assessment-training smoke.
- Extend CI workflow presence test to require deployment of `assessment` and `training-advice`.

**Step 2: Run tests to verify failure**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/ci/test_workflow_presence.sh`

Expected: FAIL before implementation.

### Task 2: Implement orchestrator modular routing

**Files:**
- Modify: `supabase/functions/orchestrator/index.ts`

**Step 1: Implement minimal routing changes**

- Add optional `module` in payload.
- Map module to function/action:
  - `chat_casual -> chat-casual / chat_casual_reply`
  - `assessment -> assessment / assessment_generate`
  - `training_advice -> training-advice / training_advice_generate`
- Keep backward compatibility (`chat_casual` default).
- Reuse idempotency with dynamic action name.

**Step 2: Run function file test**

Run: `bash tests/functions/test_chain_files.sh`
Expected: still FAIL until new function files exist.

### Task 3: Implement `assessment` and `training-advice` edge functions

**Files:**
- Create: `supabase/functions/assessment/index.ts`
- Create: `supabase/functions/training-advice/index.ts`

**Step 1: Implement minimal live behavior**

- Both functions:
  - authenticate + child access check
  - call live model via `_shared/model-router.ts`
  - insert assistant message into `chat_messages`
  - domain write + `finalizeWriteback`
  - return SSE `stream_start/delta/done`
- `assessment` writes `assessments`.
- `training-advice` writes `training_plans`.

**Step 2: Run tests**

Run:
- `bash tests/functions/test_chain_files.sh`

Expected: PASS.

### Task 4: Add live e2e for assessment-training chain

**Files:**
- Create: `tests/e2e/test_orchestrator_assessment_training_live.sh`

**Step 1: Implement e2e script**

- Create test user/child/care team.
- Call `orchestrator` twice:
  - module `assessment`
  - module `training_advice`
- Assert:
  - SSE done events
  - records in `assessments` + `training_plans`
  - `operation_logs` with expected action names
  - `snapshot_refresh_events` per request
- Add cleanup trap for created records.

**Step 2: Run test**

Run: `bash tests/e2e/test_orchestrator_assessment_training_live.sh`
Expected: PASS.

### Task 5: Update CI workflow and final verification evidence

**Files:**
- Modify: `.github/workflows/db-rebuild-and-chain-smoke.yml`
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`

**Step 1: CI deployment update**

- Deploy `assessment` and `training-advice` in workflow before smoke tests.

**Step 2: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`

Expected: PASS with both e2e scripts.

**Step 3: Update verification doc**

- Record command evidence and latest run IDs/timestamp.

### Task 6: Commit changes

**Files:**
- All touched files above.

**Step 1: Commit**

```bash
git add .
git commit -m "feat(chain): add orchestrator assessment and training advice live execution chain"
```
