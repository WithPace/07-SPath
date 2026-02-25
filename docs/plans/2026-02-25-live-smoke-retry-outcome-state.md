# Live Smoke Retry Outcome State Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expose deterministic retry call outcome state for governance and diagnostics.

**Architecture:** Extend shared retry helper with canonical outcome variables and add a dynamic contract test that simulates success/terminal-failure branches; verify with focused tests + full final gate; sync governance evidence.

**Tech Stack:** Bash helper + function overrides in tests, existing governance/e2e pipeline.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`

**Step 1: Write dynamic contract test first**

Simulate three branches and assert state variables:
- success -> `ORCH_LAST_RESULT=success`, empty failure reason
- worker limit exhausted -> `ORCH_LAST_RESULT=failure`, reason `worker_limit_exhausted`
- done event missing -> `ORCH_LAST_RESULT=failure`, reason `done_event_missing`
- all branches emit `ORCH_LAST_ATTEMPT=<n>/<max>`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`

Expected: FAIL before helper state additions.

### Task 2: Implement helper outcome state

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Initialize outcome variables at call start**

- `ORCH_LAST_RESULT=""`
- `ORCH_LAST_FAILURE_REASON=""`
- `ORCH_LAST_ATTEMPT=""`

**Step 2: Set on success path**

- `ORCH_LAST_RESULT="success"`
- `ORCH_LAST_FAILURE_REASON=""`
- `ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"`

**Step 3: Set on terminal failure path**

- `ORCH_LAST_RESULT="failure"`
- `ORCH_LAST_FAILURE_REASON="${failure_reason}"`
- `ORCH_LAST_ATTEMPT="${attempt}/${max_attempts}"`

### Task 3: GREEN + regression

**Step 1: Run focused tests**

Run:
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

Expected: PASS.

### Task 4: Full verification + governance sync

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Update evidence**

Append:
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet for outcome-state contract.

### Task 5: Commit

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_outcome_state_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-outcome-state-design.md \
  docs/plans/2026-02-25-live-smoke-retry-outcome-state.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry outcome state contract gate"
```
