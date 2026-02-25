# Live Smoke Retry Reason-Action Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce deterministic reason-to-action mapping in retry helper governance.

**Architecture:** Add a new static gate for reason/action branch invariants in `orchestrator_retry.sh`; keep helper behavior unchanged unless needed for contract conformance; then run focused checks + full final gate + governance evidence sync.

**Tech Stack:** Bash/grep static contracts, existing e2e governance pipeline, governance evidence docs.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_reason_action_contract.sh`

**Step 1: Write failing contract test first**

Assert required reason/action branch patterns in helper.

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`

Expected: FAIL before helper adjustment.

### Task 2: Implement minimal helper alignment (if needed)

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh` (only if RED reveals missing mapping detail)

**Step 1: Ensure retry branch mapping**

- WORKER_LIMIT condition
- backoff + sleep
- `continue`

**Step 2: Ensure terminal branch mapping**

- default terminal reason set
- worker-limit exhausted override
- terminal log emitted
- `return 1`

### Task 3: GREEN and regression checks

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_reason_action_contract.sh`

**Step 1: Run focused suite**

Run:
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_contract.sh`

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
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet for reason->action contract.

### Task 5: Commit

```bash
git add tests/e2e/test_live_smoke_retry_reason_action_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-reason-action-contract-design.md \
  docs/plans/2026-02-25-live-smoke-retry-reason-action-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry reason action contract gate"
```
