# Orchestrator Idempotency Live Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce runtime idempotency for duplicate orchestrator requests with same `request_id`.

**Architecture:** Add `tests/e2e/test_orchestrator_idempotency_live.sh` that performs two calls with identical payload/request id and checks short-circuit semantics + single-write side effects; include script in retry presence guard and final gate run.

**Tech Stack:** Bash, curl, jq, Supabase Auth/PostgREST APIs, existing `.env` credentials.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_orchestrator_idempotency_live.sh`

**Step 1: RED command**

Run:
- `bash tests/e2e/test_orchestrator_idempotency_live.sh`

Expected: FAIL (file missing).

### Task 2: Implement idempotency live script

**Files:**
- Create: `tests/e2e/test_orchestrator_idempotency_live.sh`
- Modify: `tests/e2e/test_live_smoke_retry_presence.sh`

**Step 1: Script behavior**

- Create isolated auth/user/child/care-team context.
- Generate one `request_id` and send the same request twice.
- Assert:
  - second response includes `"idempotent":true`
  - `operation_logs` count for (`request_id`,`chat_casual_reply`,`completed`) is exactly 1
  - `chat_messages` count for test user/child is exactly `user=1`, `assistant=1`
  - `snapshot_refresh_events` count for request id is exactly 1
- Include cleanup trap consistent with existing live scripts.

**Step 2: Retry-presence guard update**

- Include this new e2e script in `test_live_smoke_retry_presence.sh` shared-hook assertions.

### Task 3: Verify

**Step 1: Focused verification**

Run:
- `bash tests/e2e/test_live_smoke_retry_presence.sh`
- `bash tests/e2e/test_orchestrator_idempotency_live.sh`

Expected: PASS.

**Step 2: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

### Task 4: Governance evidence and commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

- Add command evidence, request ID sample, and latest timestamp.
- Add assertion line for orchestrator idempotent short-circuit behavior.

**Step 2: Commit**

```bash
git add .
git commit -m "test(e2e): add orchestrator idempotency live gate"
```
