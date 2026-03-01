# Phase 4 Frontend Delivery Design

Version: v1  
Date: 2026-03-01  
Status: proposed

## 1. Context

Current repository (`starpath`) has completed backend execution-chain, governance gates, and go-live automation for Supabase Edge Functions.

Frontend implementation is currently out of scope in this repo and must be delivered via a separate frontend repository.

## 2. Decision (Option 1)

Adopt a dual-repo model:

- Backend/Governance repo: `starpath` (current)
- Frontend app repo: `starpath-frontend` (new)

Reason:

- Keeps backend governance and release chain stable.
- Allows frontend stack iteration without coupling backend release cadence.
- Matches current runbook statement that frontend simulator belongs to a separate repository.

## 3. Phase 4 Goal

Deliver production-ready parent frontend (MVP scope) plus complete test and release readiness plan so frontend + backend can be promoted online together.

## 4. Scope

In scope (Phase 4):

- Parent-facing web frontend for core chain: chat-casual, assessment, training-advice, training-record, dashboard.
- Supabase auth/session integration.
- SSE rendering, retry UX, and card rendering for module payloads.
- Frontend test system (unit/component/contract/e2e/perf/accessibility).
- Frontend CI gate and cross-repo go-live handshake with existing backend gates.

Out of scope (next phase):

- Doctor/teacher/institution full UI delivery.
- Native app packaging.

## 5. Harness Engineering Mapping

Apply the same stage model end-to-end:

1. `intake`: freeze Phase 4 scope, user journeys, acceptance criteria.
2. `audit`: audit existing backend contracts, identify frontend contract gaps.
3. `optimize`: define performance and UX quality budgets.
4. `fill_gap`: add missing schemas, fixtures, and retry/edge-case handling.
5. `plan`: create executable task plan with TDD steps.
6. `execute`: implement by small increments with frequent commits.
7. `verify`: run full test matrix + go-live rehearsal.
8. `report`: produce frontend release record and integrated release evidence.

## 6. Architecture

## 6.1 Frontend Repo Baseline

Recommended stack for `starpath-frontend`:

- Next.js (App Router) + TypeScript
- UI: Tailwind + component tokens aligned with `docs/06-前端交互与体验文档.md`
- State: Zustand
- API boundary: typed client for Supabase + Edge Functions
- Tests: Vitest + Testing Library + Playwright

## 6.2 Integration Boundary

Frontend calls existing backend only through stable contracts:

- `orchestrator` SSE stream framing and done/delta events
- Module done payload contracts from `docs/governance/PHASE-2-CONTRACT-CATALOG.md`
- Retry reason taxonomy and transport error contracts already gated in backend

## 6.3 Cross-Repo Release Handshake

Release can promote only when both are green:

- Backend: `bash scripts/ci/release_go_live.sh` (already strict-gated)
- Frontend: `frontend_final_gate` (new in frontend repo)

## 7. Test Strategy (Frontend + Launch Readiness)

## 7.1 Test Pyramid

1. Unit tests:
   - message parser, SSE frame parser, retry-state reducer, card mappers.
2. Component tests:
   - chat timeline, input composer, dashboard cards, training record form.
3. Contract tests:
   - fixtures validate done/delta payloads against backend contract catalog.
4. E2E tests:
   - parent weekly journey and dashboard follow-up happy path.
   - network interruption, retry, timeout, and idempotent re-submit behavior.
5. Non-functional:
   - Lighthouse performance thresholds.
   - accessibility smoke (keyboard navigation + core aria assertions).

## 7.2 Go-Live Gates

Frontend release gate must include:

- lint/typecheck/build pass
- unit/component/contract tests pass
- e2e pass on staging-like environment
- API base URL and Supabase env preflight pass
- release evidence markdown updated

Backend + frontend combined go-live requires:

- backend strict go-live pass
- frontend strict final gate pass
- manual sign-off snapshot for product/engineering/operations

## 8. Deliverables

Backend repo (`starpath`) deliverables:

- Phase 4 planning docs and governance integration points
- cross-repo release handshake checklist

Frontend repo (`starpath-frontend`) deliverables:

- production parent frontend MVP
- frontend test harness and CI gate
- frontend release runbook and release record

## 9. Risks and Controls

1. Contract drift between backend and frontend:
   - control: contract fixtures + CI contract tests.
2. Network instability causing flaky e2e:
   - control: deterministic retry policy + resilient test utilities.
3. UI completion without launch evidence:
   - control: enforce release record update in frontend gate.

## 10. Acceptance

Phase 4 is complete only when:

- frontend MVP scope is delivered in `starpath-frontend`
- frontend full test matrix is green
- backend strict gate remains green
- integrated release evidence is present for both repos
- combined sign-off is approved
