# Model Router Temperature Contract Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ensure `ModelCallOptions.temperature` is honored consistently for both Kimi and Doubao provider paths.

**Architecture:** Add a static functions contract gate to enforce temperature semantics in `_shared/model-router.ts`, then apply minimal code change so Kimi uses `options.temperature ?? 1`.

**Tech Stack:** TypeScript shared module, Bash + ripgrep static checks, existing final gate.

### Task 1: RED - add model-router temperature contract test

**Files:**
- Create: `tests/functions/test_model_router_temperature_contract.sh`

**Step 1: Write failing test first**

- Validate `_shared/model-router.ts` contains:
  - `const temperature = options.temperature ?? 1;` in Kimi path.
  - request body uses `temperature,` in Kimi payload.
  - Doubao keeps `temperature: options.temperature ?? 0.4,`.

**Step 2: Run RED**

Run:
- `bash tests/functions/test_model_router_temperature_contract.sh`

Expected:
- FAIL because current Kimi path still hardcodes `temperature = 1`.

### Task 2: GREEN - minimal code fix

**Files:**
- Modify: `supabase/functions/_shared/model-router.ts`
- Create: `tests/functions/test_model_router_temperature_contract.sh`

**Step 1: Implement fix**

- Change Kimi path to:
  - `const temperature = options.temperature ?? 1;`

**Step 2: Focused verification**

Run:
- `bash tests/functions/test_model_router_temperature_contract.sh`
- `bash tests/functions/test_model_router_resilience_contract.sh`
- `bash tests/functions/test_shared_modules.sh`

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

- Append temperature contract gate pass lines.
- Append latest full-gate pass lines + UTC timestamp.
- Add assertion bullet for model-router temperature semantics.

**Step 2: Commit**

```bash
git add tests/functions/test_model_router_temperature_contract.sh \
  supabase/functions/_shared/model-router.ts \
  docs/plans/2026-02-26-model-router-temperature-contract-design.md \
  docs/plans/2026-02-26-model-router-temperature-contract.md \
  docs/governance/REBUILD-VERIFICATION-2026-02-23.md \
  docs/governance/BASELINE-VERIFICATION-2026-02-23.md
git commit -m "fix(functions): honor model-router kimi temperature option"
```
