# Model Router Resilience Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prevent regressions in provider-selection and fallback robustness for `_shared/model-router.ts`.

**Architecture:** Add one static contract test covering provider pick semantics, non-streaming completion config, dual fallback structure, and doubao model-resolution guard. Keep implementation test-only + governance evidence updates.

**Tech Stack:** Bash + ripgrep static checks, existing CI/final gate.

### Task 1: RED - add model-router resilience contract test

**Files:**
- Create: `tests/functions/test_model_router_resilience_contract.sh`

**Step 1: Write failing test first**

- Contract checks in `supabase/functions/_shared/model-router.ts`:
  - `pickProvider` supports:
    - `const preferred = (Deno.env.get("DEFAULT_LLM") ?? "doubao").toLowerCase();`
    - `if (preferred.includes("kimi")) return "kimi";`
    - default return `"doubao"`.
  - Non-streaming calls in both providers:
    - `stream: false` in kimi request body.
    - `stream: false` in doubao request body.
  - Dual fallback in `callModelLive`:
    - doubao primary then `catch` kimi fallback.
    - kimi primary then `catch` doubao fallback.
  - Doubao model guard:
    - `if (!model) { throw new Error("missing env: DOUBAO_ENDPOINT_ID or DOUBAO_MODEL"); }`

**Step 2: Run RED**

Run:
- `bash tests/functions/test_model_router_resilience_contract.sh`

Expected:
- FAIL because file does not yet exist.

### Task 2: GREEN - implement static contract gate

**Files:**
- Create: `tests/functions/test_model_router_resilience_contract.sh`

**Step 1: Add deterministic checks**

- Use strict fail messages for each contract rule.

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_model_router_resilience_contract.sh`
- `bash tests/functions/test_shared_modules.sh`
- `bash tests/functions/test_shared_reliability_contract.sh`

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

- Append model-router contract command pass lines.
- Append latest full-gate pass lines + UTC timestamp.
- Add assertion bullet for model-router resilience contract.

**Step 2: Commit**

```bash
git add tests/functions/test_model_router_resilience_contract.sh \
  docs/plans/2026-02-26-model-router-resilience-contract-design.md \
  docs/plans/2026-02-26-model-router-resilience-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "test(functions): add model-router resilience contract gate"
```
