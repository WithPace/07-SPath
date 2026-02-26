# Live Smoke Retry Request-ID Trace Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce retry helper request-id lineage semantics across attempts and terminal state.

**Architecture:** Add one dynamic helper-level governance test that simulates deterministic retry sequences and asserts request-id append order plus final pointer writeback. Keep helper behavior unchanged unless the RED test reveals a gap.

**Tech Stack:** Bash e2e contract tests, shared retry helper, governance verification scripts.

### Task 1: RED - add failing dynamic contract test

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh`

**Step 1: Write failing test first**

Implement a deterministic test harness by stubbing:
- `uid()` as monotonic `req-1`, `req-2`, ...
- `curl()` with scripted responses per case
- `sleep()` as no-op

Add assertions for three cases:
- Case A (success first attempt): `request_ids` length `1`, value `req-1`, `ORCH_LAST_REQUEST_ID=req-1`.
- Case B (retry then success): `request_ids` length `2`, values `req-1 req-2`, `ORCH_LAST_REQUEST_ID=req-2`, `ORCH_LAST_RESULT=success`, `ORCH_LAST_RETRY_COUNT=1`.
- Case C (retry exhausted): `request_ids` length `2`, values `req-1 req-2`, `ORCH_LAST_REQUEST_ID=req-2`, `ORCH_LAST_RESULT=failure`, `ORCH_LAST_FAILURE_REASON=worker_limit_exhausted`.

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh`

Expected: FAIL before helper updates (or before completing test assertions).

### Task 2: GREEN - satisfy contract with minimal changes

**Files:**
- Modify (if needed): `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Apply minimal fix only if RED exposes a gap**

- Keep retry behavior unchanged.
- If needed, ensure `request_ids` append happens once per attempt and `ORCH_LAST_REQUEST_ID` points to terminal attempt id in both success/failure branches.

**Step 2: Run focused gates**

Run:
- `bash tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`
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
- `bash tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest governance checks -> PASS
- latest UTC timestamp
- assertion bullet for request-id lineage contract.

**Step 2: Commit**

```bash
git add tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-request-id-trace-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-request-id-trace-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry request-id trace contract gate"
```
