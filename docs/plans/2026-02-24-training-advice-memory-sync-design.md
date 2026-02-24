# Training Advice Memory Sync Design

## Context

- Current `training-advice` chain writes `training_plans` + `chat_messages` + writeback logs.
- Product/data docs require training plan updates to sync `children_memory.current_focus`.
- Assessment and training-record profile sync are already implemented; this is the next missing chain writeback.

## Problem

- `training-advice` does not update `children_memory.current_focus`.
- Existing assessment-training live e2e does not assert memory writeback.
- Governance evidence does not include training-advice memory side effects.

## Options

### Option A (Selected): In-function upsert to `children_memory`

- In `training-advice`, upsert by `child_id` and set:
  - `current_focus`
  - `last_interaction_summary`
  - `updated_at`
- Extend writeback metadata `affected_tables` with `children_memory`.
- Extend current assessment-training live e2e to assert memory side effects.

Trade-offs:
- Pros: Minimal scope, immediate value, consistent with existing function ownership.
- Cons: Current focus extraction remains heuristic.

### Option B: Outbox-only marker for later memory sync

- Emit event and let downstream worker update memory.

Trade-offs:
- Pros: Smaller function.
- Cons: Does not satisfy immediate writeback expectation for live chain.

### Option C: DB trigger on `training_plans`

- Trigger updates `children_memory.current_focus`.

Trade-offs:
- Pros: Centralized DB invariant.
- Cons: More schema coupling, harder iterative logic tuning.

## Chosen Design

- Keep `orchestrator -> training-advice` routing unchanged.
- Add memory upsert in `training-advice`:
  - derive `current_focus` from plan title + model summary
  - upsert `children_memory` by `child_id`
- Update `finalizeWriteback`:
  - include `children_memory` in `affectedTables`
  - include memory identifiers in payload
- Update tests:
  - static: `training-advice` references `children_memory`
  - live e2e: `children_memory.current_focus` exists and op log includes `children_memory`
