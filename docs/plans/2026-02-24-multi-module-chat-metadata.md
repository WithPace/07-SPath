# Multi-Module Chat Metadata Consistency Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure all modules that write assistant `chat_messages` include `chat_messages` in `operation_logs.affected_tables`.

**Architecture:** Add failing assertions in static/live tests, minimally update `affectedTables` in four edge functions, deploy only changed functions, verify focused e2e + final gate, and update governance evidence.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Bash e2e tests, Supabase CLI deployment, jq/curl.

### Task 1: Add failing tests

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_assessment_training_live.sh`
- Modify: `tests/e2e/test_orchestrator_training_live.sh`
- Modify: `tests/e2e/test_orchestrator_training_record_live.sh`

**Step 1: Add RED assertions**

- Static chain checks require `assessment/training/training-advice/training-record` writeback metadata to include `chat_messages`.
- Live tests assert relevant action `affected_tables` includes `chat_messages` in addition to existing table checks.

**Step 2: Run RED verification**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`
- `bash tests/e2e/test_orchestrator_training_live.sh`
- `bash tests/e2e/test_orchestrator_training_record_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement minimal metadata fix

**Files:**
- Modify: `supabase/functions/assessment/index.ts`
- Modify: `supabase/functions/training/index.ts`
- Modify: `supabase/functions/training-advice/index.ts`
- Modify: `supabase/functions/training-record/index.ts`

**Step 1: Update `affectedTables` arrays**

- Add `chat_messages` to each module's `affectedTables` list.
- Keep existing payload/event source behavior unchanged.

### Task 3: Deploy and run focused GREEN tests

**Step 1: Deploy changed functions**

Run:
- `supabase functions deploy assessment --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`
- `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`
- `supabase functions deploy training-advice --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`
- `supabase functions deploy training-record --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`

**Step 2: Re-run focused tests**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_assessment_training_live.sh`
- `bash tests/e2e/test_orchestrator_training_live.sh`
- `bash tests/e2e/test_orchestrator_training_record_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence and assertions**

- Add latest request IDs and UTC timestamp.
- Add assertions that all four actions now include `chat_messages` in `affected_tables`.

### Task 5: Final verification and commit

**Step 1: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Commit**

```bash
git add .
git commit -m "fix(chain): include chat_messages in affected tables"
```
