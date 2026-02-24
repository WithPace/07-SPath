# Dashboard Affected Tables Accuracy Design

## Context

- `dashboard` module writes assistant rows into `chat_messages` with `cards_json`.
- `finalizeWriteback` for `dashboard_generate` currently records `affectedTables` as `training_sessions`, `assessments`, `training_plans`, etc., but omits `chat_messages`.
- Governance direction is writeback metadata truthfulness and chain observability alignment.

## Problem

- `operation_logs.affected_tables` for `dashboard_generate` is missing the real write table.
- Existing live e2e for dashboard checks `chat_messages` and `operation_logs` existence, but does not validate `affected_tables` semantics.

## Options

### Option A: Keep current metadata

- No change.

Trade-offs:
- Pros: Zero risk.
- Cons: Metadata drift from real side effects, weaker governance evidence.

### Option B (Selected): Add `chat_messages` to dashboard affected tables + assert in live e2e

- Update `dashboard` writeback metadata to include `chat_messages`.
- Add e2e assertion: `operation_logs(action_name=dashboard_generate).affected_tables` includes `chat_messages`.

Trade-offs:
- Pros: Minimal scope, direct governance gain, no behavior change.
- Cons: None meaningful.

### Option C: Introduce separate `read_tables` metadata field

- Schema + contract + all modules refactor.

Trade-offs:
- Pros: Strong semantics split.
- Cons: Large cross-cut change, not needed now.

## Chosen Design

- Implement Option B.
- Keep runtime behavior unchanged; only correct metadata + verification.
- Follow TDD: add failing static/live assertions, implement minimal code, deploy dashboard, run focused e2e, run final gate, refresh governance evidence.
