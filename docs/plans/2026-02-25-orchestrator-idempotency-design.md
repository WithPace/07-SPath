# Orchestrator Idempotency Live Gate Design

## Context

- `orchestrator` has request-level idempotency: it short-circuits when `operation_logs` already has `request_id + action_name + final_status=completed`.
- Existing live tests validate chain success and side effects, but do not explicitly test duplicate request behavior.

## Problem

- Idempotency behavior can regress silently (extra writes, duplicate assistant responses) without a dedicated gate.
- Governance currently proves writeback correctness, but not duplicate-call safety.

## Options

### Option A: Keep current coverage

Trade-offs:
- Pros: no extra runtime cost.
- Cons: idempotency is unguarded.

### Option B (Selected): Add dedicated idempotency live e2e

- New live script executes the same payload twice with the same `request_id`.
- Assert second response contains `idempotent=true`.
- Assert only one completed `operation_logs` row for that action/request.
- Assert chat side effects are single-write (`1 user + 1 assistant`).

Trade-offs:
- Pros: direct business-safety signal.
- Cons: one more live e2e in final gate.

### Option C: Replace live check with static code contract only

Trade-offs:
- Pros: fast.
- Cons: cannot prove runtime behavior.

## Chosen Design

- Implement Option B with shared retry-style robustness for transient `WORKER_LIMIT`.
- Keep scope to `chat_casual` path for deterministic side-effect counting.
- Add governance evidence and timestamp after full gate pass.
