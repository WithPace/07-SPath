# Live Smoke Retry Runtime Sanitization Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce runtime fallback semantics when retry env parameters are invalid.

**Architecture:** Add one dynamic helper-level contract test that drives the retry path under invalid env values and verifies fallback behavior through observable runtime state (`request_ids`, `ORCH_LAST_*`) and captured sleep calls. Keep helper code unchanged unless RED exposes a real runtime gap.

**Tech Stack:** Bash e2e contract tests, shared retry helper, governance verification scripts.

### Task 1: RED - add dynamic runtime sanitization contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh`

**Step 1: Write failing test first**

Implement deterministic harness with:
- `uid()` deterministic (`req-1`, `req-2`, ...)
- `curl()` always returning `WORKER_LIMIT`
- `sleep()` capturing delay args into array (no real wait)

Contract scenarios:
- Scenario A (`ORCH_MAX_ATTEMPTS=1`, `ORCH_RETRY_BASE_DELAY_SECONDS=0`):
  - call fails
  - `request_ids` length `4`
  - `ORCH_LAST_ATTEMPT=4/4`
  - `ORCH_LAST_RETRY_COUNT=3`
  - sleep sequence `1 2 4`
- Scenario B (`ORCH_MAX_ATTEMPTS=abc`, `ORCH_RETRY_BASE_DELAY_SECONDS=nan`):
  - same expectations as Scenario A
  - `ORCH_LAST_FAILURE_REASON=worker_limit_exhausted`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh`

Expected: FAIL before helper/runtime contract alignment is complete.

### Task 2: GREEN - minimal fix only if needed

**Files:**
- Modify (if needed): `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Apply minimal runtime fix only when RED reveals a gap**

- Keep retry taxonomy/observability unchanged.
- Ensure invalid env values always sanitize to default runtime values used in attempts/backoff flow.

**Step 2: Run focused regression gates**

Run:
- `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh`

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
- `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest governance checks -> PASS
- latest UTC timestamp
- assertion bullet for runtime sanitization fallback contract.

**Step 2: Commit**

```bash
git add tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-runtime-sanitization-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-runtime-sanitization-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry runtime sanitization contract gate"
```
