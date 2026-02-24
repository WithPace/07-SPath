# Chat Casual Memory Sync Design

## Context

- `chat-casual` currently writes `chat_messages` + outbox audit logs.
- Product/data docs require casual conversation to refresh long-term memory summaries.
- Other modules already cover key writebacks:
  - `training-advice -> children_memory.current_focus`
  - `assessment/training-record -> children_profiles`

## Problem

- Casual chat chain does not persist `children_memory.last_interaction_summary`.
- Live smoke for chat chain does not assert memory side effects.
- Governance evidence lacks memory writeback coverage for `chat_casual_reply`.

## Options

### Option A (Selected): In-function memory upsert

- In `chat-casual`, upsert `children_memory` by `child_id`.
- Always refresh `last_interaction_summary`.
- Preserve existing `current_focus` if present; otherwise initialize a lightweight focus hint.
- Add `children_memory` to `affectedTables`.

Trade-offs:
- Pros: minimal, fast, consistent with current edge-function ownership.
- Cons: summary extraction remains heuristic.

### Option B: Async only (outbox/worker)

- Emit event now, sync memory later.

Trade-offs:
- Pros: less sync latency in function.
- Cons: does not satisfy immediate writeback expectation.

### Option C: DB trigger on `chat_messages`

- Trigger updates memory summary on assistant message inserts.

Trade-offs:
- Pros: DB-level invariant.
- Cons: harder to tune summarization logic; coupling increases.

## Chosen Design

- Keep `orchestrator` and route behavior unchanged.
- In `chat-casual`:
  - read existing `children_memory.current_focus`
  - upsert memory with `last_interaction_summary` and stable `current_focus`
- Update writeback metadata:
  - `affectedTables` includes `children_memory`
  - payload includes memory id
- Extend chat live smoke:
  - verify memory row exists with non-empty `last_interaction_summary`
  - verify `operation_logs.affected_tables` includes `children_memory`
