# Live Smoke Retry Reason-Action Contract Design

## Context

- Retry helper now has canonical reason taxonomy constants.
- Governance still lacks explicit guarantee that each reason maps to the correct action path.
- Incorrect mapping would silently break resilience semantics or observability meaning.

## Problem

- `WORKER_LIMIT` reason must trigger retry with backoff + continue (when attempts remain).
- `worker_limit_exhausted` and `done_event_missing` reasons must terminate with `return 1` and terminal log.
- Without a contract, edits can invert/skip these action paths.

## Options

### Option A: Keep implicit behavior checks via existing tests

Trade-offs:
- Pros: no new gate.
- Cons: action mapping invariants remain under-specified.

### Option B (Selected): Add static reason->action contract gate

- Add `tests/e2e/test_live_smoke_retry_reason_action_contract.sh`.
- Enforce helper-level mapping invariants:
  - retry reason condition and `continue` path
  - terminal reasons assignment and `return 1`
  - terminal log emission before failure return

Trade-offs:
- Pros: precise governance, low cost, stable.
- Cons: one additional static contract maintenance point.

### Option C: Add behavioral simulation for every branch

Trade-offs:
- Pros: stronger dynamic assurance.
- Cons: higher script complexity and fragility in Bash test harness.

## Chosen Design

- Implement Option B now.
- Keep dynamic live checks in `final_gate` as complementary runtime signal.
- Use static gate to lock reason/action branch semantics against drift.
