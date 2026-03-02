# Phase 5 Full Ports + Admin Web Delivery Checklist

## Scope

- backend/governance repository: `starpath` (this repo)
- user-facing frontend repository: `starpath-frontend`
- admin management frontend repository: `starpath-admin-web`
- phase scope: full user ports + management web with governance-first release control

## Port Matrix

| domain | role/port | primary scope |
|---|---|---|
| user app | parent | chat, assessment, training-advice, training-record, dashboard |
| user app | doctor | review, follow-up, collaboration insights |
| user app | teacher | training feedback, schedule/context insights |
| user app | org_admin | org members, permissions, org analytics |
| admin web | super_admin/operator/cs_agent/analyst | operations, audit, content, ai ops, revenue/user management |

## Entry Criteria

- [ ] Phase 4 parent-scope baseline remains green.
- [ ] Phase 5 role contract catalog and fixture spec are documented.
- [ ] backend role/RLS contract tests exist for all role paths.
- [ ] `starpath-frontend` bootstrap complete (`lint`, `typecheck`, `build`, `test`).
- [ ] `starpath-admin-web` bootstrap complete (`lint`, `typecheck`, `build`, `test`).

## Exit Criteria

- [ ] backend strict go-live passes (`bash scripts/ci/release_go_live.sh`).
- [ ] user frontend strict gate passes (`bash scripts/ci/frontend_final_gate.sh`).
- [ ] admin web strict gate passes (`bash scripts/ci/admin_web_final_gate.sh`).
- [ ] Phase 5 release record updated with backend/frontend/admin commit SHAs and UTC evidence.
- [ ] combined sign-off rows all marked `approved`.

## Cross-Repo Sign-off

| role | approver | date_utc | status |
|---|---|---|---|
| backend engineering | TBD | TBD | pending |
| frontend engineering | TBD | TBD | pending |
| admin web engineering | TBD | TBD | pending |
| product | TBD | TBD | pending |
| operations | TBD | TBD | pending |
| security | TBD | TBD | pending |

## Risks and Controls

| risk | control |
|---|---|
| backend/frontend/admin contract drift | fixture-backed contract tests in both frontend repos + backend catalog gates |
| multi-repo release mismatch | strict cross-repo release record handshake and command evidence required |
| privilege escalation in admin flows | deny-by-default RBAC + audit log enforcement + security sign-off gate |
