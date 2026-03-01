# Phase 2 Release Record

## Release Identity

| field | value |
|---|---|
| phase | Phase 2 (Business Capability Delivery) |
| project_ref | innaguwdmdfugrbcoxng |
| commit_sha | 6de961afae90 |
| executed_at_utc | 2026-03-01T03:25:18Z |
| release_operator | engineering |

## Verification Evidence

| command | result |
|---|---|
| `bash scripts/ci/release_go_live.sh` | PASS |
| `bash scripts/ci/final_gate.sh` | PASS |
| `bash tests/governance/test_docs_presence.sh` | PASS |
| `bash tests/governance/test_e2e_governance.sh` | PASS |

Live smoke sample request IDs from this release run:
- `assessment_request_id=fdbfda12-f93a-4194-991f-f2b4bd88bf45`
- `training_advice_request_id=9246255b-b739-4dde-bed3-1640058d08f5`
- `training_request_id=ed803bb4-6097-4a75-b22e-066958284a42`
- `training_record_request_id=70fe9d52-8971-42b3-8f72-dbac46d1ef5d`
- `dashboard_request_id=e2706b4e-a186-40e4-9d0b-f875c0efb3b4`

## Sign-off Snapshot

| role | approver | status |
|---|---|---|
| engineering | engineering-oncall | approved |
| product | product-owner | pending |
| operations | operations-oncall | pending |

## Rollback References

- Phase 2 rollback drill:
  - `scripts/ops/run_phase2_rollback_drill.sh`
  - `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md`
- Phase 3 rollback drill:
  - `scripts/ops/run_phase3_rollback_drill.sh`
  - `docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md`
- Incident drill:
  - `scripts/ops/run_phase3_incident_drill.sh`
  - `docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md`
