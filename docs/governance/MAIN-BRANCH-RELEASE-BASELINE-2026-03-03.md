# Main Branch Release Baseline (2026-03-03)

## Summary

| item | value |
|---|---|
| release_id | `release-main-2026-03-03` |
| generated_at_utc | `2026-03-03T04:31:38Z` |
| release_operator | `叶明君` |
| integration_mode | remote-published (GitHub) |
| published_at_utc | `2026-03-03T06:39:10Z` |

## Cross-Repo Baseline Matrix

| repo | local_path | branch | commit_sha | tag |
|---|---|---|---|---|
| backend/governance | `07-SPath` | `main` | `648514084291` | `release-main-2026-03-03` |
| frontend/user ports | `starpath-frontend` | `main` | `5f12a4011738` | `release-main-2026-03-03` |
| admin web | `starpath-admin-web` | `main` | `9619f48b70a2` | `release-main-2026-03-03` |

## Remote Publish Status

| repo | origin_url | remote_main_head | release_tag_target |
|---|---|---|---|
| backend/governance | `git@github.com:WithPace/07-SPath.git` | `94c8e8935402` | `648514084291` |
| frontend/user ports | `git@github.com:WithPace/starpath-frontend.git` | `5f12a4011738` | `5f12a4011738` |
| admin web | `git@github.com:WithPace/starpath-admin-web.git` | `9619f48b70a2` | `9619f48b70a2` |

## Verification Evidence

| repo | command | result |
|---|---|---|
| backend/governance | `bash scripts/ci/release_go_live.sh` | PASS |
| frontend/user ports | `bash scripts/ci/frontend_final_gate.sh` | PASS |
| admin web | `bash scripts/ci/admin_web_final_gate.sh` | PASS |

## Traceability Notes

- Backend release record auto-update from strict go-live:
  - `docs/governance/PHASE-2-RELEASE-RECORD.md`
  - `commit_sha=005b2a8a7de2`
  - `executed_at_utc=2026-03-03T03:58:01Z`
- Governance verification timeline:
  - `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
