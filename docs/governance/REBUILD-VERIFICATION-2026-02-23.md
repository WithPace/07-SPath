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
   - `assessment_request_id=9675e6d8-73a7-43be-af3b-ca6a3afcc7ed`
   - `training_advice_request_id=c6baae05-9cd6-4896-8b72-410d9acbc0c6`
   - `chat_request_id=ed9b137f-1e24-4bc4-94a1-5a1ad10c88ae`
   - `dashboard_request_id=159cbfb5-679b-4287-8dec-6786399c69bb`
   - `training_request_id=c2ad7b3f-cd22-46eb-b505-5f8bbe7f3354`
   - `training_record_request_id=dfc5e2d1-d5f5-451b-8eab-5a22c7ee1878`
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
28. `supabase functions deploy chat-casual --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
29. Chat memory sync smoke output sample:
   - `chat_request_id=ed9b137f-1e24-4bc4-94a1-5a1ad10c88ae`
   - `user_id=b9bb26ed-c07c-472d-b89f-703004fcf85b`
   - `child_id=15e18a22-cdb6-4fc6-884f-a7ccbfbdf92c`
30. `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
31. Training memory sync smoke output sample:
   - `training_request_id=b9cd1f2a-eba6-4140-8446-193b559f0472`
   - `user_id=0be023c7-3fe7-4906-bbde-7b034104ab3c`
   - `child_id=c90aebb6-0ca6-4b45-87a3-92ed44b21c73`
32. `bash scripts/ci/final_gate.sh` -> PASS.
33. Final-gate training smoke output sample:
   - `training_request_id=2f35fd8c-6b36-4eb2-8af0-d5b227ab02df`
   - `user_id=bb641c68-d65d-4981-8d0b-bcaf0d3fbe69`
   - `child_id=e003c4d5-baff-4680-a96a-3c39d9d6a28b`
34. `supabase functions deploy dashboard --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
35. Dashboard affected-table smoke output sample:
   - `dashboard_request_id=391a0df3-bc6a-4a4d-a301-e08f909df192`
   - `user_id=50e89c5a-3a75-4de0-85c9-0f1fb15ec5a0`
   - `child_id=b3fcca37-948b-4954-8fad-fac823635a62`
36. `bash scripts/ci/final_gate.sh` -> PASS.
37. Final-gate dashboard smoke output sample:
   - `dashboard_request_id=9730309a-8f17-49f5-a0f6-ce3b7bf848ab`
   - `user_id=6eb181a6-c49c-4ca3-a16c-700c0cff3c30`
   - `child_id=f5c6ba05-c0ae-4cc6-bc20-c6e99bb2e47e`
38. `supabase functions deploy assessment --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
39. `supabase functions deploy training --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
40. `supabase functions deploy training-advice --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
41. `supabase functions deploy training-record --project-ref innaguwdmdfugrbcoxng --use-api --no-verify-jwt` -> PASS.
42. `bash tests/e2e/test_orchestrator_assessment_training_live.sh` -> PASS.
43. Assessment/training-advice metadata sync smoke output sample:
   - `assessment_request_id=63e5aea2-755a-4515-9b74-c313d00c477e`
   - `training_request_id=e3f27ff6-2cd3-4e44-b50a-171314988ed2`
44. `bash tests/e2e/test_orchestrator_training_live.sh` -> PASS.
45. Training metadata sync smoke output sample:
   - `training_request_id=5090a0cc-65b3-427a-b795-b203a47b3484`
46. `bash tests/e2e/test_orchestrator_training_record_live.sh` -> PASS.
47. Training-record metadata sync smoke output sample:
   - `training_record_request_id=fc5fe82f-7721-44c0-baf8-2605a7d20147`
48. `bash scripts/ci/final_gate.sh` -> PASS.
49. Final-gate metadata sync smoke output sample:
   - `assessment_request_id=345da6d8-275d-40a5-9d0c-6b9d272920b3`
   - `training_advice_request_id=4962fac3-8f28-4d99-b4b6-9e4478c1ac2c`
   - `training_request_id=991d461f-b3d2-40bc-a4e7-25ae1a57c84a`
   - `training_record_request_id=acd3eb5d-a1e6-4fec-9ee8-d9305d523ea1`
50. Latest verification timestamp (UTC): `2026-02-24T15:09:19Z`

## Assertions Confirmed

- `orchestrator` returns SSE `event: done`.
- One or more `user` and `assistant` messages persisted for the same child/user.
- `operation_logs` contains `action_name=chat_casual_reply` with same `request_id`.
- `operation_logs.affected_tables` for `chat_casual_reply` includes `children_memory`.
- `operation_logs` contains `action_name=assessment_generate` and `action_name=training_advice_generate` for new modules.
- `operation_logs.affected_tables` for `assessment_generate` includes `children_profiles` and `chat_messages`.
- `operation_logs.affected_tables` for `training_advice_generate` includes `children_memory` and `chat_messages`.
- `operation_logs` contains `action_name=training_generate` for training module.
- `operation_logs.affected_tables` for `training_generate` includes `children_memory` and `chat_messages`.
- `operation_logs` contains `action_name=training_record_create` for training-record module.
- `operation_logs.affected_tables` for `training_record_create` includes `children_profiles` and `chat_messages`.
- `operation_logs` contains `action_name=dashboard_generate` for dashboard module.
- `operation_logs.affected_tables` for `dashboard_generate` includes `chat_messages`.
- `assessments`, `training_plans`, `training_sessions`, `children_profiles`, and `children_memory` domain tables receive live writeback rows.
- Dashboard writeback stores assistant `cards_json` and links trace by same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Remaining reliability/tooling gaps are tracked in `docs/governance/GAP-REGISTER.md`.
