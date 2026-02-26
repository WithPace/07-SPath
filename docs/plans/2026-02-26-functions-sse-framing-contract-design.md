# Functions SSE Framing Contract Design

## Context

- Execution modules stream responses via SSE and frontend consumers rely on a stable frame order.
- Existing contracts already cover auth/body parsing, error mapping, writeback metadata, request-id lifecycle, and options preflight.
- No dedicated static contract currently locks the success-path SSE frame sequence.

## Problem

- A refactor can accidentally drop `stream_start`, remove `delta`, or alter frame ordering.
- Runtime smoke can still pass in some cases while frontend parsers regress on malformed framing.
- Missing a dedicated gate leaves core protocol semantics under-protected.

## Options

### Option A: rely on live smoke only

Trade-offs:
- Pros: no extra static test.
- Cons: regressions detected late with weaker localization.

### Option B (Selected): add static SSE framing contract gate

- Add one static contract test over 6 module entry files:
  - `chat-casual`
  - `assessment`
  - `training`
  - `training-advice`
  - `training-record`
  - `dashboard`
- Enforce each file contains:
  - `sseEvent("stream_start", { request_id: requestId })`
  - `sseEvent("delta", { text: model.text ... })`
  - `sseEvent("done", { ... })`
- Enforce lexical order: `stream_start` line < `delta` line < `done` line.

Trade-offs:
- Pros: deterministic, fast, governance-friendly.
- Cons: string-level coupling to current source style.

### Option C: add parser-level integration tests per module

Trade-offs:
- Pros: stronger runtime realism.
- Cons: higher maintenance and slower feedback loops for governance increments.

## Chosen Design

- Implement Option B with:
  - `tests/functions/test_sse_framing_contract.sh`
- Keep change additive and behavior-preserving unless drift is discovered.
