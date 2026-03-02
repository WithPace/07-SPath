# Phase 5 Role Contract Fixtures

## Scope

This document defines the fixture set consumed by both frontend repositories to verify role-aware contract compatibility before release:

- user frontend: `starpath-frontend`
- admin web: `starpath-admin-web`

## Fixture Set

Required fixtures:

1. parent done payload fixture
   - includes role-aware cards for `parent` dashboard and journey state.
2. doctor done payload fixture
   - includes role-specific summaries, risk context, and follow-up fields.
3. teacher done payload fixture
   - includes session/training context and intervention action fields.
4. org_admin done payload fixture
   - includes organization-level rollup fields and member-count metadata.
5. admin web audit fixture
   - includes admin web audit event payload for privileged action traces.
6. dashboard delta payload fixture
   - validates incremental stream card updates by role.
7. retry transport_error fixture
   - validates transient network handling and deterministic retry state mapping.

## Validation Rules

- Fixtures must preserve exact field names and required keys from backend contracts.
- Any schema drift in role payloads must fail frontend contract CI.
- Role metadata (`role`, `request_id`, module identity) must stay intact across parse/render path.
- Retry transport_error handling must preserve reason taxonomy and UI action mapping.
- Admin web audit fixture must include actor role, target entity, action, and timestamp.

## Consumption in Frontend CI

`starpath-frontend` must include:

- fixture-backed contract tests for parent/doctor/teacher/org_admin role adapters
- e2e smoke for role journey selectors
- strict gate that blocks release when fixture tests fail

`starpath-admin-web` must include:

- fixture-backed contract tests for admin web audit and privileged actions
- RBAC security checks tied to fixture-derived action matrix
- strict gate that blocks release when audit fixture compatibility fails
