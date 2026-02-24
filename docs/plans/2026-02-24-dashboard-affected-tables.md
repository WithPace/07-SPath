# Dashboard Affected Tables Accuracy Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure `dashboard_generate` writeback metadata includes the actual write table `chat_messages`.

**Architecture:** Add RED assertions in chain/static + dashboard live e2e, then minimally update `supabase/functions/dashboard/index.ts` `affectedTables`, deploy dashboard, verify focused live test and full final gate.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Bash e2e scripts, Supabase PostgREST/Auth APIs, jq/curl.

### Task 1: Add failing tests

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_dashboard_live.sh`

**Step 1: Add RED assertions**

- Static chain test: require dashboard function to contain `chat_messages` in writeback metadata context.
- Live dashboard test: assert `operation_logs(action_name=dashboard_generate).affected_tables` includes `chat_messages`.

**Step 2: Run tests and confirm failure**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_dashboard_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement minimal metadata fix

**Files:**
- Modify: `supabase/functions/dashboard/index.ts`

**Step 1: Update `affectedTables`**

- Add `chat_messages` to `affectedTables` for `dashboard_generate`.
- Keep current event source and snapshot settings unchanged.

### Task 3: Deploy and verify focused chain

**Step 1: Verify GREEN**

Run:
- `bash tests/functions/test_chain_files.sh`
- `supabase functions deploy dashboard --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt`
- `bash tests/e2e/test_orchestrator_dashboard_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence + assertions**

- Add latest timestamp and dashboard request ID from live run.
- Add assertion that `dashboard_generate` affected tables include `chat_messages`.

### Task 5: Final verification and commit

**Step 1: Run full gate and governance checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Commit**

```bash
git add .
git commit -m "fix(dashboard): include chat_messages in affected tables"
```
