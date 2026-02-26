# Phase 2 Business Capability Delivery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver business-capability-level acceptance on top of completed governance foundations.

**Architecture:** Implement Phase 2 through four workstreams: business output contracts, scenario harness, data assurance checks, and release readiness. Each increment follows TDD with contract/smoke verification and governance evidence updates.

**Tech Stack:** Bash, Deno TypeScript (existing functions), Supabase SQL, governance contract scripts, CI gates.

### Task 1: Establish Phase 2 Contract Catalog

**Files:**
- Create: `docs/governance/PHASE-2-CONTRACT-CATALOG.md`
- Create: `tests/functions/test_phase2_contract_catalog_presence.sh`

**Step 1: Write failing test**

Run:
- `bash tests/functions/test_phase2_contract_catalog_presence.sh`

Expected:
- FAIL before file and clauses exist.

**Step 2: Implement minimal catalog**

- Define per-module required business output fields.
- Include acceptance mapping to scenario scripts and writeback assertions.

**Step 3: Verify**

Run:
- `bash tests/functions/test_phase2_contract_catalog_presence.sh`

Expected:
- PASS.

### Task 2: Add Golden Scenario Harness

**Files:**
- Create: `tests/e2e/test_phase2_parent_weekly_journey_live.sh`
- Create: `tests/e2e/test_phase2_parent_dashboard_followup_live.sh`
- Modify: `tests/e2e/_shared/live_smoke_lib.sh`

**Step 1: Write failing tests**

Run:
- `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh`
- `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh`

Expected:
- FAIL before scripts and assertions are complete.

**Step 2: Implement minimal scenario assertions**

- Validate expected module sequence and done events.
- Validate request_id lineage and scenario-required payload fields.

**Step 3: Verify**

Run:
- both scenario scripts above

Expected:
- PASS.

### Task 3: Add Data Assurance Gates for Phase 2 Scenarios

**Files:**
- Create: `tests/db/test_phase2_scenario_writeback_consistency.sh`
- Create: `tests/functions/test_phase2_business_output_contract.sh`

**Step 1: Write failing tests**

Run:
- `bash tests/db/test_phase2_scenario_writeback_consistency.sh`
- `bash tests/functions/test_phase2_business_output_contract.sh`

Expected:
- FAIL before assertions and contract checks are complete.

**Step 2: Implement minimal checks**

- Assert scenario-linked rows and metadata in `operation_logs`, `chat_messages`, and module domain tables.
- Assert business output contract presence for all in-scope modules.

**Step 3: Verify**

Run:
- both tests above

Expected:
- PASS.

### Task 4: Release Readiness and Rollback Drill

**Files:**
- Create: `docs/governance/PHASE-2-RELEASE-CHECKLIST.md`
- Create: `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md`
- Create: `tests/governance/test_phase2_release_artifacts.sh`

**Step 1: Write failing test**

Run:
- `bash tests/governance/test_phase2_release_artifacts.sh`

Expected:
- FAIL before artifacts are defined.

**Step 2: Implement minimal artifacts**

- Checklist includes entry/exit criteria, rollback trigger, and sign-off fields.
- Drill log records command evidence and outcome.

**Step 3: Verify**

Run:
- `bash tests/governance/test_phase2_release_artifacts.sh`

Expected:
- PASS.

### Task 5: Integrate Phase 2 into Final Gate and Governance Evidence

**Files:**
- Modify: `scripts/ci/final_gate.sh`
- Modify: `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- Modify: `docs/governance/GAP-REGISTER.md`

**Step 1: Integrate tests**

- Add Phase 2 tests to final-gate sweep through existing wildcard conventions.

**Step 2: Verify full suite**

Run:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`

Expected:
- PASS.

**Step 3: Evidence and closure**

- Append command evidence and latest UTC timestamp.
- Add phase completion samples and mark any phase-specific gaps done.

### Task 6: Completion Commit Strategy

Commit Phase 2 in small increments per task:

```bash
git add <task files>
git commit -m "<scope>: <phase2 increment>"
```

Final closeout commit should summarize phase completion evidence and acceptance pass.
