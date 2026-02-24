# Rebuild Verification (2026-02-23)

## Scope

- Supabase linked project destructive rebuild applied via migration.
- Runtime chain verified: `orchestrator -> {chat-casual, assessment, training-advice, training-record} -> finalize_writeback`.
- Live assertions include `chat_messages`, `assessments`, `training_plans`, `training_sessions`, `operation_logs`, `snapshot_refresh_events`, and `conversations`.

## Environment Notes

- Project ref: `innaguwdmdfugrbcoxng`
- Functions deployed with `--use-api --no-verify-jwt` at gateway layer.
- In-function auth still enforced via JWT validation in `_shared/auth.ts`.
- Default model switched to `kimi` due current doubao endpoint availability.

## Command Evidence

1. `bash scripts/db/rebuild_remote.sh` -> PASS (`supabase db push --linked --include-all` succeeded).
2. `bash tests/db/test_06_apply_rebuild.sh` -> PASS.
3. `bash tests/functions/test_shared_modules.sh` -> PASS.
4. `bash tests/functions/test_chain_files.sh` -> PASS.
5. `bash tests/e2e/test_orchestrator_chat_casual_live.sh` -> PASS.
6. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS.
7. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS.
8. `bash scripts/ci/final_gate.sh` -> PASS (`governance + db + functions + e2e + ci` full sweep).
9. Chat chain smoke output sample:
   - `request_id=2a66dca7-55c1-4e20-ad3a-2bcb7b243305`
   - `user_id=94d775e1-ac7b-4cdb-a061-4590c89fb1b9`
   - `child_id=a8bff8a7-fd94-4596-992f-6e7701700828`
10. Assessment-training smoke output sample:
   - `assessment_request_id=d8a3d4ba-0395-4256-8137-b7dcb7c4d21f`
   - `training_request_id=a32dc367-e029-4a38-95f2-5a8c854d2c15`
11. Training-record smoke output sample:
   - `training_record_request_id=ad116998-76f4-4a3e-b0d1-4d86bb3a14a0`
12. Final sweep smoke output sample:
   - `assessment_request_id=e223b603-5645-4683-a6ba-66a2852d98c3`
   - `training_request_id=a0523ed8-87fd-4118-bfa3-eec2879565c7`
   - `chat_request_id=28887680-ec8e-4dcb-bf87-4ecb456fad9a`
   - `training_record_request_id=32c56388-07f8-4743-ac8f-d1d42bd0c12c`
13. `bash tests/governance/test_build_idempotent.sh` -> PASS.
14. `bash tests/ci/test_final_gate_script.sh` -> PASS.
15. `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
16. Latest verification timestamp (UTC): `2026-02-24T04:22:28Z`

## Assertions Confirmed

- `orchestrator` returns SSE `event: done`.
- One or more `user` and `assistant` messages persisted for the same child/user.
- `operation_logs` contains `action_name=chat_casual_reply` with same `request_id`.
- `operation_logs` contains `action_name=assessment_generate` and `action_name=training_advice_generate` for new modules.
- `operation_logs` contains `action_name=training_record_create` for training-record module.
- `assessments`, `training_plans`, and `training_sessions` domain tables receive live writeback rows.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Remaining reliability/tooling gaps are tracked in `docs/governance/GAP-REGISTER.md`.
