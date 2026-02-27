# GAP REGISTER

| id | category | description | impact | owner | due_date | status | evidence |
|----|----------|-------------|--------|-------|----------|--------|----------|
| GAP-0001 | missing | Module contracts are defined for all active execution-chain modules (`orchestrator`, `assessment`, `training`, `dashboard`, `chat-casual`, `training-advice`, `training-record`); new modules must be added to contract required list before release. | Medium | engineering | 2026-03-10 | done | governance/agent-contract/modules/ |
| GAP-0002 | reliability | Supabase edge runtime may return transient `WORKER_LIMIT` during live smoke; retry logic is centralized with exponential backoff, and CI now enforces capacity-safe governance via workflow concurrency + shared retry env defaults. | Medium | engineering | 2026-03-15 | done | .github/workflows/db-rebuild-and-chain-smoke.yml |
| GAP-0003 | tooling | Docker-dependent schema dump path has been removed; rebuild now requires direct remote `pg_dump` to official Supabase and fails fast on dump errors (no migration fallback). | Medium | engineering | 2026-03-08 | done | scripts/db/rebuild_remote.sh |
| GAP-0004 | governance | Phase 2 release-readiness artifacts were previously undefined; release checklist and rollback drill evidence are now required and tracked by governance gate. | Medium | engineering | 2026-03-20 | done | tests/governance/test_phase2_release_artifacts.sh |
| GAP-0005 | operations | Phase 3 operational governance artifacts were previously undefined; SLO/runbook/security/cost/release automation baselines are now required and tracked by governance gates. | Medium | engineering | 2026-03-25 | done | tests/governance/test_phase3_slo_runbook_presence.sh |
