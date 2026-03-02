# Phase 4 Frontend Contract Fixtures

## Scope

This document defines the fixture set required by the separate frontend repository (`starpath-frontend`) to validate compatibility with backend execution-chain contracts before release.

Reference baseline:

- `docs/governance/PHASE-2-CONTRACT-CATALOG.md`
- retry and SSE contracts currently enforced in backend CI gates

## Fixture Set

1. `chat-casual` done payload fixture
   - includes: `request_id`, `model_used`
2. `assessment` done payload fixture
   - includes: `request_id`, `model_used`, `assessment_id`
3. `training` done payload fixture
   - includes: `request_id`, `model_used`, `training_plan_id`
4. `training-advice` done payload fixture
   - includes: `request_id`, `model_used`, `training_plan_id`
5. `training-record` done payload fixture
   - includes: `request_id`, `model_used`, `training_session_id`
6. `dashboard` delta payload fixture
   - includes: `cards` array and card metadata
7. `dashboard` done payload fixture
   - includes: `request_id`, `model_used`, `role`, `card_count`
8. retry/transport fixture
   - includes: `reason=transport_error`, `exit_code=6|28|35`
   - retry transport_error fixture must be consumed by frontend retry-state contract tests

## Validation Rules

- Any fixture must preserve exact field names and required field presence from the backend contract catalog.
- Frontend contract tests must fail on:
  - missing required fields
  - wrong data type for required fields
  - absent dashboard `cards` payload in delta stream
- Retry fixture tests must map `transport_error` to deterministic frontend retry UI state.

## Consumption in Frontend CI

Frontend repository (`starpath-frontend`) must include:

- fixture-driven contract tests in CI (`contract` layer)
- gate script that blocks release when fixture compatibility fails
- evidence entry in frontend release record referencing fixture test run

Recommended gate sequence in frontend CI:

1. typecheck/lint/build
2. unit/component tests
3. fixture-driven contract tests (this fixture set)
4. e2e tests
5. release evidence update
