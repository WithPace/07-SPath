# Multi-Module Chat Metadata Consistency Design

## Context

- Multiple modules write assistant rows into `chat_messages`.
- `dashboard` and `chat-casual` now include `chat_messages` in `operation_logs.affected_tables`.
- `assessment`, `training`, `training-advice`, and `training-record` still omit `chat_messages` despite direct inserts.

## Problem

- Writeback metadata is inconsistent across modules.
- Governance evidence can drift from real DB side effects.
- Existing e2e checks for these modules do not assert `chat_messages` coverage in `affected_tables`.

## Options

### Option A: Keep current metadata and only document caveat

Trade-offs:
- Pros: No runtime changes.
- Cons: Leaves known inconsistency and weakens auditability.

### Option B (Selected): Minimal metadata correction per module + e2e assertions

- Add `chat_messages` to `affectedTables` for:
  - `assessment_generate`
  - `training_generate`
  - `training_advice_generate`
  - `training_record_create`
- Extend live e2e assertions for each action.

Trade-offs:
- Pros: Small changes, immediate consistency, low risk.
- Cons: Requires multiple deployments.

### Option C: Introduce a new metadata model (`written_tables` vs `read_tables`)

Trade-offs:
- Pros: Strong semantics.
- Cons: Cross-cut schema/contract migration; too large for current increment.

## Chosen Design

- Implement Option B with strict TDD.
- Add RED assertions first (static + live).
- Apply minimal changes in 4 functions.
- Deploy affected functions to official Supabase, run focused e2e, then run full `final_gate`.
- Refresh governance evidence with new request IDs and timestamp.
