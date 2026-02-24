# Training Memory Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure `training` writes `children_memory.current_focus` on successful plan generation.

**Architecture:** Add a `children_memory` upsert in `training`, extend chain/static tests with RED->GREEN flow, and verify live side effects and governance evidence with official Supabase.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Bash e2e tests, PostgREST/Auth APIs, jq/curl.

### Task 1: Add failing tests

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_training_live.sh`

**Step 1: Write failing assertions**

- Require `supabase/functions/training/index.ts` to reference `children_memory`.
- In `test_orchestrator_training_live.sh` add checks:
  - `children_memory.current_focus` exists for the test child.
  - `operation_logs(action_name=training_generate).affected_tables` contains `children_memory`.

**Step 2: Run tests and verify RED**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_training_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement memory sync in `training`

**Files:**
- Modify: `supabase/functions/training/index.ts`

**Step 1: Upsert `children_memory`**

- Derive `current_focus` from user message + generated content.
- Upsert by `child_id` with:
  - `current_focus`
  - `last_interaction_summary`
  - `updated_at`

**Step 2: Extend writeback metadata**

- Add `children_memory` to `affectedTables`.
- Include memory id/current focus in payload.
- Set snapshot target to include profile + short-term context when memory changes.

### Task 3: Deploy and verify focused chain

**Step 1: Verify static + live tests**

Run:
- `bash tests/functions/test_chain_files.sh`
- `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`
- `bash tests/e2e/test_orchestrator_training_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

- Add latest UTC timestamp + request ID from live run.
- Record that `training_generate` now includes `children_memory` in `affected_tables`.

### Task 5: Final gate and commit

**Step 1: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`

Expected: PASS.

**Step 2: Commit**

```bash
git add .
git commit -m "feat(training): sync memory current_focus on writeback"
```
