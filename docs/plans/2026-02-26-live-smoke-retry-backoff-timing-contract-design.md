# Live Smoke Retry Backoff Timing Contract Design

## Context

- Existing retry governance already covers:
  - static presence of exponential expression (`1 << (attempt - 1)`) in helper,
  - retry reason taxonomy + reason-action mapping,
  - runtime fallback when env values are invalid.
- Missing dedicated dynamic proof: backoff timing sequence with custom base delay and precise sleep boundary behavior.

## Problem

- A regression could preserve static expression while breaking runtime sequence ordering or sleep boundary semantics.
- Without a dynamic timing contract, retry pacing drift could reduce reliability under load or increase live smoke duration unexpectedly.

## Options

### Option A: rely on static grep contracts

Trade-offs:
- Pros: no extra test.
- Cons: weak runtime guarantee for sequencing behavior.

### Option B (Selected): add dynamic backoff timing contract

- Create deterministic helper-level test with scripted retry responses and captured `sleep()` calls.
- Validate:
  - exponential growth from configured base delay,
  - no sleep after terminal attempt,
  - no sleep when terminal failure is non-retriable.

Trade-offs:
- Pros: strong runtime confidence with low flake risk.
- Cons: one extra governance test file to maintain.

### Option C: infer from full live smoke logs

Trade-offs:
- Pros: no new helper-level harness.
- Cons: noisy signal and hard root-cause isolation.

## Chosen Design

- Implement Option B.
- Add `tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh`.
- Contract scenarios:
  - Retry-then-success with `ORCH_RETRY_BASE_DELAY_SECONDS=3` and `ORCH_MAX_ATTEMPTS=5`: sleep sequence must be `3 6`, and success at attempt `3/5`.
  - Retry-exhausted with `ORCH_RETRY_BASE_DELAY_SECONDS=3` and `ORCH_MAX_ATTEMPTS=3`: sleep sequence must be `3 6` only (no terminal sleep), failure reason `worker_limit_exhausted`.
  - Non-retriable terminal payload: zero sleep calls, failure reason `done_event_missing`.
