# Live Smoke Retry Parameter Guard Design

## Context

- `tests/e2e/_shared/orchestrator_retry.sh` currently accepts `ORCH_MAX_ATTEMPTS` and `ORCH_RETRY_BASE_DELAY_SECONDS` directly from env.
- Existing retry gates verify retry wiring and semantics presence, but do not constrain parameter drift.
- Governance objective is to keep live smoke runs resilient while preventing accidental misconfiguration.

## Problem

- Invalid or extreme env values can silently disable retries (`0`, negative, non-numeric) or create runaway waits (very large base delay).
- Current gates can still pass even if retry parameters drift out of safe bounds.

## Options

### Option A: Keep env values unconstrained

Trade-offs:
- Pros: maximum configurability.
- Cons: weak governance and unstable live verification behavior.

### Option B (Selected): Add parameter normalization + static contract gate

- Add helper-level normalization for retry parameters with explicit bounds.
- Add a dedicated gate that asserts:
  - normalization helper exists
  - boundary behavior is enforced
  - retry call path wires env values through bounded defaults

Trade-offs:
- Pros: low risk, deterministic governance, minimal runtime change.
- Cons: slightly reduced configurability outside guard range.

### Option C: Remove env overrides entirely

Trade-offs:
- Pros: fully deterministic behavior.
- Cons: loses useful operator override control during controlled troubleshooting.

## Chosen Design

- Implement Option B.
- Introduce `orchestrator_sanitize_positive_int` in retry helper.
- Guard contracts:
  - `ORCH_MAX_ATTEMPTS`: default `4`, allowed range `[2, 6]`
  - `ORCH_RETRY_BASE_DELAY_SECONDS`: default `1`, allowed range `[1, 5]`
- Add new gate `tests/e2e/test_live_smoke_retry_limits_contract.sh` that validates helper boundary behavior and wired defaults.
