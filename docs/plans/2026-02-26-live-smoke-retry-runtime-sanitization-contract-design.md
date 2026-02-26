# Live Smoke Retry Runtime Sanitization Contract Design

## Context

- Existing retry governance already has a static limits contract (`test_live_smoke_retry_limits_contract.sh`) that validates:
  - `orchestrator_sanitize_positive_int` behavior by direct function calls.
  - helper wiring to `ORCH_MAX_ATTEMPTS` and `ORCH_RETRY_BASE_DELAY_SECONDS`.
- Missing piece: dynamic runtime proof that invalid env inputs are actually sanitized during `orchestrator_call_with_retry` execution path.

## Problem

- Static contracts can miss runtime regressions where attempt loops or backoff sequencing drift from sanitized defaults.
- Without a dynamic gate, invalid env values could leak into runtime behavior and increase flakiness in live smoke scripts.

## Options

### Option A: Keep static limits contract only

Trade-offs:
- Pros: zero new maintenance cost.
- Cons: no runtime assurance for attempt/backoff fallback semantics.

### Option B (Selected): Add dynamic runtime sanitization contract

- Create a deterministic helper-level contract test that:
  - injects invalid env values at call time,
  - forces retry path via `WORKER_LIMIT`,
  - asserts runtime fallback to default bounds (`max_attempts=4`, `base_delay=1`) via observed state and sleep sequence.

Trade-offs:
- Pros: validates behavior end-to-end inside helper runtime path with low flake risk.
- Cons: adds one more test to governance suite.

### Option C: Depend only on full live smoke behavior

Trade-offs:
- Pros: no new helper-level test file.
- Cons: weak signal; hard to isolate runtime sanitization regressions.

## Chosen Design

- Implement Option B.
- Add `tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh`.
- Dynamic assertions:
  - Invalid low values (`ORCH_MAX_ATTEMPTS=1`, `ORCH_RETRY_BASE_DELAY_SECONDS=0`) fall back to `4/1`.
  - Invalid non-numeric values (`abc` / `nan`) also fall back to `4/1`.
  - Observed runtime effects:
    - `request_ids` length = `4`
    - `ORCH_LAST_ATTEMPT=4/4`
    - `ORCH_LAST_RETRY_COUNT=3`
    - `sleep` sequence = `1 2 4`
    - terminal reason = `worker_limit_exhausted`
