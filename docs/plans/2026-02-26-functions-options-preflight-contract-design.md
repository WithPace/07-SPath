# Functions OPTIONS Preflight Contract Design

## Context

- Execution-chain functions expose browser-consumable SSE APIs and must support CORS preflight.
- Current function files already include `OPTIONS` handling, but this behavior is protected only implicitly.
- Recent governance increments added static gates for auth/body-parse, forwarding, error mapping, and request-id lifecycle.

## Problem

- A future refactor can accidentally remove or alter `OPTIONS` preflight handling in one module.
- Runtime smoke may miss this regression until frontend/browser flows fail.
- Missing a static contract gate weakens governance-first guarantees for API ingress behavior.

## Options

### Option A: rely on runtime smoke only

Trade-offs:
- Pros: no new static test.
- Cons: preflight regressions are detected late and root-cause localization is slower.

### Option B (Selected): add static OPTIONS preflight contract gate

- Add one static test over 7 function entry files:
  - `orchestrator`
  - `chat-casual`
  - `assessment`
  - `training`
  - `training-advice`
  - `training-record`
  - `dashboard`
- Enforce two invariants in each file:
  - `if (req.method === "OPTIONS")`
  - `return new Response(null, { headers: SSE_HEADERS });`

Trade-offs:
- Pros: deterministic, fast, and governance-aligned.
- Cons: string-level coupling to current source style.

### Option C: add e2e browser preflight checks

Trade-offs:
- Pros: behavior-level confidence in real HTTP flow.
- Cons: slower and higher maintenance for incremental governance gating.

## Chosen Design

- Implement Option B via:
  - `tests/functions/test_options_preflight_contract.sh`
- Keep change additive with no runtime behavior changes in function code unless test reveals drift.
