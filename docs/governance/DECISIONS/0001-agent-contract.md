# ADR 0001: Adopt Agent Contract as Code

## Status
Accepted

## Date
2026-02-23

## Context
StarPath needs consistent governance across Codex, Claude, and Cursor before code implementation starts.

## Decision
Use one source contract (`contract.yaml`) and generate all runtime agent rules from it. Enforce verification in CI and block merge on drift or missing required clauses.

## Consequences
- Positive: single source of truth, auditable changes, reduced multi-agent drift.
- Cost: initial tooling and maintenance for generation/verification scripts.
