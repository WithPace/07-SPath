# Training Advice Memory Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure `training-advice` writes `children_memory.current_focus` on successful plan generation.

**Architecture:** Extend `training-advice` function with `children_memory` upsert and update existing assessment-training live e2e to verify memory side effects and operation log metadata.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Supabase PostgREST/Auth APIs, Bash e2e tests, jq/curl.

### Task 1: Add failing tests

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_assessment_training_live.sh`

**Step 1: Add assertions**

- Require `training-advice` to reference `children_memory`.
- In assessment-training live e2e:
  - verify `children_memory.current_focus` for test child is non-empty
  - verify `operation_logs(action_name=training_advice_generate).affected_tables` includes `children_memory`

**Step 2: Run and confirm failure**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement memory sync in `training-advice`

**Files:**
- Modify: `supabase/functions/training-advice/index.ts`

**Step 1: Upsert current focus**

- Build concise focus string from request + generated plan summary.
- Upsert `children_memory` by `child_id`, writing:
  - `current_focus`
  - `last_interaction_summary`
  - `updated_at`

**Step 2: Update writeback metadata**

- Add `children_memory` to `affectedTables`.
- Include memory row id/current focus in payload.

### Task 3: Verify chain behavior

**Step 1: Run tests**

Run:
- `bash tests/functions/test_chain_files.sh`
- `supabase functions deploy training-advice --project-ref <ref> --use-api --no-verify-jwt`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence and assertions**

- Add latest run request IDs and UTC timestamp.
- Mention `children_memory` side effect for training-advice chain.

### Task 5: Final verification and commit

**Step 1: Run full gate**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Commit**

```bash
git add .
git commit -m "feat(training-advice): sync memory current_focus on writeback"
```
