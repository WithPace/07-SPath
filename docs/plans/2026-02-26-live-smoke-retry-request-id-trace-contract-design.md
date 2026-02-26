# Live Smoke Retry Request-ID Trace Contract Design

## Context

- `tests/e2e/_shared/orchestrator_retry.sh` appends a new `request_id` for every attempt and writes `ORCH_LAST_REQUEST_ID` for the final attempt outcome.
- Existing retry governance covers retry triggers, limits, reason taxonomy, reason-action mapping, observability, outcome state, state reset, and cards-required terminal semantics.
- There is no dedicated dynamic gate that validates request-id lineage across multi-attempt calls.

## Problem

- A regression could break per-attempt `request_id` append behavior or final pointer semantics without violating current gates.
- Missing lineage verification weakens traceability during live incident analysis.

## Options

### Option A: Extend static grep contracts only

Trade-offs:
- Pros: lowest implementation effort.
- Cons: cannot prove runtime state behavior across retries.

### Option B (Selected): Add dynamic request-id trace contract gate

- Create a focused helper-level dynamic test with deterministic `uid` and `curl` stubs.
- Validate `request_ids` history and `ORCH_LAST_REQUEST_ID` terminal pointer across success and failure paths.

Trade-offs:
- Pros: high confidence on runtime semantics, low flake risk, no network dependency.
- Cons: one more governance gate to maintain.

### Option C: Validate only through live orchestrator tests

Trade-offs:
- Pros: full end-to-end realism.
- Cons: slower and noisier signal; harder to isolate helper regressions.

## Chosen Design

- Implement Option B.
- Add `tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh`.
- Contract scenarios:
  - First-attempt success: `request_ids` has one id; `ORCH_LAST_REQUEST_ID` equals that id.
  - Retry then success: `request_ids` records each attempt in order; `ORCH_LAST_REQUEST_ID` equals second attempt id.
  - Retry exhausted failure: `request_ids` still records each attempt; `ORCH_LAST_REQUEST_ID` equals final attempt id and failure reason is `worker_limit_exhausted`.
- Keep helper logic unchanged unless RED exposes a real gap.
