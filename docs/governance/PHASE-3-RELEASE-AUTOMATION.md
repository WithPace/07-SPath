# Phase 3 Release Automation

## Canary Policy

1. Stage releases by module groups:
   - group A: `orchestrator`, `chat-casual`
   - group B: `assessment`, `training`, `training-advice`
   - group C: `training-record`, `dashboard`
2. Promote to next group only if:
   - no sev1/sev2 alert in canary window,
   - all release gates pass.
3. Canary window:
   - minimum 30 minutes observation per group.

## Rollback Trigger Matrix

| trigger | threshold | action |
|---|---|---|
| done-event availability drop | < 98.0% in canary window | immediate rollback |
| writeback failure ratio | > 1.0% in 30m | rollback + incident |
| phase2 scenario failure | any failed run | rollback + deployment freeze |
| security incident | any confirmed critical event | immediate rollback + key rotation |

## Approval Gates

| gate | approver | required_artifact |
|---|---|---|
| pre-release governance | engineering | latest PASS of governance tests |
| canary promotion | operations | canary monitoring summary |
| production completion | engineering + product operations | release evidence entry |

- No gate can be bypassed without documented emergency approval.

## Automated Verification Sequence

1. `DRY_RUN=1 bash scripts/ci/deploy_functions.sh`
2. `DRY_RUN=1 bash scripts/governance/check_phase2_signoff_gate.sh`
3. `DRY_RUN=1 bash scripts/ci/release_go_live.sh`
4. `bash tests/governance/test_phase3_slo_runbook_presence.sh`
5. `bash tests/governance/test_phase3_security_ops_presence.sh`
6. `bash tests/governance/test_phase3_cost_guardrails_presence.sh`
7. `bash tests/governance/test_phase3_release_automation_presence.sh`
8. `bash scripts/ci/final_gate.sh`
9. `bash tests/governance/test_docs_presence.sh`
10. `bash tests/governance/test_e2e_governance.sh`

Any failure in this sequence blocks release promotion.

## Release Evidence Log

For each release, record:
- UTC timestamp
- commit SHA
- gates command outputs
- canary result
- rollback decision (yes/no) and reason
- approver signatures

Evidence location:
- `docs/governance/BASELINE-VERIFICATION-2026-02-23.md`
- `docs/governance/REBUILD-VERIFICATION-2026-02-23.md`
- `docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md`
- `docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md`
