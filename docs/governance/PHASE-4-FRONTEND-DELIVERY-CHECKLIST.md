# Phase 4 Frontend Delivery Checklist

## Scope

- frontend repository: `starpath-frontend` (separate repo)
- role scope: parent-side MVP (chat, assessment, training-advice, training-record, dashboard)
- backend/governance repository: `starpath` (this repo)

## Entry Criteria

- [ ] frontend repo bootstrap complete (`lint`, `typecheck`, `build`, `test` commands available)
- [ ] orchestrator SSE contract fixtures aligned with `docs/governance/PHASE-2-CONTRACT-CATALOG.md`
- [ ] frontend contract tests pass (`contract` layer)
- [ ] frontend e2e parent journeys pass on staging-like environment
- [ ] backend strict gates still green (`bash scripts/ci/final_gate.sh`)

## Exit Criteria

- [ ] frontend strict gate passes (`bash scripts/ci/frontend_final_gate.sh`)
- [ ] backend strict go-live passes (`bash scripts/ci/release_go_live.sh`)
- [ ] frontend release record updated with latest frontend/backend commit ids
- [ ] integrated release evidence updated in backend verification ledger

## Cross-Repo Sign-off

| role | approver | date_utc | status |
|---|---|---|---|
| frontend engineering | TBD | TBD | pending |
| backend engineering | TBD | TBD | pending |
| product | TBD | TBD | pending |
| operations | TBD | TBD | pending |

## Risks and Controls

| risk | control |
|---|---|
| backend/frontend contract drift | enforce fixture-backed contract tests in frontend CI |
| frontend e2e instability | retry-safe e2e helpers + deterministic selectors |
| release evidence gaps | release record update is required before sign-off completion |
