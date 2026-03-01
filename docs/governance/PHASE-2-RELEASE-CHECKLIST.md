# Phase 2 Release Checklist

## Release Metadata

| field | value |
|---|---|
| phase | Phase 2 (Business Capability Delivery) |
| environment | Supabase linked project (`innaguwdmdfugrbcoxng`) |
| release_owner | engineering |
| planned_window_utc | 2026-02-28T15:45:25Z (verification window) |
| status | engineering_approved_pending_product_ops |

## Entry Criteria

- [x] `bash tests/functions/test_phase2_contract_catalog_presence.sh` passes.
- [x] `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` passes.
- [x] `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` passes.
- [x] `bash tests/db/test_phase2_scenario_writeback_consistency.sh` passes.
- [x] `bash tests/functions/test_phase2_business_output_contract.sh` passes.
- [x] `bash tests/governance/test_phase2_release_artifacts.sh` passes.
- [x] `bash scripts/ci/final_gate.sh` passes.
- [x] `bash tests/governance/test_docs_presence.sh` passes.
- [x] `bash tests/governance/test_e2e_governance.sh` passes.

## Exit Criteria

- [x] Governance evidence updated in:
  - `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
  - `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- [x] Latest UTC verification timestamp recorded.
- [x] Phase 2 scenario request IDs captured for traceability.
- [x] `docs/governance/GAP-REGISTER.md` has no blocking Phase 2 gap.

## Rollback Trigger

- [ ] Any Phase 2 release gate fails after deployment.
- [ ] Live smoke detects done-event payload contract regression.
- [ ] Writeback consistency checks fail on required domain tables.
- [ ] Customer-impacting errors exceed agreed threshold.

## Rollback Plan

1. Identify failing module/function and last known good deployment revision.
2. Execute rollback drill script:
   - `DRY_RUN=0 ROLLBACK_MODULE=<module> bash scripts/ops/run_phase2_rollback_drill.sh`
3. If network instability blocks `final_gate`, run controlled fallback:
   - `DRY_RUN=0 ROLLBACK_MODULE=<module> ROLLBACK_DRILL_RUN_FINAL_GATE=0 bash scripts/ops/run_phase2_rollback_drill.sh`
4. Record rollback evidence in `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md`.

## Sign-off

| role | approver | date_utc | status |
|---|---|---|---|
| engineering | engineering-oncall | 2026-03-01T03:25:18Z | approved |
| product | TBD | TBD | pending |
| operations | TBD | TBD | pending |

## Pending Sign-off Controls

| role | blocker | target_approval_utc | escalation_after_utc |
|---|---|---|---|
| product | Product release window confirmation pending | 2026-03-02T02:00:00Z | 2026-03-02T08:00:00Z |
| operations | Operations deployment shift handover pending | 2026-03-02T02:30:00Z | 2026-03-02T08:30:00Z |
