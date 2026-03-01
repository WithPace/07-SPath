# Phase 2 Release Record

## Release Identity

| field | value |
|---|---|
| phase | Phase 2 (Business Capability Delivery) |
| project_ref | innaguwdmdfugrbcoxng |
| commit_sha | f74f20e7f124 |
| executed_at_utc | 2026-03-01T08:05:50Z |
| release_operator | 叶明君 |

## Verification Evidence

| command | result |
|---|---|
| `REQUIRE_FULL_SIGNOFF=1 bash scripts/ci/release_go_live.sh` | PASS |
| `bash scripts/ci/final_gate.sh` | PASS |
| `bash tests/governance/test_docs_presence.sh` | PASS |
| `bash tests/governance/test_e2e_governance.sh` | PASS |

Live smoke sample request IDs from this release run:
- `assessment_request_id=a115e275-2a20-4a92-90b6-f96926a455d7`
- `training_advice_request_id=7070cf15-c8c5-448c-ab68-07e8cda0e223`
- `training_request_id=50a33b31-15c3-4312-b986-6c22318639f0`
- `training_record_request_id=cec316ac-d594-4903-b572-adeb1344d68a`
- `dashboard_request_id=5e033164-cf4e-4f03-8c73-da8d643d3d0d`

## Sign-off Snapshot

| role | approver | status |
|---|---|---|
| engineering | engineering-oncall | approved |
| product | 叶明君 | approved |
| operations | 叶明君 | approved |

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
