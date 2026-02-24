# Chat Casual Memory Sync Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `chat-casual` persist memory summary (`children_memory.last_interaction_summary`) on each successful response.

**Architecture:** Extend `chat-casual` edge function with memory upsert and update chat live e2e/static checks to verify memory writeback and operation log metadata.

**Tech Stack:** Supabase Edge Functions (Deno TypeScript), Supabase PostgREST/Auth APIs, Bash e2e tests, jq/curl.

### Task 1: Add failing tests

**Files:**
- Modify: `tests/functions/test_chain_files.sh`
- Modify: `tests/e2e/test_orchestrator_chat_casual_live.sh`

**Step 1: Add assertions**

- Static: `chat-casual` must reference `children_memory`.
- Live e2e:
  - `children_memory` row exists for target child
  - `last_interaction_summary` non-empty
  - `operation_logs(action_name=chat_casual_reply).affected_tables` contains `children_memory`

**Step 2: Verify RED**

Run:
- `bash tests/functions/test_chain_files.sh`
- `bash tests/e2e/test_orchestrator_chat_casual_live.sh`

Expected: FAIL before implementation.

### Task 2: Implement memory writeback in `chat-casual`

**Files:**
- Modify: `supabase/functions/chat-casual/index.ts`

**Step 1: Add memory helper logic**

- Build concise summary from assistant response.
- Fetch existing memory row (if any) to preserve current focus.

**Step 2: Upsert `children_memory`**

- Upsert by `child_id`:
  - `current_focus` (preserve existing or initialize fallback)
  - `last_interaction_summary`
  - `updated_at`

**Step 3: Update finalize metadata**

- Include `children_memory` in `affectedTables`.
- Include memory id in payload.

### Task 3: Verify focused chain

**Step 1: Run checks**

Run:
- `bash tests/functions/test_chain_files.sh`
- `supabase functions deploy chat-casual --project-ref <ref> --use-api --no-verify-jwt`
- `bash tests/e2e/test_orchestrator_chat_casual_live.sh`

Expected: PASS.

### Task 4: Refresh governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

- Add latest run IDs and timestamp.
- Mention `chat_casual_reply` memory side effects.

### Task 5: Final verification and commit

**Step 1: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Commit**

```bash
git add .
git commit -m "feat(chat-casual): sync memory summary on reply"
```
