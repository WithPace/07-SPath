# Live Smoke Retry Transport Observability Contract Design

## Context

- Transport-failure resilience is now covered by a dynamic gate ensuring retry/failure state behavior under `set -e`.
- Retry observability has a static grep contract for log format placeholders.
- Missing dynamic proof: transport retry and terminal branches emit canonical logs with resolved values.

## Problem

- A regression could keep static log templates but break emitted runtime fields for transport failures.
- This would degrade incident debugging quality even if retry behavior still works.

## Options

### Option A: keep static observability contract only

Trade-offs:
- Pros: no extra tests.
- Cons: runtime log correctness remains unproven.

### Option B (Selected): add dynamic transport observability gate

- Add deterministic helper-level test that triggers transport retry and transport exhaustion.
- Capture stderr and assert canonical runtime log lines with concrete values.

Trade-offs:
- Pros: verifies real emitted logs and reason mapping for transport paths.
- Cons: one extra governance script.

### Option C: validate only via full live smoke output

Trade-offs:
- Pros: no unit-like harness.
- Cons: noisy and less deterministic.

## Chosen Design

- Implement Option B.
- Add `tests/e2e/test_live_smoke_retry_transport_observability_contract.sh`.
- Dynamic assertions:
  - Scenario A (transport fail once then success): retry log includes `reason=transport_error`, `attempt=1/4`, `sleep_seconds=1`, correct module and request id.
  - Scenario B (transport exhausted with 3 attempts): terminal log includes `reason=transport_error_exhausted`, `attempt=3/3`, correct module and request id.
- Keep helper logic unchanged unless RED indicates missing/incorrect runtime logs.
