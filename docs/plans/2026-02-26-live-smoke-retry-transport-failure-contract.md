# Live Smoke Retry Transport-Failure Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make retry helper resilient to non-zero transport exits under `set -e` and enforce deterministic reason/state semantics.

**Architecture:** Add a dynamic transport-failure contract test in strict shell mode, then minimally update helper to capture `curl` exit codes safely and route failures through retry or terminal branches with explicit transport reasons. Sync static reason contracts and governance evidence.

**Tech Stack:** Bash helper + dynamic e2e contracts, governance verification scripts, full `final_gate`.

### Task 1: RED - add dynamic transport-failure contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_transport_failure_contract.sh`

**Step 1: Write failing test first**

Use strict mode (`set -euo pipefail`) and deterministic stubs:
- `uid()` monotonic ids.
- `sleep()` records delays.
- `curl()` scripted non-zero exits.

Scenarios:
- Scenario A: first `curl` returns non-zero, second returns `event: done`.
  - Expect command succeeds.
  - `ORCH_LAST_RESULT=success`, `ORCH_LAST_ATTEMPT=2/4`, `ORCH_LAST_RETRY_COUNT=1`, sleep sequence `1`.
- Scenario B: all attempts return non-zero with `ORCH_MAX_ATTEMPTS=3`.
  - Expect command fails gracefully (no script abort).
  - `ORCH_LAST_RESULT=failure`, `ORCH_LAST_FAILURE_REASON=transport_error_exhausted`, `ORCH_LAST_ATTEMPT=3/3`, `ORCH_LAST_RETRY_COUNT=2`, sleep sequence `1 2`.

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh`

Expected: FAIL before helper fix.

### Task 2: GREEN - minimal helper hardening

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add transport reason constants**

- `ORCH_RETRY_REASON_TRANSPORT_ERROR="transport_error"`
- `ORCH_TERMINAL_REASON_TRANSPORT_ERROR_EXHAUSTED="transport_error_exhausted"`

**Step 2: Capture curl exit safely under `set -e`**

- Replace direct assignment with safe capture:
  - `curl_exit=0`
  - `response=$(curl ...) || curl_exit=$?`

**Step 3: Add transport-failure branch mapping**

- If `curl_exit != 0` and attempts remain:
  - increment retry count,
  - compute backoff,
  - emit retry log with `reason=${ORCH_RETRY_REASON_TRANSPORT_ERROR}`,
  - sleep and continue.
- If `curl_exit != 0` and exhausted:
  - terminal reason `transport_error_exhausted`,
  - emit terminal log,
  - write `ORCH_LAST_*` state and return failure.

### Task 3: Align static reason contracts

**Files:**
- Modify: `tests/e2e/test_live_smoke_retry_reason_contract.sh`
- Modify: `tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- Modify: `tests/e2e/test_live_smoke_retry_observability_contract.sh`

**Step 1: Extend expectations**

- Include transport retry reason constant and terminal reason constant.
- Include transport reason-action mapping checks.

### Task 4: Verification

**Step 1: Focused tests**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

Expected: PASS.

**Step 2: Full checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

### Task 5: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

Append:
- transport-failure contract command -> PASS
- latest full-gate + governance checks -> PASS
- latest UTC timestamp
- assertion bullet for transport retry/terminal semantics.

**Step 2: Commit**

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_transport_failure_contract.sh \
  tests/e2e/test_live_smoke_retry_reason_contract.sh \
  tests/e2e/test_live_smoke_retry_reason_action_contract.sh \
  tests/e2e/test_live_smoke_retry_observability_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-transport-failure-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-transport-failure-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry transport failure contract gate"
```
