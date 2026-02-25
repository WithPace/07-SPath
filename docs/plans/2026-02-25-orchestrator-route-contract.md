# Orchestrator Route Contract Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a static governance gate that validates orchestrator module routing contracts.

**Architecture:** Create `tests/functions/test_orchestrator_route_contract.sh` with explicit tuple and alias checks for `resolveRoute`; run RED->GREEN, then full `final_gate` and governance checks.

**Tech Stack:** Bash + grep/ripgrep, existing function test suite and final gate.

### Task 1: RED scaffold

**Files:**
- Create: `tests/functions/test_orchestrator_route_contract.sh`

**Step 1: RED command**

Run:
- `bash tests/functions/test_orchestrator_route_contract.sh`

Expected: FAIL (file missing).

### Task 2: Implement route contract gate

**Files:**
- Create: `tests/functions/test_orchestrator_route_contract.sh`

**Step 1: Add explicit checks**

- Assert `resolveRoute` includes canonical branches for:
  - `chat_casual`
  - `assessment`
  - `training`
  - `training_advice`
  - `training_record`
  - `dashboard`
- Assert tuple fields per branch:
  - `functionName`
  - `actionName`
  - `module`
- Assert important alias paths exist (`chat`, `train`, `training_plan`, `trainingadvice`, `trainingrecord`, `analysis`).

**Step 2: Verify GREEN**

Run:
- `bash tests/functions/test_orchestrator_route_contract.sh`
- `bash tests/functions/test_chain_files.sh`

Expected: PASS.

### Task 3: Full verification and governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Full checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Update evidence**

- Add route-contract gate command and latest timestamp.

### Task 4: Commit

```bash
git add .
git commit -m "test(governance): add orchestrator route contract gate"
```
