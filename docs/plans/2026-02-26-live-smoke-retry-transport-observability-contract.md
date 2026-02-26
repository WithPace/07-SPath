# Live Smoke Retry Transport Observability Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce runtime observability semantics for transport retry/terminal branches.

**Architecture:** Add a dynamic helper-level stderr-capture contract that executes transport retry and transport exhausted paths under deterministic stubs, then validates canonical runtime log lines (resolved fields, reasons, attempts, delays). Keep helper behavior unchanged unless RED exposes a log semantics gap.

**Tech Stack:** Bash e2e contract tests, shared retry helper, governance verification scripts.

### Task 1: RED - add dynamic transport observability contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_transport_observability_contract.sh`

**Step 1: Write failing test first**

Build deterministic harness:
- `uid()` deterministic (`req-1`, `req-2`, ...).
- `sleep()` no-op.
- `curl()` scripted non-zero exits followed by success/exhaustion.

Scenarios:
- Scenario A (transport fail once, then success):
  - env: `ORCH_MAX_ATTEMPTS=4`, `ORCH_RETRY_BASE_DELAY_SECONDS=1`
  - assert stderr contains:
    - `orchestrator retry: module=training request_id=req-1 attempt=1/4 sleep_seconds=1 reason=transport_error`
- Scenario B (transport exhausted):
  - env: `ORCH_MAX_ATTEMPTS=3`, `ORCH_RETRY_BASE_DELAY_SECONDS=1`
  - assert stderr contains:
    - `orchestrator terminal_failure: module=training request_id=req-3 attempt=3/3 reason=transport_error_exhausted`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_observability_contract.sh`

Expected: FAIL before helper/log alignment.

### Task 2: GREEN - minimal updates only if needed

**Files:**
- Modify (if needed): `tests/e2e/_shared/orchestrator_retry.sh`
- Modify (if needed): `tests/e2e/test_live_smoke_retry_observability_contract.sh`

**Step 1: Apply minimal fix only when RED reveals a gap**

- Preserve existing reason taxonomy and branch semantics.
- Ensure transport retry and terminal branches emit canonical log lines with resolved fields.

**Step 2: Focused regression verification**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

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
- transport-observability contract command -> PASS
- latest full-gate + governance checks -> PASS
- latest UTC timestamp
- assertion bullet for transport runtime log observability.

**Step 2: Commit**

```bash
git add tests/e2e/test_live_smoke_retry_transport_observability_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-transport-observability-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-transport-observability-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry transport observability contract gate"
```
