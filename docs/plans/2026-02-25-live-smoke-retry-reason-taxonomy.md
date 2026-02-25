# Live Smoke Retry Reason Taxonomy Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Lock retry reason taxonomy by enforcing canonical constants and usage in shared helper/log contract.

**Architecture:** Add a new static taxonomy gate for helper reason constants and usage points, then minimally refactor helper to use constants, verify with focused tests + full final gate, and sync governance evidence.

**Tech Stack:** Bash, grep-based contract tests, existing governance evidence docs, `scripts/ci/final_gate.sh`.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_reason_contract.sh`

**Step 1: Write failing taxonomy contract test first**

Assert helper has canonical constants and uses them in log lines + failure assignment.

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`

Expected: FAIL before helper refactor.

### Task 2: Implement constants and wiring

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add reason constants**

Define canonical constants near helper top-level.

**Step 2: Replace literals with constants**

Use constants in:
- retry log `reason=` field
- `failure_reason` assignments
- terminal failure log output

### Task 3: GREEN verification

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_reason_contract.sh`

**Step 1: Run focused suite**

Run:
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`

Expected: PASS.

### Task 4: Full verification + governance docs

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
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet for reason-taxonomy contract enforcement.

### Task 5: Commit

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_reason_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-reason-taxonomy-design.md \
  docs/plans/2026-02-25-live-smoke-retry-reason-taxonomy.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): enforce retry reason taxonomy contract"
```
