# Phase 2 Rollback Drill Log

## Drill Metadata

| field | value |
|---|---|
| phase | Phase 2 |
| drill_id | phase2-rollback-drill-001 |
| executed_at_utc | 2026-02-27T23:39:40Z |
| owner | engineering |
| environment | linked supabase project |
| scenario | parent weekly journey + dashboard follow-up |

## Trigger Simulation

- Simulated trigger: Phase 2 live scenario fails business output contract.
- Expected action: rollback to last known good function deployment and re-verify.

## Command Evidence

1. Pre-drill validation:
   - `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` -> PASS
   - `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` -> PASS
2. Rollback command:
   - `supabase functions deploy orchestrator --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS
3. Post-rollback validation:
   - `bash scripts/ci/final_gate.sh` -> PASS
   - `bash tests/governance/test_docs_presence.sh` -> PASS
   - `bash tests/governance/test_e2e_governance.sh` -> PASS

## Outcome

| metric | target | observed |
|---|---|---|
| rollback_started_within | 10m | TBD |
| rollback_completed_within | 30m | TBD |
| phase2_gates_after_rollback | PASS | PASS (full final_gate + governance checks) |

- Drill result: completed
- Follow-up actions: none

## Sign-off

| role | approver | date_utc | status |
|---|---|---|---|
| engineering | TBD | TBD | pending |
| operations | TBD | TBD | pending |

## Execution Record: phase2-rollback-drill-001-2026-02-27T14:13:52Z

| field | value |
|---|---|
| drill_id | phase2-rollback-drill-001 |
| started_at_utc | 2026-02-27T14:13:52Z |
| dry_run | 0 |
| rollback_module | <not-set> |

### Command Results

| command | result |
|---|---|
| `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` | PASS |
| `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` | PASS |
| `supabase functions deploy <module> --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` | SKIP |
| `bash scripts/ci/final_gate.sh` | FAIL |

## Execution Record: phase2-rollback-drill-001-2026-02-27T23:32:04Z

| field | value |
|---|---|
| drill_id | phase2-rollback-drill-001 |
| started_at_utc | 2026-02-27T23:32:04Z |
| dry_run | 0 |
| rollback_module | <not-set> |

### Command Results

| command | result |
|---|---|
| `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` | PASS |
| `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` | PASS |
| `supabase functions deploy <module> --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` | SKIP |
| `bash scripts/ci/final_gate.sh` | SKIP |
| `bash tests/governance/test_docs_presence.sh` | PASS |
| `bash tests/governance/test_e2e_governance.sh` | PASS |

## Execution Record: phase2-rollback-drill-001-2026-02-27T23:39:40Z

| field | value |
|---|---|
| drill_id | phase2-rollback-drill-001 |
| started_at_utc | 2026-02-27T23:39:40Z |
| dry_run | 0 |
| rollback_module | orchestrator |

### Command Results

| command | result |
|---|---|
| `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` | PASS |
| `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` | PASS |
| `supabase functions deploy orchestrator --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` | PASS |
| `bash scripts/ci/final_gate.sh` | PASS |
| `bash tests/governance/test_docs_presence.sh` | PASS |
| `bash tests/governance/test_e2e_governance.sh` | PASS |

## Execution Record: phase2-rollback-drill-001-2026-02-28T00:23:52Z

| field | value |
|---|---|
| drill_id | phase2-rollback-drill-001 |
| started_at_utc | 2026-02-28T00:23:52Z |
| ended_at_utc | 2026-02-28T00:27:25Z |
| elapsed_seconds | 213 |
| dry_run | 0 |
| rollback_module | orchestrator |

### Command Results

| command | result |
|---|---|
| `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` | PASS |
| `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` | PASS |
| `supabase functions deploy orchestrator --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` | PASS |
| `bash scripts/ci/final_gate.sh` | SKIP |
| `bash tests/governance/test_docs_presence.sh` | PASS |
| `bash tests/governance/test_e2e_governance.sh` | PASS |

## Execution Record: phase2-rollback-drill-001-2026-02-28T00:29:09Z

| field | value |
|---|---|
| drill_id | phase2-rollback-drill-001 |
| started_at_utc | 2026-02-28T00:29:09Z |
| ended_at_utc | 2026-02-28T00:45:38Z |
| elapsed_seconds | 989 |
| dry_run | 0 |
| rollback_module | orchestrator |

### Command Results

| command | result |
|---|---|
| `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` | PASS |
| `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` | PASS |
| `supabase functions deploy orchestrator --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` | PASS |
| `bash scripts/ci/final_gate.sh` | FAIL |
