# Phase 5 Role Contract Catalog

## Scope

This catalog defines role-aware response and permission contracts for Phase 5 full-port delivery across:

- backend repo: `starpath`
- user frontend repo: `starpath-frontend`
- admin web repo: `starpath-admin-web`

## Role Matrix

| role | channel | baseline responsibility |
|---|---|---|
| parent | user app | caregiver journey and weekly execution loop |
| doctor | user app | clinical follow-up review and risk commentary |
| teacher | user app | training progress and intervention execution context |
| org_admin | user app | organization-level roster and permission oversight |
| super_admin/operator/cs_agent/analyst | admin web | operations governance, prompt/content, ai ops, support |

## Module Contracts by Role

Required modules with role-aware output compatibility:

1. `orchestrator`
2. `chat-casual`
3. `assessment`
4. `training`
5. `training-advice`
6. `training-record`
7. `dashboard`

Role clauses:

- `parent`: all modules allowed in family-care flow, dashboard cards reflect child progress and action queue.
- `doctor`: assessment/training/training-advice/training-record/dashboard outputs include medical follow-up framing and risk views.
- `teacher`: training/training-advice/training-record/dashboard outputs include class/session execution and intervention notes.
- `org_admin`: dashboard and related orchestration outputs must support org-level summaries, member linkage, and permission context.

## Authorization and RLS Clauses

- Every role request must include deterministic role metadata validated before module dispatch.
- RLS checks must prevent cross-org and cross-child unauthorized reads/writes.
- `org_admin` may view org-bound entities but cannot bypass child-level membership constraints.
- Admin web privileged operations must run with deny-by-default policy and audit logging on every write action.

## Verification Mapping

Mandatory verification lanes:

1. contract presence and clause checks:
   - `bash tests/functions/test_phase5_role_contract_catalog_presence.sh`
2. backend role matrix contract checks:
   - `bash tests/functions/test_phase5_dashboard_role_matrix_contract.sh` (planned)
3. RLS role matrix checks:
   - `bash tests/db/test_phase5_rls_role_matrix.sh` (planned)
4. multi-role live journeys:
   - `bash tests/e2e/test_phase5_doctor_teacher_org_journeys_live.sh` (planned)
