# Live Smoke Retry Cards Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce precise terminal reason semantics for `require_cards` failures.

**Architecture:** Add a dynamic e2e contract test for cards-required failure path, minimally extend helper reason taxonomy with `cards_payload_missing`, align reason contracts, then run full gate and governance evidence sync.

**Tech Stack:** Bash helper + override-based dynamic test, existing retry governance scripts, full `final_gate`.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_cards_contract.sh`

**Step 1: Write failing test first**

Simulate `event: done` without cards while `require_cards=1`; assert:
- command fails
- `ORCH_LAST_RESULT=failure`
- `ORCH_LAST_FAILURE_REASON=cards_payload_missing`
- retry count is 0
- terminal failure log contains `reason=cards_payload_missing`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_cards_contract.sh`

Expected: FAIL before helper update.

### Task 2: Implement helper taxonomy refinement

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add cards payload reason constant**

- `ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING="cards_payload_missing"`

**Step 2: Update cards-required failure branch**

- set failure reason to cards constant
- emit terminal failure log format
- keep state updates and failure return

### Task 3: Align existing reason contracts

**Files:**
- Modify: `tests/e2e/test_live_smoke_retry_reason_contract.sh`
- Modify: `tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- Modify: `tests/e2e/test_live_smoke_retry_observability_contract.sh`

**Step 1: Extend expectations**

- include cards reason constant and assignment checks
- preserve existing worker_limit/done_event contracts

### Task 4: GREEN + full verification

**Step 1: Run focused suite**

Run:
- `bash tests/e2e/test_live_smoke_retry_cards_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh`

Expected: PASS.

**Step 2: Run full checks**

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
- `bash tests/e2e/test_live_smoke_retry_cards_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp
- assertion bullet for cards-missing reason contract.

**Step 2: Commit**

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_cards_contract.sh \
  tests/e2e/test_live_smoke_retry_reason_contract.sh \
  tests/e2e/test_live_smoke_retry_reason_action_contract.sh \
  tests/e2e/test_live_smoke_retry_observability_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-cards-contract-design.md \
  docs/plans/2026-02-25-live-smoke-retry-cards-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry cards reason contract gate"
```
