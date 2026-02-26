# Functions Error Response Contract Design

## Context

- Execution-chain functions now have strong governance coverage for routing, forwarding, auth/body-parse, shared reliability, and model-router resilience.
- Error responses remain a cross-function stability surface affecting client behavior and observability.
- Current code largely follows SSE error envelopes, but no dedicated static contract protects this behavior.

## Problem

- A refactor can accidentally drop `BAD_REQUEST`/`AUTH_FORBIDDEN` branches or alter expected HTTP status mapping.
- A refactor can break catch-path `INTERNAL_ERROR` SSE responses and cause inconsistent client error handling.
- Existing tests do not explicitly lock this error semantics contract across all 7 function entrypoints.

## Options

### Option A: Rely on runtime smoke only

Trade-offs:
- Pros: no additional static checks.
- Cons: inconsistent error semantics may surface late and be hard to triage.

### Option B (Selected): Add static error-response contract gate

- Add one static test validating each function entrypoint keeps:
  - explicit `BAD_REQUEST` SSE branch mapped to HTTP `400`.
  - explicit `AUTH_FORBIDDEN` SSE branch mapped to HTTP `403`.
  - catch-path `INTERNAL_ERROR` SSE with HTTP `500`.
  - success response with `SSE_HEADERS`.

Trade-offs:
- Pros: fast deterministic guard, governance visibility, no runtime dependencies.
- Cons: string-level coupling to current response structure.

### Option C: Add full mocked runtime error-path integration tests

Trade-offs:
- Pros: stronger behavioral realism.
- Cons: larger harness complexity and maintenance cost at this stage.

## Chosen Design

- Implement Option B with:
  - `tests/functions/test_error_response_contract.sh`
- Keep scope additive with no production behavior changes.
- Integrate through existing `final_gate` function-test sweep.
