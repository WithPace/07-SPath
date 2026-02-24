# Rebuild Verification (2026-02-23)

## Scope

- Supabase linked project destructive rebuild applied via migration.
- Runtime chain verified: `orchestrator -> {chat-casual, assessment, training-advice, training-record, dashboard} -> finalize_writeback`.
- Live assertions include `chat_messages` (with dashboard `cards_json`), `assessments`, `training_plans`, `training_sessions`, `operation_logs`, `snapshot_refresh_events`, and `conversations`.

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
8. `bash tests/e2e/test_orchestrator_dashboard_live.sh` -> PASS.
9. `bash scripts/ci/final_gate.sh` -> PASS (`governance + db + functions + e2e + ci` full sweep).
10. Chat chain smoke output sample:
   - `request_id=2fcd6527-645a-44f4-9b14-ca169ebe2b5b`
   - `user_id=5abd075d-e21d-4f64-837d-b00cb65832a1`
   - `child_id=9acc774f-7d44-4f6f-98bb-3c7774377cd4`
11. Assessment-training smoke output sample:
   - `assessment_request_id=b0b15ec3-2e17-49a9-864d-a8078ccd4342`
   - `training_request_id=0c34f4f8-6826-4680-9a51-2b666a8a0056`
12. Dashboard smoke output sample:
   - `dashboard_request_id=f2c98cd3-68a4-43d8-b1a6-7b5e2b89a061`
13. Training-record smoke output sample:
   - `training_record_request_id=90309d2b-0cb5-40aa-8333-f5bf57aceb50`
14. Final sweep smoke output sample:
   - `assessment_request_id=b0b15ec3-2e17-49a9-864d-a8078ccd4342`
   - `training_request_id=0c34f4f8-6826-4680-9a51-2b666a8a0056`
   - `chat_request_id=2fcd6527-645a-44f4-9b14-ca169ebe2b5b`
   - `dashboard_request_id=f2c98cd3-68a4-43d8-b1a6-7b5e2b89a061`
   - `training_record_request_id=90309d2b-0cb5-40aa-8333-f5bf57aceb50`
15. `bash tests/governance/test_build_idempotent.sh` -> PASS.
16. `bash tests/ci/test_final_gate_script.sh` -> PASS.
17. `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
18. Latest verification timestamp (UTC): `2026-02-24T06:04:16Z`

## Assertions Confirmed

- `orchestrator` returns SSE `event: done`.
- One or more `user` and `assistant` messages persisted for the same child/user.
- `operation_logs` contains `action_name=chat_casual_reply` with same `request_id`.
- `operation_logs` contains `action_name=assessment_generate` and `action_name=training_advice_generate` for new modules.
- `operation_logs` contains `action_name=training_record_create` for training-record module.
- `operation_logs` contains `action_name=dashboard_generate` for dashboard module.
- `assessments`, `training_plans`, and `training_sessions` domain tables receive live writeback rows.
- Dashboard writeback stores assistant `cards_json` and links trace by same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Remaining reliability/tooling gaps are tracked in `docs/governance/GAP-REGISTER.md`.
