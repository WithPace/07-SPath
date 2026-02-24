# Rebuild Verification (2026-02-23)

## Scope

- Supabase linked project destructive rebuild applied via migration.
- Runtime chain verified: `orchestrator -> {chat-casual, assessment, training, training-advice, training-record, dashboard} -> finalize_writeback`.
- Live assertions include `chat_messages` (with dashboard `cards_json`), `assessments`, `training_plans`, `training_sessions`, `children_profiles`, `children_memory`, `operation_logs`, `snapshot_refresh_events`, and `conversations`.

## Environment Notes

- Project ref: `innaguwdmdfugrbcoxng`
- Functions deployed with `--use-api --no-verify-jwt` at gateway layer.
- In-function auth still enforced via JWT validation in `_shared/auth.ts`.
- Default model switched to `kimi` due current doubao endpoint availability.

## Command Evidence

1. `bash scripts/db/rebuild_remote.sh` -> PASS (`supabase db push --linked --include-all` + remote `pg_dump` snapshot succeeded).
2. `bash tests/db/test_06_apply_rebuild.sh` -> PASS.
3. `bash tests/functions/test_shared_modules.sh` -> PASS.
4. `bash tests/functions/test_chain_files.sh` -> PASS.
5. `bash tests/e2e/test_orchestrator_chat_casual_live.sh` -> PASS.
6. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS.
7. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS.
8. `bash tests/e2e/test_orchestrator_dashboard_live.sh` -> PASS.
9. `bash scripts/ci/final_gate.sh` -> PASS (`governance + db + functions + e2e + ci` full sweep).
10. Chat chain smoke output sample:
   - `request_id=17d0d87f-570e-498e-af9a-73a06b94cdef`
   - `user_id=9f35fce7-af65-49d9-ba06-85699314efc3`
   - `child_id=5ab1117d-5eb4-4b2d-9d20-3e3a478d2760`
11. Assessment-training smoke output sample:
   - `assessment_request_id=c7fd5a88-92c3-4de1-a4b8-56b756942502`
   - `training_request_id=fe262c18-312c-4529-aa38-864f02d6a92e`
12. Dashboard smoke output sample:
   - `dashboard_request_id=96298e24-3710-40e7-9ca7-e04c07d57274`
13. Training-record smoke output sample:
   - `training_record_request_id=0adf115e-4bd5-4a6a-bc5f-7afdeab56285`
14. Final sweep smoke output sample (latest run):
   - `assessment_request_id=9acb7cdf-9ad6-4ce9-88f2-106482ab38b3`
   - `training_advice_request_id=5fa703e7-a5a5-4c53-8a4b-b41c9f2f7442`
   - `chat_request_id=2b04f09b-0dae-4d75-ad5b-e09065ffec5d`
   - `dashboard_request_id=3271b980-4d1d-4617-b492-dd41680358ec`
   - `training_request_id=9fe09099-2020-4639-9add-95d42b7794c5`
   - `training_record_request_id=a831cafe-0f75-4dad-a2d9-2128f343da90`
15. `bash tests/governance/test_build_idempotent.sh` -> PASS.
16. `bash tests/ci/test_final_gate_script.sh` -> PASS.
17. `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
18. `supabase functions deploy orchestrator --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
19. `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
20. `bash tests/ci/test_workflow_presence.sh` -> PASS.
21. `bash tests/e2e/test_orchestrator_training_live.sh` -> PASS.
22. Training smoke output sample:
   - `training_request_id=41af2bb5-ec9d-438f-879f-25cae83632d0`
   - `user_id=3aa817b2-7583-4e4f-9b74-2b70df8a0e8c`
   - `child_id=80646766-51a6-4a98-8730-ee7dca284932`
23. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS.
24. `supabase functions deploy training-record --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
25. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS.
26. Training-record profile sync smoke output sample:
   - `training_record_request_id=a86f7f56-dbd2-43c1-a378-4abd284b4f54`
   - `user_id=ef7b7a55-e0c0-4ac1-a7a8-e3e635a7c598`
   - `child_id=6bc3df0f-88ff-4e32-9ea9-a3624fbc6fc7`
27. `supabase functions deploy training-advice --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
28. Latest verification timestamp (UTC): `2026-02-24T12:28:33Z`

## Assertions Confirmed

- `orchestrator` returns SSE `event: done`.
- One or more `user` and `assistant` messages persisted for the same child/user.
- `operation_logs` contains `action_name=chat_casual_reply` with same `request_id`.
- `operation_logs` contains `action_name=assessment_generate` and `action_name=training_advice_generate` for new modules.
- `operation_logs.affected_tables` for `assessment_generate` includes `children_profiles`.
- `operation_logs.affected_tables` for `training_advice_generate` includes `children_memory`.
- `operation_logs` contains `action_name=training_generate` for training module.
- `operation_logs` contains `action_name=training_record_create` for training-record module.
- `operation_logs.affected_tables` for `training_record_create` includes `children_profiles`.
- `operation_logs` contains `action_name=dashboard_generate` for dashboard module.
- `assessments`, `training_plans`, `training_sessions`, `children_profiles`, and `children_memory` domain tables receive live writeback rows.
- Dashboard writeback stores assistant `cards_json` and links trace by same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Remaining reliability/tooling gaps are tracked in `docs/governance/GAP-REGISTER.md`.
