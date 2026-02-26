# Orchestrator Conversation Bootstrap Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Protect orchestrator conversation bootstrap and incoming user-message persistence invariants against regression.

**Architecture:** Add one static contract test over `supabase/functions/orchestrator/index.ts` that validates auto-conversation creation fields, user message insert fields, and explicit error handling on these writes.

**Tech Stack:** Bash + ripgrep static checks, existing final gate pipeline.

### Task 1: RED - add conversation bootstrap contract test

**Files:**
- Create: `tests/functions/test_orchestrator_conversation_bootstrap_contract.sh`

**Step 1: Write failing test first**

- Validate orchestrator includes:
  - `if (!conversationId) { ... }` branch.
  - `from("conversations").insert({ ... })` with:
    - `child_id`
    - `user_id`
    - `title: "新对话"`
    - `last_message_at`
    - `message_count: 0`
    - `is_deleted: false`
  - explicit throw on conversation create failure.
  - `from("chat_messages").insert({ ... })` with:
    - `conversation_id`
    - `child_id`
    - `user_id`
    - `role: "user"`
    - `content`
    - `edge_function: "orchestrator"`
  - explicit throw on user-message insert failure.

**Step 2: Run RED**

Run:
- `bash tests/functions/test_orchestrator_conversation_bootstrap_contract.sh`

Expected:
- FAIL before script exists.

### Task 2: GREEN - implement static gate

**Files:**
- Create: `tests/functions/test_orchestrator_conversation_bootstrap_contract.sh`

**Step 1: Add deterministic checks**

- Add explicit failure messages for each required clause.

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_orchestrator_conversation_bootstrap_contract.sh`
- `bash tests/functions/test_orchestrator_forwarding_contract.sh`
- `bash tests/functions/test_error_response_contract.sh`

Expected:
- PASS.

### Task 3: Full verification

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

### Task 4: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

- Append new contract command pass lines.
- Append latest full-gate pass records + UTC timestamp.
- Add assertion bullet for conversation bootstrap contract.

**Step 2: Commit**

```bash
git add tests/functions/test_orchestrator_conversation_bootstrap_contract.sh \
  docs/plans/2026-02-26-orchestrator-conversation-bootstrap-contract-design.md \
  docs/plans/2026-02-26-orchestrator-conversation-bootstrap-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add orchestrator conversation bootstrap contract gate"
```
