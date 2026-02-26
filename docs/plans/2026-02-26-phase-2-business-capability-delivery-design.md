# Phase 2 Business Capability Delivery Design

**Date:** 2026-02-26  
**Status:** Approved

## 1. Goal

Define the next delivery phase after governance foundation completion so the project can shift from "contract-first hardening" to "business capability outcomes" with measurable acceptance.

Phase 2 primary goal:
- Deliver production-usable business capabilities across the existing execution chain (`orchestrator` + 6 modules) with deterministic contracts, scenario-level acceptance, and release readiness.

## 2. Context

- Phase 1 governance-first controls are complete:
  - contract generation and verification gates
  - CI blocking flow
  - gap register process
  - execution-chain rebuild and live smoke baseline
- Current reliability contracts heavily protect runtime and transport behavior.
- Remaining risk is no longer "governance missing", but "business behavior quality, consistency, and release confidence at scenario level".

## 3. Options Considered

### Option A: Extend only static contract gates

Pros:
- Fast incremental additions.
- Low implementation risk.

Cons:
- Does not sufficiently prove business outcome quality.
- Can pass while user-level scenarios still degrade.

### Option B (Selected): Outcome-driven Phase 2 with scenario acceptance

Pros:
- Aligns with business capability delivery target.
- Keeps governance strength while adding behavior-level confidence.
- Enables clear release criteria.

Cons:
- Higher test and fixture maintenance cost.

### Option C: Jump directly to product rollout without dedicated phase definition

Pros:
- Maximum short-term speed.

Cons:
- High regression/release risk.
- Weak traceability for what "done" means.

## 4. Scope

### In Scope

1. Module business output contracts (domain-level)
2. Scenario-level acceptance suites across parent usage flows
3. Data quality and writeback consistency checks tied to business outputs
4. Operational readiness artifacts (runbook, rollback, release checklist)
5. CI gates for Phase 2 acceptance criteria

### Out of Scope

1. New module addition beyond current 6 execution modules
2. New client applications or redesign work
3. Large schema redesign unrelated to capability acceptance

## 5. Deliverables

1. Phase 2 contract catalog for business outputs per module
2. Golden scenario suite and deterministic fixtures
3. Data quality assertion suite linked to scenario outputs
4. Release readiness checklist and rollback drill evidence
5. Governance evidence updates with Phase 2 acceptance runs

## 6. Acceptance Criteria

1. Each execution module has explicit business output contract and validation gate.
2. Golden scenario suite passes in CI with deterministic pass/fail criteria.
3. Writeback/data quality assertions pass for all business scenarios.
4. Release checklist is complete with rollback procedure validated.
5. No blocking gaps remain for Phase 2 in `docs/governance/GAP-REGISTER.md`.

## 7. Workstreams

1. Contractization:
   - codify business output envelope and required fields by module
2. Scenario Harness:
   - implement parent-centric end-to-end scenario scripts
3. Data Assurance:
   - enforce scenario-to-writeback consistency checks
4. Release Readiness:
   - finalize runbook, rollback drill, and stage sign-off evidence

## 8. Risks and Controls

1. Non-deterministic live model behavior:
   - Control: fixture-based assertion boundaries + explicit tolerance rules
2. Runtime capacity jitter (`WORKER_LIMIT`):
   - Control: existing retry contracts + bounded attempts + observability checks
3. Scope creep:
   - Control: enforce out-of-scope list and phase acceptance gate

## 9. Exit Condition

Phase 2 is complete when all acceptance criteria in Section 6 pass and evidence is recorded in governance verification documents with latest UTC timestamp and trace samples.
