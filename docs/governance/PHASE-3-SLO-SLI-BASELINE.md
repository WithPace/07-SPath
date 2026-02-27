# Phase 3 SLO/SLI Baseline

## Scope

This baseline applies to the current execution chain:
- `orchestrator`
- `chat-casual`
- `assessment`
- `training`
- `training-advice`
- `training-record`
- `dashboard`

All metrics are measured in UTC rolling windows and reviewed weekly.

## SLO Targets

| service_slice | slo_metric | target |
|---|---|---|
| orchestrator ingress | successful `done` event rate | >= 99.5% / 30d |
| module execution | writeback success rate (`operation_logs.final_status=success`) | >= 99.0% / 30d |
| parent weekly journey | full-chain completion rate | >= 98.0% / 30d |
| critical API latency | p95 end-to-end response time | <= 8s / 24h |

## SLI Measurements

1. Done-event success rate:
   - source: orchestrator live smoke + operation logs
   - formula: `done_success / total_requests`
2. Writeback success rate:
   - source: `operation_logs`
   - formula: `success_logs / total_logs`
3. Weekly journey completion:
   - source: `tests/e2e/test_phase2_parent_weekly_journey_live.sh`
   - formula: `pass_runs / total_runs`
4. Latency:
   - source: live smoke timing traces
   - formula: p95 of request duration in rolling 24h bucket

## Alert Thresholds

| severity | trigger | action |
|---|---|---|
| sev1 | ingress availability < 98.0% for 15m | stop rollout + rollback |
| sev2 | writeback success < 99.0% for 60m | incident channel + mitigation |
| sev2 | weekly journey pass rate < 95.0% in day | freeze deployments |
| sev3 | p95 latency > 8s for 30m | investigate capacity and provider |

## Ownership

| area | owner | backup | review_cadence |
|---|---|---|---|
| reliability metrics | engineering | operations | weekly |
| incident triage | operations | engineering | on-demand |
| governance evidence sync | engineering | product operations | per release |

## Review and Evidence

- Required periodic evidence:
  - `bash scripts/ci/final_gate.sh`
  - `bash tests/governance/test_docs_presence.sh`
  - `bash tests/governance/test_e2e_governance.sh`
- Latest run summary must be appended to governance verification docs with UTC timestamp.
