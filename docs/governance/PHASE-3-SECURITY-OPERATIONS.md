# Phase 3 Security Operations

## Secrets Rotation Policy

| secret_class | examples | rotation_cadence | owner |
|---|---|---|---|
| supabase service secrets | `SUPABASE_SERVICE_ROLE_KEY`, DB credentials | 30 days | engineering |
| model provider keys | Kimi / Doubao API keys | 30 days | engineering |
| ci credentials | GitHub Actions secrets | 60 days | operations |

- Rotation requirements:
  - dual-control approval for production secret changes.
  - verify post-rotation by running `bash scripts/ci/final_gate.sh`.

## Privileged Action Controls

1. Only named maintainers can execute production deploy or destructive DB commands.
2. All privileged commands must be run via auditable shell history and CI logs.
3. Prohibited:
   - local plaintext secret sharing
   - bypassing governance gates before release
4. Emergency access is time-bounded and must be revoked after incident closure.

## Access Review Cadence

| scope | cadence | required_output |
|---|---|---|
| repo write/admin | monthly | reviewer + access diff |
| supabase project roles | monthly | role assignment snapshot |
| ci secrets maintainers | monthly | approver signature |

- Any stale account must be removed within 24h of detection.

## Audit Evidence Requirements

- Mandatory evidence per release cycle:
  - secret rotation log reference
  - privileged command record (deploy, rollback, db rebuild)
  - access review output and sign-off
- Evidence storage:
  - `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
  - `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`

## Incident Security Response

1. Detect suspected key leak or unauthorized command.
2. Revoke affected keys immediately.
3. Rotate dependent credentials and redeploy services.
4. Run full verification:
   - `bash scripts/ci/final_gate.sh`
   - `bash tests/governance/test_docs_presence.sh`
5. Append security incident evidence and corrective actions to governance docs.
