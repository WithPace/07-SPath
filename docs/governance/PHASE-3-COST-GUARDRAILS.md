# Phase 3 Cost Guardrails

## Budget Thresholds

| scope | monthly_budget_usd | warning | hard_stop |
|---|---|---|---|
| model inference | 1200 | 80% | 100% |
| supabase compute + db | 900 | 85% | 100% |
| total platform runtime | 2300 | 85% | 100% |

- Warning requires mitigation plan in 1 business day.
- Hard-stop requires release freeze and explicit approval for override.

## Spend Anomaly Response

1. Trigger:
   - day-over-day spend increase > 30%, or
   - retry-driven request volume spike > 2x baseline.
2. Immediate actions:
   - pause non-critical deploys.
   - reduce noisy traffic and disable experimental paths.
3. Recovery actions:
   - tune retry settings and traffic policy.
   - validate with `bash scripts/ci/final_gate.sh`.
4. Evidence:
   - append anomaly timeline and mitigation summary to governance verification docs.

## Capacity Ceilings

| control | ceiling | guard |
|---|---|---|
| retry attempts | `ORCH_MAX_ATTEMPTS <= 6` | enforced by contract tests |
| retry base delay | `ORCH_RETRY_BASE_DELAY_SECONDS <= 5` | enforced by contract tests |
| concurrent chain smoke in CI | single active run per workflow | workflow concurrency |
| release-time live checks | bounded smoke set only | release checklist gate |

## CI Enforcement

- Cost/capacity protection gates:
  - `bash tests/e2e/test_live_smoke_retry_limits_contract.sh`
  - `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh`
  - `bash tests/governance/test_phase3_cost_guardrails_presence.sh`
- Any failing cost guardrail gate blocks release readiness.

## Review Cadence

| review_item | cadence | owner |
|---|---|---|
| budget vs actual | weekly | operations |
| anomaly trend | weekly | engineering |
| capacity limit assumptions | bi-weekly | engineering |
| guardrail policy updates | per release | engineering + operations |
