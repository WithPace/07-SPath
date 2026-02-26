# Live Smoke Retry Transport Exit-Code Contract Design

## Context

- Transport-failure resilience and transport observability gates now exist.
- Current transport logs and state reason taxonomy are deterministic, but the transport exit code is not explicitly persisted.

## Problem

- When transport failures occur, diagnostics lose critical context (exit code), making it harder to distinguish timeout/reset/DNS classes.
- `ORCH_LAST_RESPONSE` can be empty on transport exhaustion, reducing post-failure forensic value.

## Options

### Option A: Keep reason-only transport diagnostics

Trade-offs:
- Pros: no changes.
- Cons: weak triage signal for transport root causes.

### Option B (Selected): Add explicit exit-code diagnostics contract

- On transport failure:
  - Include `exit_code=<n>` in retry and terminal logs.
  - Persist synthetic response marker `transport_error_exit_code=<n>` for exhausted terminal state.
- Add dynamic contract gate to enforce this behavior.

Trade-offs:
- Pros: stronger diagnostics with minimal complexity.
- Cons: small helper/log format expansion.

### Option C: Add separate structured telemetry channel

Trade-offs:
- Pros: richest observability.
- Cons: overkill for current governance stage.

## Chosen Design

- Implement Option B.
- Add `tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh`.
- Contract scenarios:
  - transport retry then success: retry log contains `reason=transport_error exit_code=28`.
  - transport exhausted: terminal log contains `reason=transport_error_exhausted exit_code=28`, and `ORCH_LAST_RESPONSE` contains `transport_error_exit_code=28`.
