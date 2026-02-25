# Live Smoke Cleanup Contract Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce cleanup-hook presence across all live orchestrator e2e scripts.

**Architecture:** Add a new static e2e gate script that validates cleanup contract patterns for every `test_orchestrator_*_live.sh`; verify with RED->GREEN and full final gate.

**Tech Stack:** Bash, grep, existing `tests/e2e/*.sh` and `scripts/ci/final_gate.sh` flow.

### Task 1: RED

**Files:**
- Create: `tests/e2e/test_live_smoke_cleanup_contract.sh`

**Step 1: RED command**

Run:
- `bash tests/e2e/test_live_smoke_cleanup_contract.sh`

Expected: FAIL (file missing).

### Task 2: Implement cleanup contract gate

**Files:**
- Create: `tests/e2e/test_live_smoke_cleanup_contract.sh`

**Step 1: Add checks for all scripts**

For each live script (`chat_casual`, `assessment_training`, `training`, `training_record`, `dashboard`, `idempotency`) assert:
- `cleanup()`
- `trap cleanup EXIT`
- `/auth/v1/admin/users/`
- `-X DELETE`

**Step 2: Verify GREEN**

Run:
- `bash tests/e2e/test_live_smoke_cleanup_contract.sh`
- `bash tests/e2e/test_live_smoke_cleanup_presence.sh`

Expected: PASS.

### Task 3: Full verification and governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Update evidence**

- Add cleanup contract gate command evidence and latest timestamp.

### Task 4: Commit

```bash
git add .
git commit -m "test(e2e): add live smoke cleanup contract gate"
```
