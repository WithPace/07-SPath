# Live Smoke Retry Observability Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce stable retry/failure observability fields in shared orchestrator retry logs.

**Architecture:** Add a behavioral contract test that simulates retry/failure paths in `tests/e2e/_shared/orchestrator_retry.sh`, then minimally update helper log lines to satisfy the contract, and verify via full final gate plus governance docs sync.

**Tech Stack:** Bash (`source`, function override, grep), existing e2e governance pipeline, docs evidence updates.

### Task 1: RED with behavioral contract test

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_observability_contract.sh`

**Step 1: Write failing test first**

- Source helper.
- Override `uid`, `curl`, `sleep`, and payload builder for deterministic non-network execution.
- Force WORKER_LIMIT response and assert retry + terminal-failure stderr fields.

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

Expected: FAIL (required fields missing in helper logs).

### Task 2: Implement minimal helper logging enhancement

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Extend retry log line**

Ensure retry log includes:
- `module=<...>`
- `request_id=<...>`
- `attempt=<current>/<max>`
- `sleep_seconds=<...>`

**Step 2: Add terminal failure log line**

Before final return-1 path, emit:
- `module=<...>`
- `request_id=<...>`
- `attempt=<current>/<max>`
- `reason=<worker_limit_exhausted|done_event_missing>`

### Task 3: GREEN and regression checks

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_observability_contract.sh`

**Step 1: Run focused checks**

Run:
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`

Expected: PASS.

### Task 4: Full verification + docs evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

**Step 2: Update evidence**

Add entries:
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet describing retry observability fields contract.

### Task 5: Commit

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_observability_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-observability-contract-design.md \
  docs/plans/2026-02-25-live-smoke-retry-observability-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry observability contract gate"
```
