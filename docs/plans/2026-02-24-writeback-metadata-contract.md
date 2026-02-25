# Writeback Metadata Contract Gate Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a static governance gate ensuring each module action keeps expected writeback metadata semantics.

**Architecture:** Create `tests/functions/test_writeback_metadata_contract.sh` with explicit per-module expectations for `actionName`, `eventSourceTable`, `eventType`, and `targetSnapshotType`, then verify through full gate and governance docs updates.

**Tech Stack:** Bash, grep, existing `scripts/ci/final_gate.sh` test loop.

### Task 1: RED test scaffold

**Files:**
- Create: `tests/functions/test_writeback_metadata_contract.sh`

**Step 1: RED command**

Run:
- `bash tests/functions/test_writeback_metadata_contract.sh`

Expected: FAIL (file missing).

### Task 2: Implement gate script

**Files:**
- Create: `tests/functions/test_writeback_metadata_contract.sh`

**Step 1: Add per-module expectations**

- `chat-casual`: `chat_casual_reply`, `chat_messages`, `insert`, `both`
- `assessment`: `assessment_generate`, `children_profiles`, `insert`, `both`
- `training`: `training_generate`, `training_plans`, `insert`, `both`
- `training-advice`: `training_advice_generate`, `training_plans`, `insert`, `both`
- `training-record`: `training_record_create`, `children_profiles`, `insert`, `both`
- `dashboard`: `dashboard_generate`, `training_sessions`, `read`, `short_term`

**Step 2: Verify GREEN**

Run:
- `bash tests/functions/test_writeback_metadata_contract.sh`
- `bash tests/functions/test_affected_tables_contract.sh`

Expected: PASS.

### Task 3: Full verification + governance evidence

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Run full checks**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected: PASS.

**Step 2: Update evidence docs**

- Add command evidence for metadata gate and latest timestamp.

### Task 4: Commit

```bash
git add .
git commit -m "test(governance): add writeback metadata contract gate"
```
