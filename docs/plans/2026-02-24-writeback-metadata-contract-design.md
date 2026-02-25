# Writeback Metadata Contract Gate Design

## Context

- `affectedTables` contract gate is now in place.
- Writeback semantics still depend on additional metadata fields: `eventSourceTable`, `eventType`, `targetSnapshotType`.
- These fields drive downstream refresh behavior and observability interpretation.

## Problem

- Regressions in metadata semantics can pass table-coverage checks but still break snapshot routing intent.
- No dedicated static gate currently verifies these fields by action/module.

## Options

### Option A: Rely only on live e2e behavior

Trade-offs:
- Pros: no extra tests.
- Cons: slow feedback and weak semantic diagnostics.

### Option B (Selected): Add dedicated static contract gate for writeback metadata

- New function-level test validates expected metadata per action:
  - `eventSourceTable`
  - `eventType`
  - `targetSnapshotType`
- Keep runtime e2e as secondary proof.

Trade-offs:
- Pros: fast and explicit drift detection.
- Cons: requires updates when intentionally changing metadata policy.

### Option C: Parse TypeScript AST for strict structural checks

Trade-offs:
- Pros: highest precision.
- Cons: complexity not justified now.

## Chosen Design

- Implement Option B with a deterministic shell test under `tests/functions/`.
- Enforce one expected metadata tuple per execution action/module.
- Verify via `final_gate` and record evidence in governance docs.
