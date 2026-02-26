# Functions OPTIONS Preflight Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Lock CORS preflight behavior for all execution-chain function entrypoints with a static contract gate.

**Architecture:** Add one Bash + ripgrep contract test that checks every execution-chain function for canonical `OPTIONS` branch and SSE header response return. Run focused checks, then full governance gates, then append evidence docs.

**Tech Stack:** Bash, ripgrep, existing governance/final-gate scripts.

### Task 1: RED - prove missing gate

**Files:**
- Create: `tests/functions/test_options_preflight_contract.sh`

**Step 1: Run RED first**

Run:
- `bash tests/functions/test_options_preflight_contract.sh`

Expected:
- FAIL because the script does not exist yet.

### Task 2: GREEN - implement static gate

**Files:**
- Create: `tests/functions/test_options_preflight_contract.sh`

**Step 1: Add deterministic checks**

- Check these files:
  - `supabase/functions/orchestrator/index.ts`
  - `supabase/functions/chat-casual/index.ts`
  - `supabase/functions/assessment/index.ts`
  - `supabase/functions/training/index.ts`
  - `supabase/functions/training-advice/index.ts`
  - `supabase/functions/training-record/index.ts`
  - `supabase/functions/dashboard/index.ts`
- Assert in each:
  - `if (req.method === "OPTIONS")`
  - `return new Response(null, { headers: SSE_HEADERS });`

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_options_preflight_contract.sh`
- `bash tests/functions/test_error_response_contract.sh`
- `bash tests/functions/test_request_id_lifecycle_contract.sh`

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
  - `bash tests/functions/test_options_preflight_contract.sh`
  - `bash scripts/ci/final_gate.sh`
  - `bash tests/governance/test_docs_presence.sh`
  - `bash tests/governance/test_e2e_governance.sh`
- Add final-gate smoke sample request IDs.
- Update latest UTC verification timestamp.
- Add outputs bullet for the new static gate.

**Step 2: Commit**

```bash
git add tests/functions/test_options_preflight_contract.sh \
  docs/plans/2026-02-26-functions-options-preflight-contract-design.md \
  docs/plans/2026-02-26-functions-options-preflight-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add options preflight contract gate"
```
