# Functions Auth And Body-Parse Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent regressions on request auth/access guards and single-pass JSON body consumption across execution-chain functions.

**Architecture:** Add one static contract test in `tests/functions/` that scans all 7 function entry files and enforces three invariants: authenticate call exists, child-access check exists, and `req.json()` appears exactly once. Keep implementation minimal and deterministic so it runs inside existing `final_gate`.

**Tech Stack:** Bash static contract tests, ripgrep (`rg`), existing CI gate scripts.

### Task 1: RED - add failing contract gate

**Files:**
- Create: `tests/functions/test_auth_and_body_parse_contract.sh`

**Step 1: Write failing test first**

- Script should:
  - iterate execution-chain files:
    - `supabase/functions/orchestrator/index.ts`
    - `supabase/functions/chat-casual/index.ts`
    - `supabase/functions/assessment/index.ts`
    - `supabase/functions/training/index.ts`
    - `supabase/functions/training-advice/index.ts`
    - `supabase/functions/training-record/index.ts`
    - `supabase/functions/dashboard/index.ts`
  - fail if any file missing.
  - fail if `authenticate(req)` missing.
  - fail if `checkChildAccess(user.id, payload.child_id)` missing.
  - fail if `req.json(` count is not exactly `1`.

**Step 2: Run RED**

Run:
- `bash tests/functions/test_auth_and_body_parse_contract.sh`

Expected:
- FAIL before file exists.

### Task 2: GREEN - minimal contract implementation

**Files:**
- Create: `tests/functions/test_auth_and_body_parse_contract.sh`

**Step 1: Implement gate**

- Add deterministic Bash checks with clear failure messages.
- Use `rg` and `wc -l` for `req.json(` count.

**Step 2: Verify new gate**

Run:
- `bash tests/functions/test_auth_and_body_parse_contract.sh`

Expected:
- PASS.

### Task 3: Verification

**Step 1: Focused verification**

Run:
- `bash tests/functions/test_auth_and_body_parse_contract.sh`
- `bash tests/functions/test_chain_files.sh`

Expected:
- PASS.

**Step 2: Full verification**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

### Task 4: Governance evidence + commit

**Files:**
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`

**Step 1: Update evidence**

Append:
- new auth/body-parse contract command -> PASS
- latest full check commands -> PASS
- latest UTC timestamp
- assertion bullet documenting this new gate.

**Step 2: Commit**

```bash
git add tests/functions/test_auth_and_body_parse_contract.sh \
  docs/plans/2026-02-26-functions-auth-body-parse-contract-design.md \
  docs/plans/2026-02-26-functions-auth-body-parse-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add auth body-parse contract gate"
```
