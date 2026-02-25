# Live Smoke Retry State Reset Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce deterministic reset semantics and retry-count state for every retry helper invocation.

**Architecture:** Add a dynamic state-reset contract test that runs multiple simulated calls and asserts no stale state carry-over; minimally extend helper with `ORCH_LAST_RETRY_COUNT` and update it across branches.

**Tech Stack:** Bash helper + function override tests, existing governance/e2e gate chain.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_state_reset_contract.sh`

**Step 1: Write failing dynamic test first**

Simulate successive calls with pre-filled stale values and assert:
- state fields reset each call
- success branch values
- worker-limit exhausted branch values
- done-event-missing branch values
- retry count correctness (`ORCH_LAST_RETRY_COUNT`)

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh`

Expected: FAIL before helper counter/reset alignment.

### Task 2: Implement minimal helper state extension

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add/reset retry count**

- initialize `ORCH_LAST_RETRY_COUNT="0"` at call start.

**Step 2: Increment on retry branch**

- increment counter each time WORKER_LIMIT retry branch executes.

### Task 3: GREEN + regression

**Step 1: Run focused tests**

Run:
- `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

Expected: PASS.

### Task 4: Full verification + docs

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Sync evidence**

Append:
- `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet for state-reset + retry-count contract.

### Task 5: Commit

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_state_reset_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-state-reset-contract-design.md \
  docs/plans/2026-02-25-live-smoke-retry-state-reset-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry state reset contract gate"
```
