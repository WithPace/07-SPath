# Orchestrator Route Contract Gate Design

## Context

- `orchestrator` maps module aliases to downstream function/action/module tuples.
- Runtime e2e verifies end-to-end behavior, but there is no dedicated static route contract guard.
- Existing checks mostly assert string presence, not route tuple integrity.

## Problem

- Route drift (alias typo, wrong function, wrong action) may bypass weak static checks.
- Diagnosis would rely on slower live e2e failures.

## Options

### Option A: Keep e2e-only route confidence

Trade-offs:
- Pros: no changes.
- Cons: slower feedback and weaker preflight governance.

### Option B (Selected): Add static route contract test for orchestrator

- Validate each route tuple explicitly:
  - module aliases
  - `functionName`
  - `actionName`
  - canonical `module`
- Keep current runtime behavior unchanged.

Trade-offs:
- Pros: fast drift detection, clearer failure messages.
- Cons: one additional static test to maintain when adding modules.

### Option C: Refactor to table-driven route map + generated tests

Trade-offs:
- Pros: central source of truth.
- Cons: broader refactor scope than needed now.

## Chosen Design

- Implement Option B as `tests/functions/test_orchestrator_route_contract.sh`.
- Enforce all current module route tuples and key alias branches.
- Validate with `final_gate` and update governance evidence.
