# Functions Auth And Body-Parse Contract Design

## Context

- Current execution-chain functions are stable and `final_gate` passes.
- Earlier backend review highlighted historical risks around:
  - missing request authentication / child access checks.
  - multiple `req.json()` calls in a single request handler (body stream consumed twice).
- These risks are currently addressed in code, but there is no dedicated static gate to prevent regressions.

## Problem

- A future refactor can silently remove `authenticate` / `checkChildAccess` calls.
- A future refactor can accidentally add a second `req.json()` call and reintroduce body-consumption bugs.
- Existing chain tests verify functional hooks, but do not lock this specific reliability/security contract.

## Options

### Option A: Keep relying on code review only

Trade-offs:
- Pros: zero implementation effort.
- Cons: high regression risk; no CI guard for known high-impact failure modes.

### Option B (Selected): Add static functions contract gate

- Add one new test gate under `tests/functions/`.
- Assert for all 7 execution-chain function entry files:
  - `authenticate(req)` exists.
  - `checkChildAccess(user.id, payload.child_id)` exists.
  - exactly one `req.json(` call exists.
- Integrate into existing `final_gate` automatically via `tests/functions/*.sh`.

Trade-offs:
- Pros: low cost, deterministic, fast CI feedback, no runtime dependencies.
- Cons: static-string checks can be bypassed by major code style changes (acceptable for current governance stage).

### Option C: Add runtime integration auth/body-parse regression tests

Trade-offs:
- Pros: stronger behavioral confidence.
- Cons: significantly higher setup complexity and flakiness risk; not needed for this increment.

## Chosen Design

- Implement Option B with a dedicated static contract test:
  - `tests/functions/test_auth_and_body_parse_contract.sh`.
- Keep checks strict but minimal (YAGNI), focused on current architecture and known regression vectors.
- Record evidence in governance verification docs after full gate pass.
