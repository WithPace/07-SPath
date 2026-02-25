# Live Smoke Retry Cards Contract Design

## Context

- Retry helper has mature governance around retry reasons, reason-action mapping, observability, outcome state, and state reset.
- One remaining branch is under-specified: `require_cards=1` when response is `event: done` but payload lacks `cards`.

## Problem

- Current branch reports `done_event_missing`, which semantically conflates two different failures:
  - stream done marker missing
  - done marker present but cards payload missing
- This weakens diagnostics and reason taxonomy precision.

## Options

### Option A: Keep current reason (`done_event_missing`)

Trade-offs:
- Pros: no code changes.
- Cons: ambiguous diagnosis and weaker governance clarity.

### Option B (Selected): Add explicit cards-missing terminal reason + contract gate

- Introduce `ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING="cards_payload_missing"`.
- In `require_cards` failure branch, use this reason and terminal-failure log format.
- Add dynamic gate `tests/e2e/test_live_smoke_retry_cards_contract.sh`.

Trade-offs:
- Pros: precise reason taxonomy, better observability, low-risk change.
- Cons: minor update in helper and static contracts.

### Option C: Separate helper function for cards validation

Trade-offs:
- Pros: cleaner decomposition.
- Cons: extra complexity for limited value.

## Chosen Design

- Implement Option B.
- Keep retry mechanics unchanged.
- Only refine terminal reason semantics and enforce via dedicated governance gate.
