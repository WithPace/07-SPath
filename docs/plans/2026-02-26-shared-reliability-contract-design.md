# Shared Reliability Contract Design

## Context

- Execution-chain governance already has contracts for routing, writeback metadata, retries, transport diagnostics, and function auth/body parsing.
- Two high-impact reliability controls currently rely on code discipline without dedicated static gates:
  - `_shared/auth.ts` service client singleton reuse.
  - `_shared/finalize.ts` writeback finalization via single RPC path.

## Problem

- If `_shared/auth.ts` regresses to per-call `createClient`, runtime cost and connection churn can increase.
- If `_shared/finalize.ts` regresses to direct table inserts, transactional guarantee from `finalize_writeback` can be bypassed.
- Existing tests do not explicitly lock these two controls as a contract.

## Options

### Option A: Keep current coverage only

Trade-offs:
- Pros: no new code.
- Cons: critical reliability controls can regress silently.

### Option B (Selected): Add static shared reliability contract gate

- Add dedicated test under `tests/functions/`:
  - assert service client singleton pattern in `_shared/auth.ts`.
  - assert `finalizeWriteback` uses `rpc("finalize_writeback")`.
  - assert `_shared/finalize.ts` does not directly write `snapshot_refresh_events`/`operation_logs`.

Trade-offs:
- Pros: deterministic, fast, low-maintenance governance guard.
- Cons: static checks are string-based and tied to current implementation style.

### Option C: Add runtime performance/integration reliability tests

Trade-offs:
- Pros: stronger runtime confidence.
- Cons: adds remote dependency and flakiness; too heavy for this increment.

## Chosen Design

- Implement Option B with one static gate:
  - `tests/functions/test_shared_reliability_contract.sh`.
- Keep scope minimal (YAGNI) and integrate naturally into `final_gate` via `tests/functions/*.sh`.
- Update governance verification docs with new evidence and latest UTC timestamp.
