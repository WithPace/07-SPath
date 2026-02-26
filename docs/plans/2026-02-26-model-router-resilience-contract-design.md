# Model Router Resilience Contract Design

## Context

- Execution-chain modules call `_shared/model-router.ts` for external LLM routing.
- Governance already protects route mapping, retry behavior, auth/body-parse, shared client singleton, and forwarding semantics.
- Model router currently has critical resilience assumptions not yet covered by static gates.

## Problem

- A refactor can accidentally remove dual-provider fallback and reduce availability.
- A refactor can switch chat completion calls to streaming unexpectedly (`stream: true`) and break current parsing expectations.
- A refactor can alter provider-selection semantics (`DEFAULT_LLM`) without contract visibility.

## Options

### Option A: Keep relying on runtime failures

Trade-offs:
- Pros: no additional tests.
- Cons: regressions discovered late and only under outage scenarios.

### Option B (Selected): Add static model-router resilience contract gate

- Add one contract test to enforce:
  - `pickProvider` supports `doubao` default and `kimi` selection by env hint.
  - `callModelLive` contains symmetric fallback branches (doubao->kimi and kimi->doubao).
  - `callDoubao` and `callKimi` both send `stream: false`.
  - Doubao model resolution guard exists.

Trade-offs:
- Pros: fast deterministic guard, no network dependency.
- Cons: string-level coupling to current implementation form.

### Option C: Add mocked runtime provider-failover tests

Trade-offs:
- Pros: behavior-level assurance.
- Cons: larger harness complexity for current stage.

## Chosen Design

- Implement Option B with:
  - `tests/functions/test_model_router_resilience_contract.sh`
- Keep scope additive; no production code behavior changes.
- Integrate automatically into `final_gate` via `tests/functions/*.sh`.
