# Functions Writeback Before Done Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Lock ordering semantics so execution modules always perform writeback persistence before emitting terminal SSE `done`.

**Architecture:** Add a static Bash + ripgrep contract script that checks `finalizeWriteback` and `done` presence and lexical ordering across six module entry files, then run focused and full governance verification.

**Tech Stack:** Bash, ripgrep, existing final-gate and governance scripts.

### Task 1: RED - prove missing gate

**Files:**
- Create: `tests/functions/test_writeback_before_done_contract.sh`

**Step 1: Run RED first**

Run:
- `bash tests/functions/test_writeback_before_done_contract.sh`

Expected:
- FAIL because the script does not exist yet.

### Task 2: GREEN - implement static gate

**Files:**
- Create: `tests/functions/test_writeback_before_done_contract.sh`

**Step 1: Add deterministic checks**

- Check these files:
  - `supabase/functions/chat-casual/index.ts`
  - `supabase/functions/assessment/index.ts`
  - `supabase/functions/training/index.ts`
  - `supabase/functions/training-advice/index.ts`
  - `supabase/functions/training-record/index.ts`
  - `supabase/functions/dashboard/index.ts`
- Assert each file contains:
  - `await finalizeWriteback({`
  - `sseEvent("done",`
- Assert lexical order:
  - finalizeWriteback line < done-event line

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_writeback_before_done_contract.sh`
- `bash tests/functions/test_writeback_metadata_contract.sh`
- `bash tests/functions/test_sse_framing_contract.sh`

Expected:
- PASS.

### Task 3: Full verification sweep

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

### Task 4: Governance evidence and commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Append evidence**

- Add PASS lines for:
  - `bash tests/functions/test_writeback_before_done_contract.sh`
  - `bash scripts/ci/final_gate.sh`
  - `bash tests/governance/test_docs_presence.sh`
  - `bash tests/governance/test_e2e_governance.sh`
- Add final-gate smoke request-id sample set.
- Update latest UTC timestamp.
- Add outputs/assertions bullet for the new static ordering gate.

**Step 2: Commit**

```bash
git add tests/functions/test_writeback_before_done_contract.sh \
  docs/plans/2026-02-26-functions-writeback-before-done-contract-design.md \
  docs/plans/2026-02-26-functions-writeback-before-done-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add writeback-before-done contract gate"
```
