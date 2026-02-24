# Training Memory Sync Design

## Context

- Current `training` chain writes `training_plans` + `chat_messages` + writeback logs.
- `chat-casual` and `training-advice` already write `children_memory.current_focus`.
- Governance target is consistent chain side effects across training-related modules.

## Problem

- `training` does not update `children_memory`, causing writeback inconsistency.
- Existing `training` live e2e does not assert memory side effects.

## Options

### Option A: Keep `training` plan-only writeback

- No code change.

Trade-offs:
- Pros: Zero migration risk.
- Cons: Inconsistent chain behavior; weak governance evidence.

### Option B (Selected): Upsert `children_memory` inside `training`

- Upsert by `child_id` and write:
  - `current_focus`
  - `last_interaction_summary`
  - `updated_at`
- Extend `finalizeWriteback.affectedTables` with `children_memory`.
- Extend live e2e assertions for `children_memory` and operation log table coverage.

Trade-offs:
- Pros: Immediate consistency, minimal scope, no extra infra.
- Cons: `current_focus` remains heuristic text synthesis.

### Option C: Defer memory update to outbox consumer

- `training` writes marker only; background worker updates memory.

Trade-offs:
- Pros: Thinner function.
- Cons: Not aligned with current live writeback expectations.

## Chosen Design

- Implement Option B.
- Keep orchestrator routing unchanged.
- Add RED assertions first, then minimal implementation in `training`.
- Verify with real Supabase live e2e and final gate.
