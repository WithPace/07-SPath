# Phase 5 Full Ports + Admin Web Delivery Design

Version: v1  
Date: 2026-03-01  
Status: proposed

## 1. Context

Current state after Phase 3 and Phase 4 planning:

- Backend execution-chain and governance gates are established in `starpath`.
- Phase 4 defines parent MVP frontend delivery in separate frontend repository.
- Core functional contracts are currently parent-first; role-complete delivery is not finished.
- Admin management web has design documentation but no production implementation/release gate chain.

Phase 5 must shift from parent MVP to full multi-role product delivery with governance-first enforcement.

## 2. Phase 5 Goal

Deliver production-ready full client ports and management web with auditable Harness Engineering workflow:

- User ports: `parent`, `doctor`, `teacher`, `org_admin`
- Operations management web: `super_admin`, `operator`, `cs_agent`, `analyst`
- Cross-repo launch readiness where backend + user ports + admin web gates all pass before promotion.

## 3. Scope

In scope (Phase 5):

- Full role-based frontend delivery for all user ports.
- Management web delivery for运营、客服、分析、内容、机构管理 workflows.
- Backend role contract expansion (request payload, cards payload, permission boundary, RLS acceptance).
- Unified test matrix (unit/component/contract/e2e/security/perf) across repos.
- Unified release handshake and evidence chain under governance docs.

Out of scope (Phase 5):

- Native iOS/Android packaging.
- Offline-first sync architecture.
- New AI module families beyond existing seven module contracts.

## 4. Options Considered

### Option A: Single user-facing app + admin web in one frontend repository

Pros:
- Lowest initial setup overhead.
- Shared component library with minimal repo operations burden.

Cons:
- Weak isolation between high-risk admin surface and user traffic surface.
- Higher blast radius for CI failure and deployment rollback.

### Option B (Selected): Dual frontend repositories with strict boundary

Topology:
- `starpath` (backend + governance)
- `starpath-frontend` (parent/doctor/teacher/org_admin user ports)
- `starpath-admin-web` (operations/admin management web)

Pros:
- Clear security and release isolation.
- Allows independent cadence for high-change admin workflows.
- Stronger Harness governance evidence per boundary.

Cons:
- More release coordination and artifact synchronization work.

### Option C: Frontend monorepo workspace (`apps/portal`, `apps/admin`)

Pros:
- Shared tooling and packages with explicit app separation.
- Easier cross-app refactor than dual-repo.

Cons:
- Migration and tooling complexity higher than Option B now.
- Still couples app CI/runtime risks in one repo.

## 5. Harness Engineering Mapping

Phase 5 follows mandatory stages end-to-end:

1. `intake`: freeze role matrix, user journeys, acceptance criteria, release owners.
2. `audit`: map missing contracts and gaps (role payload, permission, missing screens, missing runbooks).
3. `optimize`: define SLO/SLI + latency budget + retry budgets per role workflow.
4. `fill_gap`: add missing contracts, fixtures, RLS tests, admin audit coverage.
5. `plan`: produce executable task plan and commit strategy.
6. `execute`: incremental implementation with small commits and deterministic gates.
7. `verify`: run strict gates for three repos + live rehearsal.
8. `report`: attach evidence to governance release records and close gap register entries.

## 6. Architecture

## 6.1 Delivery Boundary

- Backend and governance remain in `starpath`.
- User ports implemented in `starpath-frontend`.
- Management web implemented in `starpath-admin-web`.
- Shared contract fixtures published from backend governance docs and consumed by both frontend repos.

## 6.2 Port Matrix

1. Parent port:
   - core chain: chat, assessment, training-advice, training-record, dashboard.
2. Doctor port:
   - child overview, risk summaries, follow-up advice, care-team collaboration views.
3. Teacher port:
   - training session insights, class schedule context, intervention tracking views.
4. Org admin port:
   - institution roster, member permissions, org-level analytics and audit summary.
5. Admin web:
   - user management, subscription/revenue, content/prompt governance, AI ops monitoring, incident/audit console.

## 6.3 Backend Contract Evolution

Required contract additions in backend:

- `dashboard` role expansion from parent-only to role-matrix payload contracts.
- Role-aware orchestration metadata and module output schemas.
- Role contract fixture pack for frontend CI.
- RLS and authorization acceptance suite for all roles.
- Admin API boundary and audit log completion checks.

## 6.4 Security and Governance Boundary

- User-facing and admin-facing auth flows must be isolated.
- Admin operations require strict RBAC and full audit logging.
- Any schema or policy drift must fail governance contract tests before deploy.
- Promotion blocked unless all required sign-off roles are complete.

## 7. Test and Release Strategy

## 7.1 Test Matrix

1. Unit:
   - parser, state reducers, role-policy helpers, adapter mappers.
2. Component:
   - role-specific dashboards, cards, form/state behavior.
3. Contract:
   - role payload fixtures against backend catalog and retry taxonomy.
4. E2E:
   - parent weekly journey
   - doctor follow-up review journey
   - teacher training feedback journey
   - org admin member-management journey
   - admin web operations journey
5. Security:
   - auth boundary tests, RLS role matrix, privileged action denial checks.
6. Non-functional:
   - performance budget, accessibility smoke, CI stability constraints.

## 7.2 Release Handshake

Combined go-live promotion requires:

1. Backend strict gate pass (`scripts/ci/release_go_live.sh`).
2. User ports strict gate pass (`starpath-frontend/scripts/ci/frontend_final_gate.sh`).
3. Admin web strict gate pass (`starpath-admin-web/scripts/ci/admin_web_final_gate.sh`).
4. Governance records updated with commit SHA, UTC timestamp, gate outputs, and rollback references.
5. Manual sign-off completion for product/engineering/operations/security.

## 8. Gap Audit Baseline (Initial)

Identified gaps to be filled during Phase 5:

1. Frontend implementation repo(s) for multi-role and admin are not delivered yet.
2. Backend `dashboard` role handling is parent-only and must expand.
3. Existing e2e suites are parent-dominant; multi-role journeys missing.
4. Admin web release gate and evidence chain not established.
5. Cross-repo release handshake currently covers backend + parent scope only.

## 9. Deliverables

Backend repo (`starpath`):

- Phase 5 governance checklist and release record.
- Role contract catalog and fixture definitions.
- Role/RLS/admin boundary automated checks.
- Phase 5 evidence updates in verification ledgers.

User frontend repo (`starpath-frontend`):

- Parent + doctor + teacher + org admin production web.
- Contract/e2e/perf/accessibility test harness.
- Frontend release record and rollback runbook.

Admin web repo (`starpath-admin-web`):

- Operations management web implementation.
- Admin security/audit-focused test harness.
- Admin release record and rollback runbook.

## 10. Acceptance

Phase 5 is complete only when:

1. All user ports and admin web are delivered and validated in strict gates.
2. Backend role contracts, RLS, and admin boundaries are fully verified.
3. Cross-repo launch handshake evidence is complete and auditable.
4. Gap register has no open `missing`/`conflict` high-severity Phase 5 items.
5. Final sign-off is approved with explicit UTC timestamp and release identifiers.
