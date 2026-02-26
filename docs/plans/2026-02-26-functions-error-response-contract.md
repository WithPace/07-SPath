# Functions Error Response Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Enforce consistent SSE error semantics and HTTP status mapping across all execution-chain functions.

**Architecture:** Add a single static contract test over 7 function entry files to lock BAD_REQUEST/AUTH_FORBIDDEN/INTERNAL_ERROR branches and status code expectations, plus success-path SSE header contract.

**Tech Stack:** Bash + ripgrep static checks, existing CI/final gate.

### Task 1: RED - add error-response contract test

**Files:**
- Create: `tests/functions/test_error_response_contract.sh`

**Step 1: Write failing test first**

- Validate for each function file:
  - contains `sseError("BAD_REQUEST"` and `status: 400`.
  - contains `sseError("AUTH_FORBIDDEN"` and `status: 403`.
  - contains catch-path `sseError("INTERNAL_ERROR"` and `status: 500`.
  - contains success response with `headers: SSE_HEADERS`.

Target files:
- `supabase/functions/orchestrator/index.ts`
- `supabase/functions/chat-casual/index.ts`
- `supabase/functions/assessment/index.ts`
- `supabase/functions/training/index.ts`
- `supabase/functions/training-advice/index.ts`
- `supabase/functions/training-record/index.ts`
- `supabase/functions/dashboard/index.ts`

**Step 2: Run RED**

Run:
- `bash tests/functions/test_error_response_contract.sh`

Expected:
- FAIL because script does not yet exist.

### Task 2: GREEN - implement static contract gate

**Files:**
- Create: `tests/functions/test_error_response_contract.sh`

**Step 1: Add deterministic checks**

- Add explicit fail messages per file/rule.

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_error_response_contract.sh`
- `bash tests/functions/test_auth_and_body_parse_contract.sh`
- `bash tests/functions/test_orchestrator_forwarding_contract.sh`

Expected:
- PASS.

### Task 3: Full verification

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

- Append new error-response contract pass lines.
- Append latest full-gate pass + timestamp.
- Add assertion bullet for error-response contract.

**Step 2: Commit**

```bash
git add tests/functions/test_error_response_contract.sh \
  docs/plans/2026-02-26-functions-error-response-contract-design.md \
  docs/plans/2026-02-26-functions-error-response-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add error response contract gate"
```
