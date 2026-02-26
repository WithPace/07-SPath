# Functions Writeback Before Done Contract Design

## Context

- Execution modules persist writeback metadata via `finalizeWriteback` and then stream SSE responses.
- Existing gates cover writeback metadata fields and done-event request_id presence.
- No dedicated static gate currently enforces ordering between writeback persistence and terminal SSE `done`.

## Problem

- A refactor can move `sseEvent("done", ...)` construction before `await finalizeWriteback(...)`.
- This can expose “client marked complete, backend writeback pending/failed” inconsistencies.
- Runtime smoke may not localize this ordering drift quickly.

## Options

### Option A: rely on code review and live smoke

Trade-offs:
- Pros: no additional static checks.
- Cons: ordering regressions are discovered late with weaker root-cause precision.

### Option B (Selected): add static ordering contract gate

- Add one static contract test over 6 module functions:
  - `chat-casual`
  - `assessment`
  - `training`
  - `training-advice`
  - `training-record`
  - `dashboard`
- Enforce:
  - `await finalizeWriteback({` exists
  - `sseEvent("done",` exists
  - line number of `finalizeWriteback` is strictly before `done`

Trade-offs:
- Pros: deterministic, fast, governance-aligned.
- Cons: lexical ordering check is style-coupled.

### Option C: runtime transactional probe test

Trade-offs:
- Pros: stronger behavior-level validation.
- Cons: more runtime complexity and slower governance feedback.

## Chosen Design

- Implement Option B with:
  - `tests/functions/test_writeback_before_done_contract.sh`
- Keep change additive with no runtime behavior changes.
