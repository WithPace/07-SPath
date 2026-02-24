# Assessment Profile Sync Design

## Context

- Current assessment chain writes `assessments` + `chat_messages` + writeback logs.
- Product/data docs require assessment completion to generate a new `children_profiles` version.
- Training-record has already been upgraded to profile version writeback; assessment should align.

## Problem

- `supabase/functions/assessment/index.ts` does not write `children_profiles`.
- `tests/e2e/test_orchestrator_assessment_training_live.sh` does not assert profile version side effects.
- Governance evidence currently validates assessment/training plans only, without assessment profile writeback.

## Option Analysis

### Option A (Selected): In-function profile version sync

- Add profile recompute logic directly in `assessment` function.
- Read latest `children_profiles`, generate version+1 domain snapshot, insert new row.
- Update `finalizeWriteback` metadata to include `children_profiles`.
- Extend existing assessment-training live e2e to assert profile side effects.

Trade-offs:
- Pros: Minimal structural change, consistent with current edge-function ownership model.
- Cons: Domain scoring is heuristic and can be refined later.

### Option B: DB trigger on `assessments`

- Auto-generate profile versions via DB trigger.

Trade-offs:
- Pros: Centralized invariant.
- Cons: Higher schema complexity, harder to iterate model/domain logic.

### Option C: Outbox-only marker

- Emit event now, let downstream worker generate profile.

Trade-offs:
- Pros: Low immediate function complexity.
- Cons: Fails immediate writeback expectations for current execution chain.

## Chosen Design

- Keep chain: `orchestrator -> assessment`.
- Within `assessment`:
  - infer focus domain from message/model text
  - derive risk baseline
  - recompute six-domain `domain_levels` against latest version
  - insert `children_profiles` new version with `score_reason=评估结果更新`
- Update writeback evidence:
  - `affectedTables` includes `children_profiles`
  - payload includes new profile id/version/focus domain
- Extend live e2e:
  - assert `children_profiles` row exists after assessment
  - assert `operation_logs.affected_tables` contains `children_profiles`
