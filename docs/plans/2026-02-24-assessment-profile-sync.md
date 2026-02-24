# Assessment Profile Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `assessment` write a new `children_profiles` version on each successful assessment, with auditable live evidence.

**Architecture:** Extend `assessment` edge function with profile recompute/versioning logic and update existing assessment-training e2e to verify profile side effects plus operation log metadata.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Supabase PostgREST/Auth APIs, Bash e2e tests, jq/curl.

### Task 1: Add failing tests for assessment profile writeback

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_assessment_training_live.sh`

**Step 1: Add assertions**

- Require `assessment` function to reference `children_profiles`.
- In live e2e:
  - verify at least one `children_profiles` row for assessment user/child
  - verify assessment operation log `affected_tables` includes `children_profiles`

**Step 2: Verify failure before implementation**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`

Expected: FAIL before production code changes.

### Task 2: Implement assessment profile version sync

**Files:**
- Modify: `supabase/functions/assessment/index.ts`

**Step 1: Add domain helpers**

- Domain keyword mapping and focus domain inference.
- Domain level normalization/clamp helpers.
- Risk-based score baseline and trend derivation.

**Step 2: Insert new profile version**

- Read latest profile by `child_id`.
- Build next `domain_levels` and `overall_summary`.
- Insert `children_profiles` with `version + 1`.

**Step 3: Update finalize metadata**

- Include `children_profiles` in `affectedTables`.
- Include profile id/version/domain in payload.
- Keep assessment action name unchanged (`assessment_generate`).

### Task 3: Verify runtime chain

**Files:**
- No new files

**Step 1: Run focused checks**

Run:
- `bash tests/functions/test_chain_files.sh`
- `supabase functions deploy assessment --project-ref <ref> --use-api --no-verify-jwt`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`

Expected: PASS with profile writeback evidence.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Add latest run evidence**

- Record latest assessment request id and timestamp.
- Mention `children_profiles` coverage for assessment chain.

### Task 5: Final verification and commit

**Step 1: Run full gate**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Commit**

```bash
git add .
git commit -m "feat(assessment): sync profile versions on live writeback"
```
