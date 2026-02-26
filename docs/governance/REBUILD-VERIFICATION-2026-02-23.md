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
50. `bash tests/functions/test_affected_tables_contract.sh` -> PASS.
51. `bash scripts/ci/final_gate.sh` -> PASS.
52. Final-gate contract gate smoke output sample:
   - `assessment_request_id=adff0a45-3e67-44b8-a392-d96bd85fba46`
   - `training_advice_request_id=dd5113af-9421-492f-8386-a179d203aa6d`
   - `training_request_id=abf1f171-3ba7-4647-9bf9-835f1298f001`
   - `training_record_request_id=d6c6da08-1876-4253-8850-d15781accbdd`
53. `bash tests/functions/test_writeback_metadata_contract.sh` -> PASS.
54. `bash scripts/ci/final_gate.sh` -> PASS.
55. Final-gate writeback-metadata smoke output sample:
   - `assessment_request_id=48e6564b-471b-450b-834f-0285ce544e89`
   - `training_advice_request_id=bd4b982a-f7db-4518-a6a4-ebd6019ac1eb`
   - `training_request_id=50d916bd-6157-4ede-b7f7-a14fcafd7865`
   - `training_record_request_id=87cbbc89-d552-4c84-9f14-5ad84171c572`
56. `bash tests/functions/test_orchestrator_route_contract.sh` -> PASS.
57. `bash scripts/ci/final_gate.sh` -> PASS.
58. Final-gate route-contract smoke output sample:
   - `assessment_request_id=fdd5a847-6caa-483c-bfa4-ee1e39e53b28`
   - `training_advice_request_id=a53c206e-1a31-4ec7-bc98-e93c37ec4d75`
   - `training_request_id=3284ff9e-ed8d-4819-a16e-e67c45f0d869`
   - `training_record_request_id=b11c647a-f1ef-4bf2-89e4-f58110f4c9b6`
59. `bash tests/e2e/test_orchestrator_idempotency_live.sh` -> PASS.
60. `bash scripts/ci/final_gate.sh` -> PASS.
61. Final-gate idempotency smoke output sample:
   - `request_id=fbf26faa-9518-46be-b9e2-7c61115f8215`
   - `assessment_request_id=16830849-8e62-40a0-b763-34383caeaf1a`
   - `training_advice_request_id=a12fc981-fe70-4682-8a25-54a9bde1dd83`
   - `training_request_id=929f9408-ab55-4730-ba77-b95d273e6954`
   - `training_record_request_id=7c4ed8e1-1806-4abd-bf88-dba07cf60c20`
62. `bash tests/e2e/test_live_smoke_cleanup_contract.sh` -> PASS.
63. `bash scripts/ci/final_gate.sh` -> PASS.
64. Final-gate cleanup-contract smoke output sample:
   - `assessment_request_id=32188ac6-9de9-4e73-bb0d-a3eb486c81e2`
   - `training_advice_request_id=1b0ca920-42d5-4220-a9cd-8ea5bfdea14b`
   - `chat_request_id=930f38a5-c340-4f0a-9436-441140b5d155`
   - `dashboard_request_id=81ef96e6-d117-4334-830a-6004cd801bca`
   - `idempotency_request_id=49681c19-75bb-4660-b55a-a154eba02d82`
   - `training_request_id=d43ef379-767d-49bf-b8cd-14484e7de24e`
   - `training_record_request_id=5b8df105-78d2-424e-8d06-4900c0bf1a78`
65. `bash tests/e2e/test_live_smoke_retry_contract.sh` -> PASS.
66. `bash scripts/ci/final_gate.sh` -> PASS.
67. Final-gate retry-contract smoke output sample:
   - `assessment_request_id=6f64fcf8-9664-4091-85d9-87e37dc15274`
   - `training_advice_request_id=cf8d5323-dd25-4bd4-b1fd-eee0a2c7a089`
   - `chat_request_id=201fa6ae-b0b7-42d3-b00f-4f30e0a76e3e`
   - `dashboard_request_id=58cba1af-3e4f-4729-829b-7017e91e4141`
   - `idempotency_request_id=02cb1b0b-8d6a-427a-b081-c58a5c27ecd1`
   - `training_request_id=a645b3fd-0a6b-455d-81d4-1a9d20be76eb`
   - `training_record_request_id=d72ab155-b1c7-4fed-8f93-6d2fd276bc27`
68. `bash tests/e2e/test_live_smoke_retry_limits_contract.sh` -> PASS.
69. `bash scripts/ci/final_gate.sh` -> PASS.
70. Final-gate retry-limits smoke output sample:
   - `assessment_request_id=479863e8-c385-43e0-afa3-597ad0fa3924`
   - `training_advice_request_id=66b6df31-067b-4f39-8b94-72ca0d0448dd`
   - `chat_request_id=a1bdc9b0-c100-4e5c-93a2-3b1f61b2922b`
   - `dashboard_request_id=4afeb36b-b09b-4af2-a382-6c8cd1d29ff4`
   - `idempotency_request_id=e9b32963-2dfe-4362-8590-9212df6f611c`
   - `training_request_id=e07741ad-34d1-4c7a-ae05-706fe8eb460b`
   - `training_record_request_id=7aaac883-7e6f-4a91-a93a-6813f0f1d6b9`
72. `bash tests/e2e/test_live_smoke_retry_observability_contract.sh` -> PASS.
73. `bash scripts/ci/final_gate.sh` -> PASS.
74. Final-gate retry-observability smoke output sample:
   - `assessment_request_id=1da32244-b5c7-4e21-854f-c3a3e87a3e4f`
   - `training_advice_request_id=93ee7a77-1a12-4422-bba5-f87f61e93ed4`
   - `chat_request_id=80e99967-0f12-4ba2-bde9-68062c01ec13`
   - `dashboard_request_id=7a599a1c-0be0-4e26-b448-1514f0c865d0`
   - `idempotency_request_id=8a326c2e-3dd9-4367-857a-3ab45897100a`
   - `training_request_id=1b33f9fe-b911-4624-8bd3-6d0585f0f0ae`
   - `training_record_request_id=0b81d001-ec07-44f4-8f40-30c6872dc0a3`
76. `bash tests/e2e/test_live_smoke_retry_reason_contract.sh` -> PASS.
77. `bash scripts/ci/final_gate.sh` -> PASS.
78. Final-gate retry-reason-taxonomy smoke output sample:
   - `assessment_request_id=dd0f4e91-5921-4d34-9baf-85f4a51ed7ee`
   - `training_advice_request_id=8f04cd6f-5e2d-4813-bc2e-15f2aad53c94`
   - `chat_request_id=20c27d8c-e608-4f9b-b7c6-00b075effeca`
   - `dashboard_request_id=ebbafaf2-ddf1-48cb-beda-bf8911735a48`
   - `idempotency_request_id=6684ec5e-2fc6-48d1-930c-99a9e3e5f223`
   - `training_request_id=5be06a50-1a27-426c-88ec-7feb85ab2c0c`
   - `training_record_request_id=9a58f12d-650e-485d-b07b-ee33a5a6b680`
80. `bash tests/e2e/test_live_smoke_retry_reason_action_contract.sh` -> PASS.
81. `bash scripts/ci/final_gate.sh` -> PASS.
82. Final-gate retry-reason-action smoke output sample:
   - `assessment_request_id=29cfa3f4-91c6-4a35-8d50-088ab0a952db`
   - `training_advice_request_id=30543f11-5746-46da-8fb6-55da0874190c`
   - `chat_request_id=b86ad209-cf78-481e-8bf6-725e182937d1`
   - `dashboard_request_id=18f0f73b-8d58-4148-8131-5d80aa2a6abf`
   - `idempotency_request_id=21859939-1521-42ef-a3cf-8c94b68597dc`
   - `training_request_id=02ebdc39-2100-4467-8dd1-49ee38b899da`
   - `training_record_request_id=c63bf275-8b8a-41d1-bb04-587c75756c2c`
84. `bash tests/e2e/test_live_smoke_retry_outcome_state_contract.sh` -> PASS.
85. `bash scripts/ci/final_gate.sh` -> PASS.
86. Final-gate retry-outcome-state smoke output sample:
   - `assessment_request_id=01551945-cb96-49a5-abe7-e5be1863198b`
   - `training_advice_request_id=3996cb10-1a45-4d20-8cf0-da2f45d4aa76`
   - `chat_request_id=4f643906-9864-4924-9677-de8b1465916d`
   - `dashboard_request_id=244bcc76-16b3-4924-b781-95772f6c21cd`
   - `idempotency_request_id=e18a5f07-2ae5-433e-a33d-ae14bb16fa04`
   - `training_request_id=e1e287ab-9253-42be-a817-88e0f894a4fc`
   - `training_record_request_id=f98e39ce-0bef-4ab3-bcce-61acfea76bf7`
88. `bash tests/e2e/test_live_smoke_retry_state_reset_contract.sh` -> PASS.
89. `bash scripts/ci/final_gate.sh` -> PASS.
90. Final-gate retry-state-reset smoke output sample:
   - `assessment_request_id=c9539a59-ac27-4912-80a4-de28c9ca894f`
   - `training_advice_request_id=8a992eac-49a8-4f7a-8e78-38eb40709b8e`
   - `chat_request_id=a8b50660-5c33-40a7-9eb3-8ff9313e356c`
   - `dashboard_request_id=4fd9b11e-958e-4c02-8533-f98af4806fb7`
   - `idempotency_request_id=281f3476-4f28-417a-9806-2cb99cd76516`
   - `training_request_id=68067608-583a-40eb-826e-1acdb7aea706`
   - `training_record_request_id=b7946658-fabc-49c1-a2a4-702fccc16c22`
92. `bash tests/e2e/test_live_smoke_retry_cards_contract.sh` -> PASS.
93. `bash scripts/ci/final_gate.sh` -> PASS.
94. Final-gate retry-cards smoke output sample:
   - `assessment_request_id=01912d35-b2cf-4c34-8c52-89e4fcf429d8`
   - `training_advice_request_id=9910dd1b-d9d7-4d5b-8217-3f5be2aba4ec`
   - `chat_request_id=5033f766-30d5-4490-bd3b-eccd6328ee5d`
   - `dashboard_request_id=af770abd-373e-4462-a22e-5740c347e798`
   - `idempotency_request_id=b0c66857-ef61-41ae-9cac-5acb11b61cc7`
   - `training_request_id=39887090-dff5-4297-b5d9-a0ddebe80a5e`
   - `training_record_request_id=a9fe84f2-2aa1-480e-a22e-5f3f09c56fb5`
95. Latest verification timestamp (UTC): `2026-02-25T13:25:40Z`
96. `bash scripts/ci/final_gate.sh` -> PASS (rerun after transient Supabase API TLS timeout).
97. Final-gate retry-cards smoke output sample:
   - `assessment_request_id=fd38e488-ca58-481f-971c-6088fc71a65d`
   - `chat_request_id=c8d71917-6c80-45f6-96fd-0d117247f3e2`
   - `dashboard_request_id=1a375e81-1822-4cfa-b86d-a11613af9732`
   - `idempotency_request_id=352c8213-d124-4b3c-9bbd-6f02bca214b5`
   - `training_request_id=5c6298ee-9811-4148-ad51-19e10400b07d`
   - `training_record_request_id=c6385fab-5c82-482f-97f3-2cd90986a43f`
98. `bash tests/governance/test_docs_presence.sh` -> PASS.
99. `bash tests/governance/test_e2e_governance.sh` -> PASS.
100. Latest verification timestamp (UTC): `2026-02-25T13:40:46Z`
101. `bash tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh` -> PASS.
102. `bash scripts/ci/final_gate.sh` -> PASS.
103. Final-gate retry-request-id-trace smoke output sample:
   - `assessment_request_id=ee8607e5-42f1-4873-9ca4-8c0610405c72`
   - `training_advice_request_id=3c6b8958-53b3-4936-997f-af4fdbb74b46`
   - `chat_request_id=049e070e-0493-49d1-97fd-887ad8ec5590`
   - `dashboard_request_id=64816a19-aa14-4802-b9e2-c41d70cc14d1`
   - `idempotency_request_id=8326c5df-3cb1-44f5-bf68-ad09f6b40239`
   - `training_request_id=9763998a-31c0-4a14-8bcd-6fa2e76ebbb9`
   - `training_record_request_id=e6565377-2743-45dc-80b1-a3ab46b30694`
104. `bash tests/governance/test_docs_presence.sh` -> PASS.
105. `bash tests/governance/test_e2e_governance.sh` -> PASS.
106. Latest verification timestamp (UTC): `2026-02-26T00:43:11Z`
107. `bash tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh` -> PASS.
108. `bash scripts/ci/final_gate.sh` -> PASS.
109. Final-gate retry-runtime-sanitization smoke output sample:
   - `assessment_request_id=512ed86b-577c-440d-94d9-bfb95bef931e`
   - `training_advice_request_id=5c648f16-90d9-4c47-ab69-aa11e40ffcca`
   - `chat_request_id=d6a00723-6537-4376-b3f6-ad1bb8893ecc`
   - `dashboard_request_id=d3798b43-0b36-4de6-83a0-241b74934d7b`
   - `idempotency_request_id=5fde7389-679d-46f5-aa58-c5e122e7bc8e`
   - `training_request_id=8d15c58c-59f4-4703-9d9e-b7aa840d8c4d`
   - `training_record_request_id=3d21ca1c-8bad-4982-ae35-52b0c4393750`
110. `bash tests/governance/test_docs_presence.sh` -> PASS.
111. `bash tests/governance/test_e2e_governance.sh` -> PASS.
112. Latest verification timestamp (UTC): `2026-02-26T02:29:45Z`

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
- Static contract gate `tests/functions/test_affected_tables_contract.sh` enforces action-to-table metadata coverage.
- Static contract gate `tests/functions/test_writeback_metadata_contract.sh` enforces action-to-event/snapshot metadata semantics.
- Static contract gate `tests/functions/test_orchestrator_route_contract.sh` enforces module alias routing and route tuple integrity.
- Live gate `tests/e2e/test_orchestrator_idempotency_live.sh` enforces duplicate `request_id` short-circuit (`idempotent=true`) and single completion log semantics.
- Live gate `tests/e2e/test_live_smoke_cleanup_contract.sh` enforces cleanup hooks (`cleanup()`, `trap cleanup EXIT`, admin user delete path, delete method) across all live smoke scripts.
- Live gate `tests/e2e/test_live_smoke_retry_contract.sh` enforces retry helper semantics (`WORKER_LIMIT` retry + exponential backoff + trace writeback) and all-script retry defaults.
- Live gate `tests/e2e/test_live_smoke_retry_limits_contract.sh` enforces bounded retry env values (`ORCH_MAX_ATTEMPTS` in `[2,6]`, `ORCH_RETRY_BASE_DELAY_SECONDS` in `[1,5]`) to prevent parameter drift.
- Live gate `tests/e2e/test_live_smoke_retry_observability_contract.sh` enforces retry/terminal-failure log field contract (`module`, `request_id`, `attempt`, `sleep_seconds`/`reason`) for helper observability stability.
- Live gate `tests/e2e/test_live_smoke_retry_reason_contract.sh` enforces retry reason taxonomy constants and canonical usage (`WORKER_LIMIT`, `worker_limit_exhausted`, `done_event_missing`).
- Live gate `tests/e2e/test_live_smoke_retry_reason_action_contract.sh` enforces reason-to-action mapping (`WORKER_LIMIT` -> retry/backoff/continue, terminal reasons -> terminal log + failure return).
- Live gate `tests/e2e/test_live_smoke_retry_outcome_state_contract.sh` enforces helper outcome state writeback (`ORCH_LAST_RESULT`, `ORCH_LAST_FAILURE_REASON`, `ORCH_LAST_ATTEMPT`) across success and failure branches.
- Live gate `tests/e2e/test_live_smoke_retry_state_reset_contract.sh` enforces per-call state reset and retry counter correctness (`ORCH_LAST_RETRY_COUNT`) to prevent stale diagnostics.
- Live gate `tests/e2e/test_live_smoke_retry_cards_contract.sh` enforces `require_cards` terminal semantics via dedicated reason `cards_payload_missing` and canonical terminal-failure logging.
- Live gate `tests/e2e/test_live_smoke_retry_request_id_trace_contract.sh` enforces per-attempt `request_ids` trace lineage and terminal `ORCH_LAST_REQUEST_ID` pointer correctness.
- Live gate `tests/e2e/test_live_smoke_retry_runtime_sanitization_contract.sh` enforces runtime fallback defaults for invalid retry env values (`ORCH_MAX_ATTEMPTS`, `ORCH_RETRY_BASE_DELAY_SECONDS`).
- `assessments`, `training_plans`, `training_sessions`, `children_profiles`, and `children_memory` domain tables receive live writeback rows.
- Dashboard writeback stores assistant `cards_json` and links trace by same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Remaining reliability/tooling gaps are tracked in `docs/governance/GAP-REGISTER.md`.
