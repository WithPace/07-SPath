# Live Smoke Retry Backoff Timing Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce runtime backoff timing sequence semantics for retry helper.

**Architecture:** Add a dynamic helper-level contract test that captures sleep arguments under deterministic retry scenarios. Assert exponential backoff sequence from configured base delay and no extra sleep in terminal/non-retriable branches. Keep helper code unchanged unless RED reveals a gap.

**Tech Stack:** Bash e2e contract tests, shared retry helper, governance verification scripts.

### Task 1: RED - add dynamic backoff timing contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh`

**Step 1: Write failing test first**

Build deterministic harness:
- `uid()` returns monotonic `req-1`, `req-2`, ...
- `sleep()` records delays into array
- `curl()` scripted per scenario

Scenarios:
- Scenario A (retry twice then success):
  - env: `ORCH_MAX_ATTEMPTS=5`, `ORCH_RETRY_BASE_DELAY_SECONDS=3`
  - responses: `WORKER_LIMIT`, `WORKER_LIMIT`, `event: done`
  - asserts: sleep sequence `3 6`, `ORCH_LAST_RESULT=success`, `ORCH_LAST_ATTEMPT=3/5`, `ORCH_LAST_RETRY_COUNT=2`
- Scenario B (retry exhausted):
  - env: `ORCH_MAX_ATTEMPTS=3`, `ORCH_RETRY_BASE_DELAY_SECONDS=3`
  - responses: all `WORKER_LIMIT`
  - asserts: sleep sequence `3 6` only, `ORCH_LAST_RESULT=failure`, `ORCH_LAST_FAILURE_REASON=worker_limit_exhausted`, `ORCH_LAST_ATTEMPT=3/3`, `ORCH_LAST_RETRY_COUNT=2`
- Scenario C (non-retriable terminal):
  - env: `ORCH_MAX_ATTEMPTS=5`, `ORCH_RETRY_BASE_DELAY_SECONDS=3`
  - response: `unexpected payload`
  - asserts: no sleep calls, `ORCH_LAST_FAILURE_REASON=done_event_missing`, `ORCH_LAST_ATTEMPT=1/5`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh`

Expected: FAIL before contract alignment is complete.

### Task 2: GREEN - minimal fix only if needed

**Files:**
- Modify (if needed): `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Apply minimal runtime fix only when RED reveals a gap**

- Preserve reason taxonomy and logging contracts.
- Ensure backoff sleeps only happen for retryable attempts (`attempt < max_attempts` and worker-limit reason).

**Step 2: Run focused regression gates**

Run:
- `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`

Expected: PASS.

### Task 3: Full verification

**Step 1: Run full gate**

Run:
- `bash scripts/ci/final_gate.sh`

Expected: PASS.

**Step 2: Run governance checks**

Run:
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

### Task 4: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

Append:
- `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest governance checks -> PASS
- latest UTC timestamp
- assertion bullet for backoff timing sequence contract.

**Step 2: Commit**

```bash
git add tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-backoff-timing-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-backoff-timing-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry backoff timing contract gate"
```
