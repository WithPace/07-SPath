# Orchestrator Forwarding Contract Design

## Context

- Existing contracts cover route tuples, writeback metadata, retry behavior, auth/body-parse guards, and shared reliability primitives.
- `orchestrator` remains the runtime fan-out entrypoint for the 6 downstream module functions.
- Forwarding semantics are critical but currently not guarded by a dedicated static contract.

## Problem

- A refactor can silently break forwarding payload fields (`request_id`, `module`, `conversation_id`) or auth header passthrough.
- A refactor can weaken idempotency short-circuit query constraints.
- Route contract alone does not enforce downstream fetch call structure.

## Options

### Option A: Rely on live smoke tests only

Trade-offs:
- Pros: no extra static checks.
- Cons: regression signal is slower and can be masked by transient runtime errors.

### Option B (Selected): Add static forwarding contract gate

- Introduce one static test that enforces:
  - downstream URL format and `fetch` invocation exists.
  - passthrough auth header uses `getAuthHeader(req)`.
  - body includes canonical forwarding fields.
  - idempotency query keeps `request_id + action_name + final_status=completed`.
  - response proxies downstream SSE body with `SSE_HEADERS`.

Trade-offs:
- Pros: deterministic guard for high-impact routing assumptions.
- Cons: string-coupled checks may need updates if implementation style changes.

### Option C: Add dedicated runtime forwarding integration test harness

Trade-offs:
- Pros: stronger behavioral assurance.
- Cons: higher complexity and runtime dependency overhead for this stage.

## Chosen Design

- Implement Option B with:
  - `tests/functions/test_orchestrator_forwarding_contract.sh`
- Keep scope minimal and additive; no production behavior changes.
- Integrate naturally into `final_gate` through `tests/functions/*.sh`.
