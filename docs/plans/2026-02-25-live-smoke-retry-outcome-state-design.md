# Live Smoke Retry Outcome State Contract Design

## Context

- Retry helper already has taxonomy constants and reason->action governance gates.
- Current observable state after helper call is limited to `ORCH_LAST_REQUEST_ID` and `ORCH_LAST_RESPONSE`.
- For deterministic diagnostics and future script assertions, we need stable post-call outcome fields.

## Problem

- Callers cannot reliably distinguish success/failure class and terminal reason without re-parsing raw response/log lines.
- Existing contracts do not enforce stateful outcome metadata.

## Options

### Option A: Keep response-only state

Trade-offs:
- Pros: no change.
- Cons: weak introspection and harder future governance hooks.

### Option B (Selected): Add canonical outcome state variables + dynamic contract gate

- Add helper-managed state variables:
  - `ORCH_LAST_RESULT` (`success` or `failure`)
  - `ORCH_LAST_FAILURE_REASON` (empty on success)
  - `ORCH_LAST_ATTEMPT` (`<n>/<max>`)
- Add dynamic test `tests/e2e/test_live_smoke_retry_outcome_state_contract.sh` to simulate:
  - success path
  - worker-limit exhausted path
  - done-event-missing path

Trade-offs:
- Pros: stronger runtime semantics and reusable diagnostics.
- Cons: small helper state extension.

### Option C: External JSON diagnostic blob

Trade-offs:
- Pros: richer structure.
- Cons: overkill for current shell helper.

## Chosen Design

- Implement Option B with minimal helper state additions.
- Keep existing behavior untouched; only append deterministic post-call state metadata.
