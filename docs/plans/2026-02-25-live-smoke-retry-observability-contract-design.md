# Live Smoke Retry Observability Contract Design

## Context

- Retry resilience gates already validate helper wiring, retry semantics, and parameter bounds.
- Current helper logs retry attempts, but governance has no strict contract for retry log fields and terminal failure diagnostics.
- When live smoke fails intermittently, missing structured retry/failure fields slows triage.

## Problem

- Retry and terminal failure logs can drift or become incomplete without governance detection.
- We need stable, machine-greppable observability fields in helper logs without adding runtime dependencies.

## Options

### Option A: Static grep-only log string checks

Trade-offs:
- Pros: smallest change.
- Cons: does not prove runtime path actually emits required fields.

### Option B (Selected): Behavioral observability contract test with function-level simulation

- Add `tests/e2e/test_live_smoke_retry_observability_contract.sh`.
- Source shared helper and override `curl/sleep/uid` for deterministic retry/failure simulation.
- Assert runtime stderr logs include required fields:
  - retry log: module, request_id, attempt/max, sleep_seconds
  - terminal failure log: module, request_id, attempt/max, reason

Trade-offs:
- Pros: strong signal with low cost; no network dependency.
- Cons: slightly more complex test harness.

### Option C: Full live chaos/fault-injection e2e

Trade-offs:
- Pros: highest realism.
- Cons: flakier and expensive in official Supabase environment.

## Chosen Design

- Implement Option B.
- Extend shared helper retry/failure log lines to include deterministic key-value fields.
- Add observability contract test to governance chain.
