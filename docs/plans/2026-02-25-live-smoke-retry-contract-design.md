# Live Smoke Retry Contract Gate Design

## Context

- Current gate `tests/e2e/test_live_smoke_retry_presence.sh` ensures live scripts source the shared retry helper and call `orchestrator_call_with_retry`.
- This covers wiring presence, but not retry semantics consistency.
- Governance priority is to prevent silent regressions in live-smoke resilience behavior.

## Problem

- Retry behavior could drift (attempt count, backoff, error trigger conditions, trace capture) while the current gate still passes.
- Live scripts could also drift from baseline HTTP retry flags used by shared `curl_common`.

## Options

### Option A: Keep presence-only gate

Trade-offs:
- Pros: no extra maintenance.
- Cons: weak governance signal; semantic regressions can pass.

### Option B (Selected): Add all-script retry contract gate with semantic checks

- Add `tests/e2e/test_live_smoke_retry_contract.sh`.
- Assert helper-level retry contract:
  - env-overridable max attempts/base delay defaults
  - WORKER_LIMIT-triggered retry branch
  - exponential backoff formula and `sleep`
  - request-id and response trace writeback fields
- Assert script-level contract for all live orchestrator scripts:
  - shared helper sourced
  - `orchestrator_call_with_retry` used
  - shared `curl_common` includes `--retry`, `--retry-delay`, `--retry-all-errors`

Trade-offs:
- Pros: stronger static governance with low implementation risk.
- Cons: one more static gate to maintain.

### Option C: Add fault-injection live retry test

Trade-offs:
- Pros: highest confidence in runtime behavior.
- Cons: costly and flaky in live environment; larger blast radius.

## Chosen Design

- Implement Option B now.
- Keep existing `test_live_smoke_retry_presence.sh` as a narrow smoke contract.
- Add new semantic retry contract gate to harden governance without changing runtime logic.
