# Phase 4 Frontend Delivery Checklist

## Scope

- frontend repository: `starpath-frontend` (separate repo)
- role scope: parent-side MVP (chat, assessment, training-advice, training-record, dashboard)
- backend/governance repository: `starpath` (this repo)

## Entry Criteria

- [x] frontend repo bootstrap complete (`lint`, `typecheck`, `build`, `test` commands available)
- [x] orchestrator SSE contract fixtures aligned with `docs/governance/PHASE-2-CONTRACT-CATALOG.md`
- [x] frontend contract tests pass (`contract` layer)
- [x] frontend e2e parent journeys pass on staging-like environment
- [x] backend strict gates still green (`bash scripts/ci/final_gate.sh`)

## Exit Criteria

- [x] frontend strict gate passes (`bash scripts/ci/frontend_final_gate.sh`)
- [x] backend strict go-live passes (`bash scripts/ci/release_go_live.sh`)
- [x] frontend release record updated with latest frontend/backend commit ids
- [x] integrated release evidence updated in backend verification ledger

## Cross-Repo Sign-off

| role | approver | date_utc | status |
|---|---|---|---|
| frontend engineering | 叶明君 | 2026-03-02T05:13:42Z | approved |
| backend engineering | 叶明君 | 2026-03-02T05:13:42Z | approved |
| product | 叶明君 | 2026-03-02T05:30:32Z | approved |
| operations | 叶明君 | 2026-03-02T05:30:32Z | approved |

## Risks and Controls

| risk | control |
|---|---|
| backend/frontend contract drift | enforce fixture-backed contract tests in frontend CI |
| frontend e2e instability | retry-safe e2e helpers + deterministic selectors |
| release evidence gaps | release record update is required before sign-off completion |
