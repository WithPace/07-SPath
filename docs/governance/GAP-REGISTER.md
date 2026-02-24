# GAP REGISTER

| id | category | description | impact | owner | due_date | status | evidence |
|----|----------|-------------|--------|-------|----------|--------|----------|
| GAP-0001 | missing | Module contracts are now defined for orchestrator/assessment/training/dashboard, but other future business modules are still pending governance contracts. | Medium | engineering | 2026-03-10 | in_progress | governance/agent-contract/modules/ |
| GAP-0002 | reliability | Supabase edge runtime may return transient `WORKER_LIMIT` during live smoke; retry logic is now centralized with exponential backoff across all orchestrator live e2e scripts, while infra-side capacity mitigation is still pending. | Medium | engineering | 2026-03-15 | in_progress | tests/e2e/_shared/orchestrator_retry.sh |
| GAP-0003 | tooling | Docker-dependent schema dump path has been removed; rebuild and schema dump now prefer direct remote `pg_dump` to official Supabase, with migration snapshot fallback only when DB connection credentials are unavailable. | Medium | engineering | 2026-03-08 | in_progress | scripts/db/rebuild_remote.sh |
