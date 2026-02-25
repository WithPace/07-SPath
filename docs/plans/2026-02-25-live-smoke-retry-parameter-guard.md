# Live Smoke Retry Parameter Guard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent retry parameter drift by enforcing bounded retry env values in shared helper and codifying the contract in governance tests.

**Architecture:** Add retry-parameter normalization in `tests/e2e/_shared/orchestrator_retry.sh`, then enforce it with a new static contract test and full-gate verification, followed by governance evidence sync.

**Tech Stack:** Bash (`source`, `test`, `grep`), existing live smoke scripts, governance evidence docs, `scripts/ci/final_gate.sh`.

### Task 1: RED on behavioral contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_limits_contract.sh`

**Step 1: Write contract test first**

Test should:
- source retry helper
- assert sanitized boundary behavior for numeric/non-numeric values
- assert bounded wiring for `ORCH_MAX_ATTEMPTS` and `ORCH_RETRY_BASE_DELAY_SECONDS`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`

Expected: FAIL (missing function/wiring before implementation).

### Task 2: Implement bounded retry normalization

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add integer sanitizer helper**

Add helper to return default when value is non-numeric or outside min/max range.

**Step 2: Wire bounded defaults in retry call**

Set:
- max attempts default `4`, range `[2, 6]`
- base delay default `1`, range `[1, 5]`

### Task 3: GREEN and regression safety

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_limits_contract.sh`

**Step 1: Run focused tests**

Run:
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_presence.sh`

Expected: PASS.

### Task 4: Full verification and evidence sync

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Update governance evidence**

Append:
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet describing bounded retry parameter contract enforcement

### Task 5: Commit

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_limits_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-parameter-guard-design.md \
  docs/plans/2026-02-25-live-smoke-retry-parameter-guard.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): guard live smoke retry parameter drift"
```
