# Live Smoke Retry Transport Exit-Code Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce transport exit-code diagnostics in retry logs and terminal state writeback.

**Architecture:** Add one dynamic helper-level contract test that triggers transport retry and transport exhaustion branches under deterministic curl exit codes. Update helper minimally to include `exit_code` in transport logs and to persist `transport_error_exit_code=<code>` in `ORCH_LAST_RESPONSE` on transport terminal exhaustion.

**Tech Stack:** Bash e2e contract tests, shared retry helper, governance verification scripts.

### Task 1: RED - add dynamic transport exit-code contract

**Files:**
- Create: `tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh`

**Step 1: Write failing test first**

Deterministic harness:
- `uid()` monotonic.
- `sleep()` no-op.
- `curl()` returns exit code `28` per scenario.

Assertions:
- Scenario A (first transport fail then success):
  - command succeeds
  - retry log contains `reason=transport_error exit_code=28`
- Scenario B (transport exhausted with 3 attempts):
  - command fails
  - terminal log contains `reason=transport_error_exhausted exit_code=28`
  - `ORCH_LAST_RESPONSE` contains `transport_error_exit_code=28`

**Step 2: Run RED**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh`

Expected: FAIL before helper update.

### Task 2: GREEN - minimal helper update

**Files:**
- Modify: `tests/e2e/_shared/orchestrator_retry.sh`

**Step 1: Add exit-code diagnostics**

- In transport retry branch log, append `exit_code=${curl_exit}`.
- In transport terminal branch log, append `exit_code=${curl_exit}`.
- In transport terminal state writeback, set:
  - `ORCH_LAST_RESPONSE="transport_error_exit_code=${curl_exit}${response:+ ${response}}"`

**Step 2: Update observability static contract**

**Files:**
- Modify: `tests/e2e/test_live_smoke_retry_observability_contract.sh`

Add checks for transport log `exit_code=${curl_exit}` and state marker `transport_error_exit_code=`.

### Task 3: Verification

**Step 1: Focused suite**

Run:
- `bash tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_transport_observability_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh`
- `bash tests/e2e/test_live_smoke_retry_observability_contract.sh`

Expected: PASS.

**Step 2: Full checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

### Task 4: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

Append:
- transport-exit-code contract -> PASS
- latest full checks -> PASS
- latest UTC timestamp
- assertion bullet for transport exit-code diagnostics.

**Step 2: Commit**

```bash
git add tests/e2e/_shared/orchestrator_retry.sh \
  tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh \
  tests/e2e/test_live_smoke_retry_observability_contract.sh \
  docs/plans/2026-02-26-live-smoke-retry-transport-exit-code-contract-design.md \
  docs/plans/2026-02-26-live-smoke-retry-transport-exit-code-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(e2e): add retry transport exit-code contract gate"
```
