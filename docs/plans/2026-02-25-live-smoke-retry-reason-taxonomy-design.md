# Live Smoke Retry Reason Taxonomy Contract Design

## Context

- Retry helper now logs structured retry and terminal failure fields.
- Reason values are still partially string-literal based, which can drift over time.
- Governance objective is to keep reason taxonomy stable for machine parsing and incident triage.

## Problem

- If reason strings diverge across retry and terminal logs, dashboards and grep-based diagnostics become brittle.
- Current gates do not enforce canonical reason constants and usage.

## Options

### Option A: Keep literal strings

Trade-offs:
- Pros: no refactor.
- Cons: higher drift risk; weaker governance signal.

### Option B (Selected): Canonical reason constants + taxonomy contract gate

- Add helper-level constants for retry/terminal reasons.
- Enforce constants usage in logs and assignments.
- Add static gate `tests/e2e/test_live_smoke_retry_reason_contract.sh`.

Trade-offs:
- Pros: stable taxonomy, low risk, low runtime impact.
- Cons: small helper refactor + one extra gate.

### Option C: External schema (JSON/YAML) for reasons

Trade-offs:
- Pros: strongest formalism.
- Cons: unnecessary complexity for current Bash helper scope.

## Chosen Design

- Implement Option B with three canonical constants:
  - `ORCH_RETRY_REASON_WORKER_LIMIT`
  - `ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED`
  - `ORCH_TERMINAL_REASON_DONE_EVENT_MISSING`
- Add static taxonomy gate to prevent reason drift.
