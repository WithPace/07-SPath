# Live Smoke Retry State Reset Contract Design

## Context

- Retry helper now exposes outcome state fields (`ORCH_LAST_RESULT`, `ORCH_LAST_FAILURE_REASON`, `ORCH_LAST_ATTEMPT`).
- A missing guard remains: stale state from prior calls can silently pollute diagnostics if reset discipline drifts.

## Problem

- We need governance to guarantee per-call state reset semantics.
- We also need a deterministic retry counter to show how many retry loops actually happened in the latest call.

## Options

### Option A: Keep existing fields only

Trade-offs:
- Pros: no changes.
- Cons: cannot assert reset completeness or retry-count correctness.

### Option B (Selected): Add reset+counter state contract gate

- Introduce helper field `ORCH_LAST_RETRY_COUNT`.
- Enforce call-start reset and per-branch updates via dynamic contract test.
- Validate no stale carry-over across successive calls.

Trade-offs:
- Pros: stronger determinism for diagnostics and downstream assertions.
- Cons: small helper state extension.

### Option C: Parse logs only for retry count

Trade-offs:
- Pros: no helper changes.
- Cons: brittle; loses direct state contract semantics.

## Chosen Design

- Implement Option B with one dynamic test: `tests/e2e/test_live_smoke_retry_state_reset_contract.sh`.
- Contract guarantees:
  - call-start state reset
  - success/failure state correctness
  - retry-count accuracy (`0` no retry, `1+` when retry occurred)
