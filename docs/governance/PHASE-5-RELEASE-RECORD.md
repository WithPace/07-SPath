# Phase 5 Full Ports + Admin Web Release Record

## Release Identity

| field | value |
|---|---|
| phase | Phase 5 (Full Ports + Admin Web) |
| backend_repo | starpath |
| frontend_repo | starpath-frontend |
| admin_web_repo | starpath-admin-web |
| backend_commit_sha | b6defa5 |
| frontend_commit_sha | 5f12a40 |
| admin_web_commit_sha | 9619f48 |
| executed_at_utc | 2026-03-02T08:44:27Z |
| release_operator | 叶明君 |

## Verification Evidence

| command | result |
|---|---|
| `bash scripts/ci/release_go_live.sh` | PASS |
| `bash ../starpath-frontend/scripts/ci/frontend_final_gate.sh` | PASS |
| `bash ../starpath-admin-web/scripts/ci/admin_web_final_gate.sh` | PASS |
| `bash tests/governance/test_phase5_governance_presence.sh` | PASS |
| `bash tests/governance/test_docs_presence.sh` | PASS |

## Cross-Repo Handshake

| checkpoint | status | note |
|---|---|---|
| backend strict go-live green | done | release_go_live completed with full gate chain |
| frontend strict gate green | done | starpath-frontend frontend_final_gate passed |
| admin web strict gate green | done | starpath-admin-web admin_web_final_gate passed |
| integrated sign-off complete | done | all required sign-off rows approved |

## Rollback References

- backend rollback drill scripts:
  - `scripts/ops/run_phase2_rollback_drill.sh`
  - `scripts/ops/run_phase3_rollback_drill.sh`
- frontend rollback runbook:
  - `starpath-frontend/docs/governance/FRONTEND-ROLLBACK-RUNBOOK.md`
- admin web rollback runbook:
  - `starpath-admin-web/docs/governance/ADMIN-WEB-ROLLBACK-RUNBOOK.md`
