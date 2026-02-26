# Functions Request ID Lifecycle Contract Design

## Context

- Execution-chain traces depend on stable `request_id` propagation from ingress to module writeback and SSE completion responses.
- Retry/helper contracts already protect request-id lineage on live-smoke wrapper side.
- Module-level `request_id` lifecycle semantics are currently implicit and not covered by a dedicated static gate.

## Problem

- A refactor can drop payload `request_id` inheritance, breaking cross-module trace joins.
- A refactor can stop passing `requestId` into `finalizeWriteback`, weakening `operation_logs`/outbox correlation.
- A refactor can omit `request_id` in `done` SSE payload, breaking client-side traceability.

## Options

### Option A: rely on runtime smoke only

Trade-offs:
- Pros: no extra tests.
- Cons: regressions discovered late and with weak root-cause localization.

### Option B (Selected): static request_id lifecycle contract gate

- Add one static test over 6 module functions:
  - `chat-casual`
  - `assessment`
  - `training`
  - `training-advice`
  - `training-record`
  - `dashboard`
- Enforce:
  - `requestId = payload.request_id || requestId;`
  - `finalizeWriteback({ requestId, ... })`
  - `sseEvent("done", ...)` includes `request_id: requestId`

Trade-offs:
- Pros: deterministic and fast governance guard.
- Cons: string-level coupling to current style.

### Option C: integration tests asserting request_id joins in DB

Trade-offs:
- Pros: behavior-level confidence.
- Cons: heavier runtime dependency and slower feedback.

## Chosen Design

- Implement Option B:
  - `tests/functions/test_request_id_lifecycle_contract.sh`
- Keep change additive and no runtime behavior changes.
