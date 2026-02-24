# Affected Tables Contract Test Design

## Context

- Runtime modules now largely align `operation_logs.affected_tables` with real write side effects.
- Existing protection is fragmented across multiple e2e scripts and `test_chain_files.sh` grep checks.
- Current governance gap: no single, explicit contract test that blocks metadata drift per action.

## Problem

- Future edits can silently drop required tables from `affectedTables` without immediate, focused failure.
- Detecting drift currently relies on broad e2e sweeps, which are slower and less diagnostic.

## Options

### Option A: Keep relying on e2e and ad-hoc grep checks

Trade-offs:
- Pros: no additional work.
- Cons: weak prevention, slower root cause.

### Option B (Selected): Add dedicated function contract test for action-to-table expectations

- Add `tests/functions/test_affected_tables_contract.sh` with explicit expectations per action.
- Validate required tables exist in each function `affectedTables` declaration.
- Keep existing e2e checks as runtime proof.

Trade-offs:
- Pros: fast failure, clear diagnostics, governance-first guardrail.
- Cons: adds one maintenance surface when new modules are added.

### Option C: Build AST-level parser for TypeScript metadata verification

Trade-offs:
- Pros: strongest static precision.
- Cons: overkill for current repo maturity.

## Chosen Design

- Implement Option B.
- Add a deterministic shell contract test that enforces expected `affectedTables` tokens by module/action.
- Register evidence in governance docs after full gate run.
