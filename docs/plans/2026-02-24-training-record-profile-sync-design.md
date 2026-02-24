# Training Record Profile Sync Design

## Context

- Current `training-record` chain writes `training_sessions` + `chat_messages` + writeback logs.
- Product and data docs define that each training record should incrementally update `children_profiles.domain_levels`.
- Governance now requires execution chain behavior to align with this writeback expectation.

## Problem

- `children_profiles` is not updated in the current `training-record` function.
- This causes a gap between documented business chain and actual data side effects.

## Options

### Option A (Selected): In-function incremental profile version write

- In `training-record`, read latest profile version, compute next `domain_levels`, insert new profile row.
- Update `finalizeWriteback` metadata (`affected_tables`, payload, snapshot target) to include profile writeback.
- Extend existing live e2e to assert profile side effects.

Trade-offs:
- Pros: Minimal scope, explicit behavior, fast to verify in current chain.
- Cons: Domain scoring heuristic is simple and can be further refined later.

### Option B: DB trigger on `training_sessions` to auto-write profile

- Trigger performs version increment and profile update.

Trade-offs:
- Pros: Centralized enforcement.
- Cons: More migration complexity and lower function-level transparency.

### Option C: Outbox-only marker, profile update deferred to downstream worker

- Keep function as-is, only emit event for later profile update.

Trade-offs:
- Pros: Minimal immediate change.
- Cons: Does not satisfy current immediate writeback requirement.

## Design Summary

- Keep architecture with `orchestrator -> training-record`.
- Add deterministic, minimal heuristics inside `training-record`:
  - Detect one target domain from message/model text.
  - Apply small score delta from success rate and duration.
  - Insert `children_profiles` new row with `version+1`.
- Keep backward compatibility for existing API response.
- Strengthen tests:
  - Static presence: `training-record` must reference `children_profiles`.
  - Live e2e: assert `children_profiles` row exists and `operation_logs.affected_tables` contains `children_profiles`.
