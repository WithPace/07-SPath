# Live Smoke Retry Transport-Failure Contract Design

## Context

- Retry helper is invoked from live smoke scripts that run with `set -euo pipefail`.
- Current helper captures orchestrator response via command substitution:
  - `response=$(curl ...)`
- Under `set -e`, a non-zero `curl` exit in command substitution can abort the whole script before helper retry/failure logic runs.

## Problem

- Transient transport failures (e.g., connection reset) can bypass helper governance:
  - no controlled retry path,
  - no terminal reason writeback,
  - brittle live smoke behavior.

## Options

### Option A: keep current behavior

Trade-offs:
- Pros: no code changes.
- Cons: transport failures remain ungoverned and can hard-exit scripts.

### Option B (Selected): explicit transport-failure retry/terminal semantics

- Capture `curl` exit code safely under `set -e` using:
  - `response=$(curl ...) || curl_exit=$?`
- Add transport reason taxonomy:
  - retry reason: `transport_error`
  - terminal reason: `transport_error_exhausted`
- Map transport failures to retry path while attempts remain; otherwise terminal failure with state writeback.

Trade-offs:
- Pros: resilient behavior and deterministic diagnostics.
- Cons: small taxonomy expansion and contract updates.

### Option C: wrapper-level retries only

Trade-offs:
- Pros: no helper changes.
- Cons: duplicates retry policy outside helper and weakens governance centralization.

## Chosen Design

- Implement Option B.
- Add dynamic contract gate `tests/e2e/test_live_smoke_retry_transport_failure_contract.sh` with `set -euo pipefail`.
- Contract scenarios:
  - first transport failure then success -> retry occurs, success returns, state reflects attempt `2/N`.
  - transport failure exhausted -> terminal reason `transport_error_exhausted`, retry count and attempt are deterministic.
- Align static reason/reason-action/observability contracts with new transport reason constants and branch semantics.
