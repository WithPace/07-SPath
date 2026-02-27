# Phase 3 Operations Runbook

## Incident Severity Matrix

| severity | definition | examples |
|---|---|---|
| sev1 | core chain unavailable or unsafe data writes | orchestrator ingress outage, repeated failed writeback |
| sev2 | business degradation with viable workaround | module failure spike, dashboard cards missing |
| sev3 | limited impact, no immediate business block | elevated latency, intermittent retries |

## Incident Response Workflow

1. Detect:
   - alert from SLO thresholds or failed live smoke.
2. Triage:
   - identify scope (module/function/request_id cohort).
3. Contain:
   - pause deployments and disable risky changes.
4. Mitigate:
   - apply rollback or bounded hotfix.
5. Verify:
   - run `bash scripts/ci/final_gate.sh`.
6. Close:
   - update evidence logs and postmortem action items.

## On-call Escalation

| phase | primary | escalation_path | max_wait |
|---|---|---|---|
| detection | operations on-call | engineering on-call | 10m |
| mitigation | engineering on-call | tech lead | 20m |
| sev1 business comms | product operations | executive owner | 30m |

- Escalation rule:
  - unresolved sev1 after 20m automatically escalates to tech lead.

## Rollback Procedure

1. Determine rollback trigger:
   - any sev1 condition or failed release gate.
2. Redeploy last known good function set.
3. Re-run:
   - `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh`
   - `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh`
   - `bash scripts/ci/final_gate.sh`
4. Record command outcomes and request IDs in verification docs.

## Drill Evidence

| drill_type | frequency | required_evidence |
|---|---|---|
| incident drill | monthly | command logs + elapsed time + owner sign-off |
| rollback drill | monthly | rollback commands + gate pass evidence |
| paging drill | quarterly | escalation timestamp trail |

- Evidence references:
  - `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
  - `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
  - `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md`
