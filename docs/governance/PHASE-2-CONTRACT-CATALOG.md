# Phase 2 Contract Catalog

## Scope

Phase 2 covers business-capability delivery contracts for current execution modules:
- `chat-casual`
- `assessment`
- `training`
- `training-advice`
- `training-record`
- `dashboard`

## Module Output Contracts

### chat-casual

- done payload required fields:
  - `request_id`
  - `model_used`
- writeback action:
  - `action_name=chat_casual_reply`
- minimum affected tables:
  - `chat_messages`
  - `children_memory`

### assessment

- done payload required fields:
  - `request_id`
  - `model_used`
  - `assessment_id`
- writeback action:
  - `action_name=assessment_generate`
- minimum affected tables:
  - `assessments`
  - `children_profiles`
  - `chat_messages`

### training

- done payload required fields:
  - `request_id`
  - `model_used`
  - `training_plan_id`
- writeback action:
  - `action_name=training_generate`
- minimum affected tables:
  - `training_plans`
  - `children_memory`
  - `chat_messages`

### training-advice

- done payload required fields:
  - `request_id`
  - `model_used`
  - `training_plan_id`
- writeback action:
  - `action_name=training_advice_generate`
- minimum affected tables:
  - `training_plans`
  - `children_memory`
  - `chat_messages`

### training-record

- done payload required fields:
  - `request_id`
  - `model_used`
  - `training_session_id`
- writeback action:
  - `action_name=training_record_create`
- minimum affected tables:
  - `training_sessions`
  - `children_profiles`
  - `chat_messages`

### dashboard

- done payload required fields:
  - `request_id`
  - `model_used`
  - `role`
  - `card_count`
- delta payload contract:
  - includes `cards`
- writeback action:
  - `action_name=dashboard_generate`
- minimum affected tables:
  - `training_sessions`
  - `assessments`
  - `training_plans`
  - `chat_messages`

## Scenario Mapping

- Weekly parent journey scenario:
  - `tests/e2e/test_phase2_parent_weekly_journey_live.sh`
- Dashboard follow-up scenario:
  - `tests/e2e/test_phase2_parent_dashboard_followup_live.sh`

## Data Assurance Mapping

- scenario writeback consistency:
  - `tests/db/test_phase2_scenario_writeback_consistency.sh`
- business output contract:
  - `tests/functions/test_phase2_business_output_contract.sh`

## Exit Condition

Phase 2 contract catalog is accepted when all mapped tests pass under:
- `bash scripts/ci/final_gate.sh`
- `bash tests/governance/test_docs_presence.sh`
- `bash tests/governance/test_e2e_governance.sh`
