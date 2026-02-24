# Affected Tables Contract Test Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a dedicated static governance test that enforces action-level `affectedTables` table coverage.

**Architecture:** Create `tests/functions/test_affected_tables_contract.sh` with explicit module/action table expectations; ensure it fails before implementation edits (RED), then pass (GREEN), and run full final gate + governance checks.

**Tech Stack:** Bash, ripgrep/grep, existing CI/final_gate test runner.

### Task 1: Add failing contract test (RED)

**Files:**
- Create: `tests/functions/test_affected_tables_contract.sh`

**Step 1: Write RED assertions**

- For each module action, assert required table names are present in the corresponding `affectedTables` declaration context.
- Include checks for:
  - `chat_casual_reply`
  - `assessment_generate`
  - `training_generate`
  - `training_advice_generate`
  - `training_record_create`
  - `dashboard_generate`

**Step 2: Run and observe RED**

Run:
- `bash tests/functions/test_affected_tables_contract.sh`

Expected: FAIL initially while script is intentionally incomplete/strict.

### Task 2: Implement minimal GREEN

**Files:**
- Modify: `tests/functions/test_affected_tables_contract.sh`

**Step 1: Finalize robust checks**

- Use simple and deterministic grep assertions that pass on current source layout.
- Keep script readable and diagnosable.

**Step 2: Verify GREEN**

Run:
- `bash tests/functions/test_affected_tables_contract.sh`
- `bash tests/functions/test_chain_files.sh`

Expected: PASS.

### Task 3: Full verification and governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full gate**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Update evidence docs**

- Record new command evidence and timestamp.

### Task 4: Commit

Run:

```bash
git add .
git commit -m "test(governance): add affected_tables contract gate"
```
