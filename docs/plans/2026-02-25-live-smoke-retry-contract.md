# Live Smoke Retry Contract Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce retry-semantics consistency across shared helper and all live orchestrator smoke scripts.

**Architecture:** Introduce a new static e2e governance gate script (`test_live_smoke_retry_contract.sh`) that validates helper retry semantics and per-script retry wiring defaults, then re-run full final gate and governance doc checks.

**Tech Stack:** Bash (`grep`, `test`), existing e2e scripts, governance evidence docs, `scripts/ci/final_gate.sh`.

### Task 1: RED for new gate

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_contract.sh`

**Step 1: Run missing-file command (RED)**

Run:
- `bash tests/e2e/test_live_smoke_retry_contract.sh`

Expected: FAIL (`No such file or directory`).

### Task 2: Implement retry semantic contract gate

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_contract.sh`

**Step 1: Implement helper-level assertions**

Assert in `tests/e2e/_shared/orchestrator_retry.sh`:
- `ORCH_MAX_ATTEMPTS` default path
- `ORCH_RETRY_BASE_DELAY_SECONDS` default path
- `WORKER_LIMIT` retry condition
- exponential backoff formula (`1 << (attempt - 1)`)
- `sleep` call on retry
- request/response trace fields (`ORCH_LAST_REQUEST_ID`, `ORCH_LAST_RESPONSE`, `request_ids+=`)

**Step 2: Implement all-script assertions**

For each live script:
- helper source path exists (`_shared/orchestrator_retry.sh`)
- `orchestrator_call_with_retry` invocation exists
- `curl_common` keeps `--retry 3`, `--retry-delay 1`, `--retry-all-errors`

**Step 3: Verify GREEN**

Run:
- `bash tests/e2e/test_live_smoke_retry_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_presence.sh`

Expected: PASS.

### Task 3: Full verification

**Files:**
- No new files

**Step 1: Run full gate**

Run:
- `bash scripts/ci/final_gate.sh`

Expected: PASS.

**Step 2: Run governance validation after doc updates**

Run:
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

### Task 4: Governance evidence sync

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Append command evidence**

Add entries for:
- `bash tests/e2e/test_live_smoke_retry_contract.sh` -> PASS
- latest `bash scripts/ci/final_gate.sh` -> PASS
- latest UTC timestamp

**Step 2: Append assertions**

Add an assertion bullet that retry semantic contract now enforces helper semantics and all-script retry defaults.

### Task 5: Commit

```bash
git add tests/e2e/test_live_smoke_retry_contract.sh \
  docs/plans/2026-02-25-live-smoke-retry-contract-design.md \
  docs/plans/2026-02-25-live-smoke-retry-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add live smoke retry contract gate"
```
