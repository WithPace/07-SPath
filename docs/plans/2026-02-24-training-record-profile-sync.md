# Training Record Profile Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure `training-record` writes incremental `children_profiles` versions and provides auditable writeback evidence.

**Architecture:** Extend `training-record` edge function with local domain scoring/versioning logic, then assert profile side effects in existing live smoke test and governance evidence docs.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Supabase PostgREST/Auth APIs, Bash e2e tests, jq/curl.

### Task 1: Add failing tests for profile writeback

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_training_record_live.sh`

**Step 1: Add test assertions**

- Static test requires `training-record` function to reference `children_profiles`.
- Live e2e requires:
  - at least one `children_profiles` row for the request child/user
  - populated `domain_levels`
  - `operation_logs.affected_tables` contains `children_profiles`

**Step 2: Run and verify failure**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_training_record_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement incremental profile update in `training-record`

**Files:**
- Modify: `supabase/functions/training-record/index.ts`

**Step 1: Add profile update helpers**

- Domain mapping from message/model text to one of six domains.
- Score/level clamping and trend derivation helpers.
- Merge/normalize domain_levels shape for next profile version.

**Step 2: Write new profile row**

- Query latest profile by `child_id` + `version desc`.
- Insert next version row with updated domain and `overall_summary`.
- Keep existing session + assistant message writes.

**Step 3: Update finalize metadata**

- Add `children_profiles` to `affectedTables`.
- Include profile id/version/domain in payload.
- Set snapshot target to reflect combined short/long-term impact.

### Task 3: Verify updated chain

**Files:**
- No new files

**Step 1: Run tests**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_training_record_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Record latest run evidence**

- Add latest training-record request id and updated timestamp.
- Mention `children_profiles` writeback coverage in assertions/output section.

### Task 5: Final verification and commit

**Step 1: Run gates**

Run:
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Commit**

```bash
git add .
git commit -m "feat(training-record): sync profile versions on live writeback"
```
