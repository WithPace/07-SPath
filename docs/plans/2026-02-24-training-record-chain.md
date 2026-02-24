# Training Record Chain Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `orchestrator -> training-record` live execution chain with direct writes to `training_sessions` and full writeback evidence.

**Architecture:** Extend orchestrator modular routing, implement a new training-record edge function reusing shared auth/model/finalize modules, and verify with live e2e plus CI workflow presence checks.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Supabase PostgREST/Auth APIs, Bash tests, curl/jq.

### Task 1: Add failing tests for training-record chain

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/ci/test_workflow_presence.sh`
- Create: `tests/e2e/test_orchestrator_training_record_live.sh`

**Steps:**
1. Add file/keyword assertions for `training-record`.
2. Add workflow assertions for deployment + e2e script call.
3. Add e2e placeholder script that fails.
4. Run tests and verify failure.

### Task 2: Implement orchestrator routing

**Files:**
- Modify: `supabase/functions/orchestrator/index.ts`

**Steps:**
1. Add module mapping for `training_record`.
2. Map to function `training-record`.
3. Use dynamic action name `training_record_create` for idempotency.
4. Run function chain test and verify still pending until new function exists.

### Task 3: Implement training-record edge function

**Files:**
- Create: `supabase/functions/training-record/index.ts`

**Steps:**
1. Auth + child access checks.
2. Call live model and produce structured summary.
3. Write to `training_sessions`.
4. Write assistant message to `chat_messages`.
5. Call `finalizeWriteback` with training-record action metadata.
6. Return SSE done payload.

### Task 4: Implement live e2e and CI integration

**Files:**
- Modify: `.github/workflows/db-rebuild-and-chain-smoke.yml`
- Replace: `tests/e2e/test_orchestrator_training_record_live.sh`

**Steps:**
1. Add deployment of `training-record` in workflow.
2. Add workflow step to run new e2e.
3. Replace placeholder e2e with full live assertions and cleanup trap.
4. Deploy updated functions and run new live e2e.

### Task 5: Full verification and governance update

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Steps:**
1. Run `bash scripts/ci/final_gate.sh`.
2. Update verification evidence with training-record run IDs and timestamp.
3. Re-run governance and presence tests.

### Task 6: Commit

**Steps:**
1. Stage all touched files.
2. Commit with message:
   - `feat(chain): add training-record live execution chain`
