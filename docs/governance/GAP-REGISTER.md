# GAP REGISTER

| id | category | description | impact | owner | due_date | status | evidence |
|----|----------|-------------|--------|-------|----------|--------|----------|
| GAP-0001 | missing | Module contracts are now defined for orchestrator/assessment/training/dashboard, but other future business modules are still pending governance contracts. | Medium | engineering | 2026-03-10 | in_progress | governance/agent-contract/modules/ |
| GAP-0002 | reliability | Supabase edge runtime may return transient `WORKER_LIMIT` during live smoke and still needs capacity-side mitigation; test now retries but infra risk remains. | Medium | engineering | 2026-03-15 | in_progress | tests/e2e/test_orchestrator_chat_casual_live.sh |
| GAP-0003 | tooling | `supabase db dump --linked` requires Docker locally; current flow uses migration-file fallback instead of true remote schema dump. | Medium | engineering | 2026-03-08 | in_progress | scripts/db/rebuild_remote.sh |
