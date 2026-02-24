# GAP REGISTER

| id | category | description | impact | owner | due_date | status | evidence |
|----|----------|-------------|--------|-------|----------|--------|----------|
| GAP-0001 | missing | Module contracts are now defined for orchestrator/assessment/training/dashboard, but other future business modules are still pending governance contracts. | Medium | engineering | 2026-03-10 | in_progress | governance/agent-contract/modules/ |
| GAP-0002 | reliability | Supabase edge runtime may return transient `WORKER_LIMIT` during live smoke; retry logic is centralized with exponential backoff, and CI now enforces capacity-safe governance via workflow concurrency + shared retry env defaults. | Medium | engineering | 2026-03-15 | done | .github/workflows/db-rebuild-and-chain-smoke.yml |
| GAP-0003 | tooling | Docker-dependent schema dump path has been removed; rebuild now requires direct remote `pg_dump` to official Supabase and fails fast on dump errors (no migration fallback). | Medium | engineering | 2026-03-08 | done | scripts/db/rebuild_remote.sh |
