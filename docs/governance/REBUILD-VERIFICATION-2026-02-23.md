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
113. `bash tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh` -> PASS.
114. `bash scripts/ci/final_gate.sh` -> PASS.
115. Final-gate retry-backoff-timing smoke output sample:
   - `assessment_request_id=c470dc39-e545-4790-b9ce-e773e82bd17a`
   - `training_advice_request_id=1735c352-7a79-40f6-898e-8a1dfc4d1da1`
   - `chat_request_id=a7dd90f3-a19f-4e7a-afa7-3706bbeb1ea7`
   - `dashboard_request_id=97470017-677e-48a5-a2cb-c645c114aaf6`
   - `idempotency_request_id=78d10388-f84f-4635-81d8-1380af90ef93`
   - `training_request_id=6cbb3d61-00a2-48e1-8c8c-cf90adafb821`
   - `training_record_request_id=3d32d91a-c3e9-42c8-9897-3c5b026fbfe6`
116. `bash tests/governance/test_docs_presence.sh` -> PASS.
117. `bash tests/governance/test_e2e_governance.sh` -> PASS.
118. Latest verification timestamp (UTC): `2026-02-26T02:50:18Z`
119. `bash tests/e2e/test_live_smoke_retry_transport_failure_contract.sh` -> PASS.
120. `bash scripts/ci/final_gate.sh` -> PASS.
121. Final-gate retry-transport-failure smoke output sample:
   - `assessment_request_id=c0091f10-559b-477f-8824-4509bca68ee6`
   - `training_advice_request_id=453dd8d3-8da1-4610-b60e-48fdeb5c4118`
   - `chat_request_id=fff3b108-5050-49a7-a1bd-8e0cb8d9f49f`
   - `dashboard_request_id=981c96f7-2b1f-4f21-b3fd-c31dba96805d`
   - `idempotency_request_id=06b17b73-fba4-4200-8e0c-86b1147d4d7f`
   - `training_request_id=52043087-7c0d-4a27-8517-b493a36600f5`
   - `training_record_request_id=8b2e2f9c-c2ab-462a-b373-4b07f40fd479`
122. `bash tests/governance/test_docs_presence.sh` -> PASS.
123. `bash tests/governance/test_e2e_governance.sh` -> PASS.
124. Latest verification timestamp (UTC): `2026-02-26T03:13:46Z`
125. `bash tests/e2e/test_live_smoke_retry_transport_observability_contract.sh` -> PASS.
126. `bash scripts/ci/final_gate.sh` -> PASS.
127. Final-gate retry-transport-observability smoke output sample:
   - `assessment_request_id=91b0e0be-6cd5-4c6e-bd8f-82f2c6dd12e1`
   - `training_advice_request_id=7a2efd5d-1abd-48b2-bd2a-4d2414fc8df6`
   - `chat_request_id=1cfce24c-a4ef-4fa9-8ec0-c023be0475da`
   - `dashboard_request_id=d6be33cb-0ba8-4c48-b5c8-db066514f1bc`
   - `idempotency_request_id=56fe7064-c41a-4441-9296-3f00f9588286`
   - `training_request_id=84bec54f-701c-4416-b958-0741688261ce`
   - `training_record_request_id=94fde17f-e41e-4d67-a3aa-33020b621277`
128. `bash tests/governance/test_docs_presence.sh` -> PASS.
129. `bash tests/governance/test_e2e_governance.sh` -> PASS.
130. Latest verification timestamp (UTC): `2026-02-26T07:01:10Z`
131. `bash tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh` -> PASS.
132. `bash scripts/ci/final_gate.sh` -> PASS.
133. Final-gate retry-transport-exit-code smoke output sample:
   - `assessment_request_id=b655bed7-9add-4a43-8123-c4b477adab2d`
   - `chat_request_id=4a073791-fa32-4305-8818-11345b110301`
   - `dashboard_request_id=b58120cf-57e1-4fa1-b43a-789bca6caf17`
   - `idempotency_request_id=eb9dbbf5-2cab-4795-ba6a-10b4d57add0a`
   - `training_request_id=b769aef9-fde3-4626-ac84-cf5e3fc06188`
   - `training_record_request_id=abd586eb-c20d-4307-b876-ca390eda9b1e`
134. `bash tests/governance/test_docs_presence.sh` -> PASS.
135. `bash tests/governance/test_e2e_governance.sh` -> PASS.
136. Latest verification timestamp (UTC): `2026-02-26T07:31:20Z`
137. `bash tests/functions/test_auth_and_body_parse_contract.sh` -> PASS.
138. `bash scripts/ci/final_gate.sh` -> PASS.
139. Final-gate auth-body-parse-contract smoke output sample:
   - `assessment_request_id=0d23cbaa-f1ea-446d-9a2b-96c6468c49f3`
   - `chat_request_id=28ba0b53-a1d1-4549-b912-594f54bcd60e`
   - `dashboard_request_id=3b177a19-3575-423e-a3a8-929077889b7b`
   - `idempotency_request_id=814acfba-1709-4000-8de8-dd4de41c953f`
   - `training_request_id=7baeb2df-fa1e-493a-9206-1047970b7aa3`
   - `training_record_request_id=3fa38f24-5b6e-46cb-8a7d-912200632942`
140. `bash tests/governance/test_docs_presence.sh` -> PASS.
141. `bash tests/governance/test_e2e_governance.sh` -> PASS.
142. Latest verification timestamp (UTC): `2026-02-26T07:54:28Z`
143. `bash tests/functions/test_shared_reliability_contract.sh` -> PASS.
144. `bash scripts/ci/final_gate.sh` -> PASS.
145. Final-gate shared-reliability-contract smoke output sample:
   - `assessment_request_id=1c44fb6f-8d9a-4260-9f3b-059eea3cfd53`
   - `chat_request_id=63621fca-5954-47b1-b5c6-d1dd6686d48c`
   - `dashboard_request_id=a871497b-5f30-47a2-a59b-02301fc4a00f`
   - `idempotency_request_id=c6a4118c-ab10-4b7e-be41-e7380b51f854`
   - `training_request_id=8aef9f4c-51a9-4fdf-b867-939eb50f75cd`
   - `training_record_request_id=b1b622f1-faf7-49b8-9c4f-bc521859daad`
146. `bash tests/governance/test_docs_presence.sh` -> PASS.
147. `bash tests/governance/test_e2e_governance.sh` -> PASS.
148. Latest verification timestamp (UTC): `2026-02-26T09:37:00Z`
149. `bash tests/functions/test_orchestrator_forwarding_contract.sh` -> PASS.
150. `bash scripts/ci/final_gate.sh` -> PASS.
151. Final-gate orchestrator-forwarding-contract smoke output sample:
   - `assessment_request_id=d6bc537d-a47f-431a-9fa5-f7f1e2e8fd76`
   - `chat_request_id=fe8f4f58-1fca-482b-88c8-496d9819436b`
   - `dashboard_request_id=bd50fb8e-0732-4f54-813b-e7161a85c5ec`
   - `idempotency_request_id=1c95b5dd-abea-45bf-972e-b4dcc6245d0c`
   - `training_request_id=8034464d-ac8e-4b57-9b10-cd53c24c9004`
   - `training_record_request_id=6a421b17-7fb3-42ed-a21d-0adf50d0a955`
152. `bash tests/governance/test_docs_presence.sh` -> PASS.
153. `bash tests/governance/test_e2e_governance.sh` -> PASS.
154. Latest verification timestamp (UTC): `2026-02-26T11:00:50Z`
155. `bash tests/functions/test_model_router_resilience_contract.sh` -> PASS.
156. `bash scripts/ci/final_gate.sh` -> PASS.
157. Final-gate model-router-resilience-contract smoke output sample:
   - `assessment_request_id=0e3a603d-4d49-49a0-a076-d34db94031d7`
   - `chat_request_id=061dc71a-b75a-4ca8-9a95-8ae0419a688c`
   - `dashboard_request_id=122af8c1-981d-490a-a87d-3e98c73dec01`
   - `idempotency_request_id=b1749b43-ea13-408d-a68a-430ecbd362ff`
   - `training_request_id=2a022476-af0c-461a-951a-596da21c3b73`
   - `training_record_request_id=61064505-21f2-4bc7-b8f8-844f845609f7`
158. `bash tests/governance/test_docs_presence.sh` -> PASS.
159. `bash tests/governance/test_e2e_governance.sh` -> PASS.
160. Latest verification timestamp (UTC): `2026-02-26T11:09:21Z`
161. `bash tests/functions/test_error_response_contract.sh` -> PASS.
162. `bash scripts/ci/final_gate.sh` -> PASS.
163. Final-gate error-response-contract smoke output sample:
   - `assessment_request_id=4f627be6-bb3a-4dd5-89bb-9ec984d76821`
   - `chat_request_id=c2c1f55d-ab00-4537-b298-a64d1e446b1c`
   - `dashboard_request_id=c4b97ee5-f7ea-42e5-a036-6e9aa03d9332`
   - `idempotency_request_id=146a2766-d498-4dee-bfea-3f8974191047`
   - `training_request_id=e92d88cb-856a-40fb-b749-e51ef5b13ea2`
   - `training_record_request_id=3fa54c23-fc84-4e57-9b0e-86d7d522ae57`
164. `bash tests/governance/test_docs_presence.sh` -> PASS.
165. `bash tests/governance/test_e2e_governance.sh` -> PASS.
166. Latest verification timestamp (UTC): `2026-02-26T12:09:45Z`
167. `bash tests/functions/test_orchestrator_conversation_bootstrap_contract.sh` -> PASS.
168. `bash scripts/ci/final_gate.sh` -> PASS.
169. Final-gate orchestrator-conversation-bootstrap-contract smoke output sample:
   - `assessment_request_id=76c5d31a-687e-4632-b91b-9696b98579d8`
   - `chat_request_id=1161570f-8f23-4c06-a430-ba988b229239`
   - `dashboard_request_id=d362c728-6a7e-419e-b7be-30be24ecb23a`
   - `idempotency_request_id=ad66fa3d-0dbf-42c2-b48b-594d8b2bd214`
   - `training_request_id=22039cdd-42fd-4337-a639-854150e9ae24`
   - `training_record_request_id=f952aab3-c372-4f46-b2ee-d76f56d57ebb`
170. `bash tests/governance/test_docs_presence.sh` -> PASS.
171. `bash tests/governance/test_e2e_governance.sh` -> PASS.
172. Latest verification timestamp (UTC): `2026-02-26T12:34:14Z`
173. `bash tests/functions/test_model_router_temperature_contract.sh` -> PASS.
174. `bash scripts/ci/final_gate.sh` -> PASS.
175. Final-gate model-router-temperature-contract smoke output sample:
   - `assessment_request_id=58dacdae-6481-4a15-94a2-a6582360b5ae`
   - `chat_request_id=e470c62d-3e07-4b71-9335-191195e7fa4a`
   - `dashboard_request_id=613e7bf5-44c1-4bf8-90e0-df21be0c7779`
   - `idempotency_request_id=1294aa59-3d5d-4bb8-81b7-39a6c5320150`
   - `training_request_id=0b74af3c-e932-42fd-a621-a1447f79df1d`
   - `training_record_request_id=305993a5-aa03-4f16-94bc-c600f01aa54c`
176. `bash tests/governance/test_docs_presence.sh` -> PASS.
177. `bash tests/governance/test_e2e_governance.sh` -> PASS.
178. Latest verification timestamp (UTC): `2026-02-26T12:44:39Z`
179. `bash tests/functions/test_request_id_lifecycle_contract.sh` -> PASS.
180. `bash scripts/ci/final_gate.sh` -> PASS.
181. Final-gate request-id-lifecycle-contract smoke output sample:
   - `assessment_request_id=e63b5c53-966a-4e54-9805-feafb0f17791`
   - `chat_request_id=8487695c-56dc-4c48-b9d5-9e62aea10682`
   - `dashboard_request_id=5a4a1792-fcab-45d8-8d00-63c8ad91a0e0`
   - `idempotency_request_id=00ba92d4-34d0-495f-a937-62d36fee69fe`
   - `training_request_id=a22cfa01-9a4e-4667-8fa7-be007533619a`
   - `training_record_request_id=fe1abc1c-f9a4-4240-b993-f077efe5c654`
182. `bash tests/governance/test_docs_presence.sh` -> PASS.
183. `bash tests/governance/test_e2e_governance.sh` -> PASS.
184. Latest verification timestamp (UTC): `2026-02-26T13:02:15Z`
185. `bash tests/functions/test_options_preflight_contract.sh` -> PASS.
186. `bash scripts/ci/final_gate.sh` -> PASS.
187. Final-gate options-preflight-contract smoke output sample:
   - `assessment_request_id=1931ba96-fa48-4a07-aa37-cc353cd9a7b9`
   - `chat_request_id=b3d65f3d-2bef-4c2f-a9ba-7d10e96ff37b`
   - `dashboard_request_id=9af0d217-9cc2-40f4-b435-16a53f947a9b`
   - `idempotency_request_id=272a9df1-28e8-4823-b9ed-8a7b2b8878e1`
   - `training_request_id=65a8c2ff-dc7f-4a16-8dcd-52405dd8c264`
   - `training_record_request_id=f4d6de6d-b7bb-40b1-ab43-f19a895e6db5`
188. `bash tests/governance/test_docs_presence.sh` -> PASS.
189. `bash tests/governance/test_e2e_governance.sh` -> PASS.
190. Latest verification timestamp (UTC): `2026-02-26T13:27:22Z`
191. `bash tests/functions/test_sse_framing_contract.sh` -> PASS.
192. `bash scripts/ci/final_gate.sh` -> PASS.
193. Final-gate sse-framing-contract smoke output sample:
   - `assessment_request_id=6c1744b5-e8d5-4fa1-86e4-4541f6bd2a8c`
   - `chat_request_id=e422d1d7-4bd5-4e8d-a83c-2b1cfe5aa713`
   - `dashboard_request_id=8da24c90-f753-4169-b71a-34cc26756e18`
   - `idempotency_request_id=2d8ac5fa-d039-43a7-9351-83846bf0b924`
   - `training_request_id=f64b6f02-58b6-4f14-8798-2152c1191c8d`
   - `training_record_request_id=b5b07e37-063f-4ddb-b6b5-f13f72ee7ad8`
194. `bash tests/governance/test_docs_presence.sh` -> PASS.
195. `bash tests/governance/test_e2e_governance.sh` -> PASS.
196. Latest verification timestamp (UTC): `2026-02-26T13:52:47Z`
197. `bash tests/functions/test_writeback_before_done_contract.sh` -> PASS.
198. `bash scripts/ci/final_gate.sh` -> PASS.
199. Final-gate writeback-before-done-contract smoke output sample:
   - `assessment_request_id=40d64bd8-80f3-4fd6-9d67-96c1f217310f`
   - `chat_request_id=04c9ccc4-ae85-4195-86f4-f6f1f7a164de`
   - `dashboard_request_id=98088b60-f4c6-4b1a-856b-7e9feeb60201`
   - `idempotency_request_id=714bb46c-3dcf-4167-9884-136322be60b8`
   - `training_request_id=7272ce84-9646-41bf-9aeb-3ca8c8bfa272`
   - `training_record_request_id=14bd2c8d-97a6-40fa-bbba-bb071296f0c4`
200. `bash tests/governance/test_docs_presence.sh` -> PASS.
201. `bash tests/governance/test_e2e_governance.sh` -> PASS.
202. Latest verification timestamp (UTC): `2026-02-26T14:16:54Z`
203. `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS.
204. `bash scripts/ci/final_gate.sh` -> PASS.
205. `bash tests/governance/test_docs_presence.sh` -> PASS.
206. `bash tests/governance/test_e2e_governance.sh` -> PASS.
207. Final-gate Phase 2 weekly journey smoke output sample:
   - `assessment_request_id=5efea2fa-ceac-4794-adaa-1be7ba9d9eb3`
   - `training_advice_request_id=5c3c5127-2e92-4e7c-8dff-1568bb48b8cf`
   - `training_request_id=de0f24c4-cb4c-45ed-a62a-f648b62391c4`
   - `training_record_request_id=c30ae7c0-0004-43f9-98e6-a20846d3714d`
   - `dashboard_request_id=ddc2b57d-d802-46d0-894f-77a9d118b378`
208. Phase 2 dashboard followup smoke output sample:
   - `training_request_id=2a75c851-d515-4f54-b84f-99924d08ee44`
   - `training_record_request_id=c1a5cef4-d9f4-4046-a665-bee8a0882e66`
   - `dashboard_request_id=4589d2f0-3f52-4471-a8db-9610af7ac791`
209. `bash tests/e2e/test_phase2_parent_weekly_journey_live.sh` -> PASS.
210. `bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh` -> PASS.
211. Latest verification timestamp (UTC): `2026-02-26T15:31:06Z`
212. `bash scripts/ci/final_gate.sh` -> PASS.
213. `bash tests/governance/test_docs_presence.sh` -> PASS.
214. `bash tests/governance/test_e2e_governance.sh` -> PASS.
215. Final-gate Phase 2 weekly journey smoke output sample:
   - `assessment_request_id=1936d0a5-3aad-4bbf-ae26-10bcbc589245`
   - `training_advice_request_id=d061ba55-3471-41e2-b96f-97cc4e0f6bf5`
   - `training_request_id=64200afb-1f60-49e9-b90b-cfcb392d2cf6`
   - `training_record_request_id=4c7ccc29-c08d-4557-a72d-a09e30a7585e`
   - `dashboard_request_id=3a24d315-b582-42c7-ac21-c3917a576439`
216. Phase 2 dashboard followup smoke output sample:
   - `training_request_id=c7fde7fd-3ed0-4742-bb12-2b7e472d44fb`
   - `training_record_request_id=a55c296e-6317-40ca-8977-97b5dffe9cd3`
   - `dashboard_request_id=b707c3df-d8df-4531-ab62-5a5c4dba95f3`
217. Latest verification timestamp (UTC): `2026-02-26T15:48:56Z`
218. `bash tests/governance/test_phase3_slo_runbook_presence.sh` -> PASS.
219. `bash tests/governance/test_phase3_security_ops_presence.sh` -> PASS.
220. `bash tests/governance/test_phase3_cost_guardrails_presence.sh` -> PASS.
221. `bash tests/governance/test_phase3_release_automation_presence.sh` -> PASS.
222. `bash scripts/ci/final_gate.sh` -> PASS.
223. `bash tests/governance/test_docs_presence.sh` -> PASS.
224. `bash tests/governance/test_e2e_governance.sh` -> PASS.
225. Final-gate Phase 3 chain smoke output sample:
   - `assessment_request_id=c156d60b-968f-4f6f-80a4-86f811a861bd`
   - `chat_request_id=4611950e-f524-417f-8ebb-8f2488789fb4`
   - `dashboard_request_id=4c7b335b-b311-4595-9f0a-6c1e50aa5b05`
   - `idempotency_request_id=b47d5501-cf0d-4705-8287-0f44443c16bc`
   - `training_request_id=c79c70d6-cdc6-4eed-a598-1baa91e50347`
   - `training_record_request_id=359641cd-235d-45f8-8da0-b1fc08b97739`
226. Final-gate Phase 2 weekly journey smoke output sample:
   - `assessment_request_id=facc4ab4-a59a-40d3-9944-6faed33cdd69`
   - `training_advice_request_id=b13248bd-c0f2-4dd1-996b-9d13db99637e`
   - `training_request_id=80286104-8c07-44a8-b2ac-be868a3f5304`
   - `training_record_request_id=198d05bf-76d7-40c9-afc9-26e6e02dbd91`
   - `dashboard_request_id=b2562c29-2f50-4e6a-9a26-7e2da4be6fcc`
227. Phase 2 dashboard followup smoke output sample:
   - `training_request_id=47f0cc0b-5f5a-41fe-90cd-0949e3b5e5f7`
   - `training_record_request_id=ff425007-1034-4851-8ec0-12def25b4305`
   - `dashboard_request_id=d4187c25-387d-4313-b2c4-a047eaa2b513`
228. Final-gate retry recovery sample:
   - `module=assessment`
   - `request_id=c600d981-9dec-48fe-94db-1c8d3e0ef21a`
   - `reason=WORKER_LIMIT`
229. Latest verification timestamp (UTC): `2026-02-27T01:00:20Z`
230. `bash tests/governance/test_phase3_drill_assets_presence.sh` -> PASS.
231. `bash scripts/ci/final_gate.sh` -> PASS.
232. `bash tests/governance/test_docs_presence.sh` -> PASS.
233. `bash tests/governance/test_e2e_governance.sh` -> PASS.
234. Final-gate Phase 3 chain smoke output sample:
   - `assessment_request_id=78c61f66-4f77-4b8d-98d0-b425d6cccc1f`
   - `chat_request_id=ded6c3a3-c1db-4c11-a789-76639a731e2a`
   - `dashboard_request_id=f2e2e9df-7aa7-464f-8615-12c437503890`
   - `idempotency_request_id=94af8c31-fb4d-4124-8f53-0124a332180a`
   - `training_request_id=1e58ee1f-2463-4361-ad35-cf0f7bf25b4b`
   - `training_record_request_id=8ff022d5-022a-468e-bc3c-8cbc49b905c6`
235. Final-gate Phase 2 weekly journey smoke output sample:
   - `assessment_request_id=73c4c492-1ead-4814-8c38-99c2d40c93ef`
   - `training_advice_request_id=33e46daa-889d-4676-a43c-cc35305908cd`
   - `training_request_id=a12ce95c-b492-4cae-84bf-4d6fb2c16317`
   - `training_record_request_id=78a8b144-6258-4822-a144-71f79ed7269b`
   - `dashboard_request_id=78a11041-bdc7-41a1-9914-fbdaecd64fcb`
236. Phase 2 dashboard followup smoke output sample:
   - `training_request_id=9f409a47-2c2c-46ef-8a2a-a3e617b51b3b`
   - `training_record_request_id=85d3dd73-0c64-4b2f-b02d-05c29440a631`
   - `dashboard_request_id=e35b6338-4d58-4b52-88bf-8c316b30de63`
237. Final-gate retry recovery sample:
   - `module=assessment`
   - `request_id=5b0580a3-b7b9-4c8f-bde7-38bf83f07cec`
   - `reason=WORKER_LIMIT`
238. Latest verification timestamp (UTC): `2026-02-27T01:23:32Z`
239. `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS.
240. `DRY_RUN=0 ROLLBACK_MODULE=orchestrator ROLLBACK_DRILL_RUN_FINAL_GATE=1 ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS=1 bash scripts/ops/run_phase2_rollback_drill.sh` -> PASS.
241. Phase 2 rollback drill execution record: `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md` -> `phase2-rollback-drill-001-2026-02-27T23:39:40Z`.
242. Phase 2 rollback drill weekly journey sample:
   - `assessment_request_id=778f585f-107c-466e-b532-5fde7c801a47`
   - `training_advice_request_id=ccf6f01f-af21-4c73-bfc8-233eb00a23ca`
   - `training_request_id=80f36956-2cf8-4ef3-b59b-00bf0dbebc4e`
   - `training_record_request_id=444388c4-498b-46ad-8c9a-7eef19e441a1`
   - `dashboard_request_id=48f70d16-504c-4e0d-8253-8c83611775d5`
243. Phase 2 rollback drill dashboard followup sample:
   - `training_request_id=bd26bf35-9068-4762-b7da-97f7c401cd81`
   - `training_record_request_id=a4b9d8af-dc41-4721-9ea1-48e97beef4ca`
   - `dashboard_request_id=01efed98-8855-4fe9-80cb-52404e08f6d1`
244. `bash tests/governance/test_phase3_drill_assets_presence.sh` -> PASS.
245. `bash tests/governance/test_docs_presence.sh` -> PASS.
246. `bash tests/governance/test_e2e_governance.sh` -> PASS.
247. Phase 3 drill log metadata synced to executed evidence:
   - `docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md` executed_at set to `2026-02-28T00:09:04Z`
   - `docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md` executed_at set to `2026-02-28T00:10:18Z`
248. Latest verification timestamp (UTC): `2026-02-27T23:39:40Z`
249. `DRY_RUN=0 ROLLBACK_MODULE=orchestrator ROLLBACK_DRILL_RUN_FINAL_GATE=1 bash scripts/ops/run_phase2_rollback_drill.sh` -> PASS.
250. Phase 2 rollback drill full-pass timing record: `docs/governance/PHASE-2-ROLLBACK-DRILL-LOG.md` -> `phase2-rollback-drill-001-2026-02-28T15:45:25Z` (`elapsed_seconds=1653`).
251. Phase 2 rollback drill weekly journey sample:
   - `assessment_request_id=66773d22-8e94-4a2e-834e-cab432068458`
   - `training_advice_request_id=217934b3-3524-4e2d-b21e-70078db07f38`
   - `training_request_id=20f885fa-6210-4317-8049-dc84755d8580`
   - `training_record_request_id=de9fb3d7-00c0-4351-a848-37cc379a36a3`
   - `dashboard_request_id=4900a568-8d7c-4e7f-b6c7-7ed1c2f6a743`
252. Phase 2 rollback drill dashboard followup sample:
   - `training_request_id=b6b1571f-0809-4298-b811-bfb82a372336`
   - `training_record_request_id=37469eb2-b4c4-4f7f-bd40-c6ba2aa09428`
   - `dashboard_request_id=48e98da8-df1a-4be6-a607-e65aa860181d`
253. `bash tests/governance/test_docs_presence.sh` -> PASS.
254. `bash tests/governance/test_e2e_governance.sh` -> PASS.
255. Latest verification timestamp (UTC): `2026-02-28T15:45:25Z`

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
- Static contract gate `tests/functions/test_auth_and_body_parse_contract.sh` enforces request authentication, child-access guard, and single-pass `req.json()` body consumption across execution-chain entrypoints.
- Static contract gate `tests/functions/test_orchestrator_forwarding_contract.sh` enforces downstream forwarding URL/auth/payload semantics, idempotency query constraints, and SSE proxy response behavior.
- Static contract gate `tests/functions/test_shared_reliability_contract.sh` enforces shared service-client singleton reuse and RPC-only finalize writeback path (`finalize_writeback`).
- Static contract gate `tests/functions/test_model_router_resilience_contract.sh` enforces provider-pick semantics, dual-provider fallback structure, non-streaming completion config, and doubao model guard behavior.
- Static contract gate `tests/functions/test_error_response_contract.sh` enforces BAD_REQUEST/AUTH_FORBIDDEN/INTERNAL_ERROR SSE semantics and canonical HTTP status mapping across execution-chain functions.
- Static contract gate `tests/functions/test_orchestrator_conversation_bootstrap_contract.sh` enforces conversation auto-create defaults and ingress user-message persistence semantics in orchestrator.
- Static contract gate `tests/functions/test_model_router_temperature_contract.sh` enforces caller-provided temperature semantics in model-router (`options.temperature` honored in Kimi and Doubao paths).
- Static contract gate `tests/functions/test_request_id_lifecycle_contract.sh` enforces module-level request_id inheritance, finalizeWriteback passthrough, and done-event request_id echo semantics.
- Static contract gate `tests/functions/test_options_preflight_contract.sh` enforces canonical `OPTIONS` guard and null preflight SSE-header response semantics across execution-chain functions.
- Static contract gate `tests/functions/test_sse_framing_contract.sh` enforces success-path SSE framing (`stream_start -> delta -> done`) presence and lexical ordering across execution modules.
- Static contract gate `tests/functions/test_writeback_before_done_contract.sh` enforces ordering where `finalizeWriteback` executes before terminal SSE `done` across execution modules.
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
- Live gate `tests/e2e/test_live_smoke_retry_backoff_timing_contract.sh` enforces exponential backoff sleep sequencing and terminal no-sleep boundaries.
- Live gate `tests/e2e/test_live_smoke_retry_transport_failure_contract.sh` enforces `set -e` safe transport retry flow and transport terminal reason `transport_error_exhausted`.
- Live gate `tests/e2e/test_live_smoke_retry_transport_observability_contract.sh` enforces runtime transport retry/terminal stderr log semantics with resolved request_id/attempt/reason fields.
- Live gate `tests/e2e/test_live_smoke_retry_transport_exit_code_contract.sh` enforces transport retry/terminal diagnostics include `exit_code` and terminal `ORCH_LAST_RESPONSE` marker `transport_error_exit_code=<n>`.
- Live gate `tests/e2e/test_phase2_parent_weekly_journey_live.sh` enforces end-to-end parent weekly journey sequencing (`assessment -> training-advice -> training -> training-record -> dashboard`) and request-id lineage.
- Live gate `tests/e2e/test_phase2_parent_dashboard_followup_live.sh` enforces dashboard follow-up consistency from training/training-record context, including `affected_tables` and `snapshot_refresh_events` trace closure.
- Phase 2 follow-up run validated transient `WORKER_LIMIT` recovery through shared retry helper and completed PASS without manual intervention.
- Governance gate `tests/governance/test_phase3_slo_runbook_presence.sh` enforces presence of SLO targets, SLI measurements, alert thresholds, ownership, and operations runbook incident workflow baseline.
- Governance gate `tests/governance/test_phase3_security_ops_presence.sh` enforces secrets rotation, privileged action controls, access review cadence, and security incident response baseline.
- Governance gate `tests/governance/test_phase3_cost_guardrails_presence.sh` enforces budget thresholds, anomaly response, capacity ceilings, and CI enforcement baseline.
- Governance gate `tests/governance/test_phase3_release_automation_presence.sh` enforces canary policy, rollback trigger matrix, approval gates, and automated release verification sequence baseline.
- Governance gate `tests/governance/test_phase3_drill_assets_presence.sh` enforces executable incident/rollback drill scripts, structured drill forms, and cross-doc references.
- `assessments`, `training_plans`, `training_sessions`, `children_profiles`, and `children_memory` domain tables receive live writeback rows.
- Dashboard writeback stores assistant `cards_json` and links trace by same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Operational governance gaps through Phase 3 are tracked as `done` in `docs/governance/GAP-REGISTER.md`.

## 2026-03-01 Deploy and Go-Live Evidence

- Executed `bash scripts/ci/release_go_live.sh` against project ref `innaguwdmdfugrbcoxng` and completed end-to-end with exit code `0`.
- Deployed modules:
  - `orchestrator`
  - `chat-casual`
  - `assessment`
  - `training`
  - `training-advice`
  - `training-record`
  - `dashboard`
- Release gate sequence outcomes:
  - `bash scripts/ci/final_gate.sh` -> PASS
  - `bash tests/governance/test_docs_presence.sh` -> PASS
  - `bash tests/governance/test_e2e_governance.sh` -> PASS
- Live smoke evidence samples from this run:
  - assessment/training chain sample: `assessment_request_id=4a7d850e-7739-4d60-9f43-29d977f9483e`, `training_request_id=6a102172-b167-4755-b48e-07637615ee3e`
  - phase2 dashboard followup sample: `training_request_id=7fd8b31a-49a5-45bd-8945-40c9900c06f9`, `dashboard_request_id=4101a4e2-3c50-4bb6-8910-d829d4ec775d`
  - phase2 weekly journey sample: `assessment_request_id=fdbfda12-f93a-4194-991f-f2b4bd88bf45`, `training_advice_request_id=9246255b-b739-4dde-bed3-1640058d08f5`, `training_request_id=ed803bb4-6097-4a75-b22e-066958284a42`, `training_record_request_id=70fe9d52-8971-42b3-8f72-dbac46d1ef5d`, `dashboard_request_id=e2706b4e-a186-40e4-9d0b-f875c0efb3b4`
- Transient load behavior observed and recovered by retry contract:
  - `module=training`
  - `request_id=c5de9fe0-0ad2-4bb0-9bbc-03038d2fa8e0`
  - `reason=WORKER_LIMIT`
- Latest verification timestamp (UTC): `2026-03-01T03:25:18Z`

## 2026-03-01 Pending Sign-off Controls Evidence

- Added governance gate: `tests/governance/test_phase2_pending_signoff_controls.sh`.
- `bash tests/governance/test_phase2_pending_signoff_controls.sh` -> PASS.
- `bash tests/governance/test_phase2_signoff_and_release_record.sh` -> PASS.
- `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS.
- `bash scripts/ci/final_gate.sh` -> PASS (includes new phase2 pending sign-off control gate).
- Phase2 follow-up smoke sample:
  - `training_request_id=45b146fd-1007-4316-8bb1-b4c38f8fc38a`
  - `training_record_request_id=3042e783-b181-4a4e-91aa-34cafed55b1b`
  - `dashboard_request_id=6b87d644-9344-4e1c-b15e-4e05c5c5dffe`
- Phase2 weekly journey smoke sample:
  - `assessment_request_id=5f0433a0-3b1a-4738-bcd0-777f4c9baa98`
  - `training_advice_request_id=369cd11e-4c85-4597-8808-8757f3b8a4ba`
  - `training_request_id=bd5c3743-9777-46a8-b555-3e8a32e5cb1a`
  - `training_record_request_id=111b7d61-a32d-4b4f-b296-59be3ed4af45`
  - `dashboard_request_id=703690b6-3fd0-43bf-9ff4-d99f7a1e6223`
- Latest verification timestamp (UTC): `2026-03-01T06:31:28Z`

## 2026-03-01 Sign-off Approval Script Evidence

- Added governance utility script: `scripts/governance/approve_phase2_signoff.sh`.
- Added gate: `tests/governance/test_phase2_signoff_approval_script.sh`.
- `bash tests/governance/test_phase2_signoff_approval_script.sh` -> PASS.
- `DRY_RUN=1 ROLE=product APPROVER=product-owner-v1 DATE_UTC=2026-03-01T06:40:00Z bash scripts/governance/approve_phase2_signoff.sh` -> PASS (diff preview mode).
- `bash scripts/ci/final_gate.sh` -> PASS (includes new script gate).
- Final-gate Phase 2 weekly journey smoke sample:
  - `assessment_request_id=e377b6a4-897f-40e1-88c7-06ecdd2b8165`
  - `training_advice_request_id=9e812fb7-a598-46af-967b-60398c546541`
  - `training_request_id=7292282e-6097-45d4-a683-47b125c98c02`
  - `training_record_request_id=a2321f35-ab6d-448c-a934-ccecf37fed24`
  - `dashboard_request_id=d9c1210b-c38f-4e43-89b5-f52cb3b10558`
- Latest verification timestamp (UTC): `2026-03-01T06:49:09Z`

## 2026-03-01 Sign-off Gate Execution Chain Evidence

- Added governance gate script: `scripts/governance/check_phase2_signoff_gate.sh`.
- Added gate test: `tests/governance/test_phase2_signoff_gate_script.sh`.
- Updated release entry script to run sign-off gate first:
  - `scripts/ci/release_go_live.sh` now includes `bash scripts/governance/check_phase2_signoff_gate.sh`.
- Verification outputs:
  - `bash tests/governance/test_phase2_signoff_gate_script.sh` -> PASS.
  - `bash scripts/governance/check_phase2_signoff_gate.sh` -> PASS (`require_full_signoff=0`).
  - `REQUIRE_FULL_SIGNOFF=1 bash scripts/governance/check_phase2_signoff_gate.sh` -> FAIL (expected: `role=product is pending while REQUIRE_FULL_SIGNOFF=1`).
  - `DRY_RUN=1 bash scripts/ci/release_go_live.sh` -> PASS (includes sign-off gate step preview).
  - `bash scripts/ci/final_gate.sh` -> PASS (includes new gate test).
- Final-gate Phase 2 weekly journey smoke sample:
  - `assessment_request_id=46ec6b44-395e-4c8f-be86-4065c171065b`
  - `training_advice_request_id=05f50959-ccee-4737-8560-f02d64432098`
  - `training_request_id=81ab2fa3-cc94-4ec6-a96a-42c06fe2b62b`
  - `training_record_request_id=8bca064f-bc77-4201-852b-f76982b66bc4`
  - `dashboard_request_id=ef44df63-28d6-4f97-9ffe-bb51e976a63a`
- Latest verification timestamp (UTC): `2026-03-01T07:12:29Z`

## 2026-03-01 Full Sign-off Go-Live Evidence

- Applied manual sign-off approvals with approver `叶明君`:
  - `ROLE=operations APPROVER='叶明君' DATE_UTC=2026-03-01T07:49:45Z bash scripts/governance/approve_phase2_signoff.sh`
  - `ROLE=product APPROVER='叶明君' DATE_UTC=2026-03-01T07:56:30Z bash scripts/governance/approve_phase2_signoff.sh`
- `REQUIRE_FULL_SIGNOFF=1 bash scripts/governance/check_phase2_signoff_gate.sh` -> PASS.
- First full-signoff `release_go_live` attempt observed transient idempotency duplicate-completed-log failure; direct repro `bash tests/e2e/test_orchestrator_idempotency_live.sh` then passed.
- Re-run `REQUIRE_FULL_SIGNOFF=1 bash scripts/ci/release_go_live.sh` -> PASS.
- Re-run final-gate weekly journey smoke sample:
  - `assessment_request_id=a115e275-2a20-4a92-90b6-f96926a455d7`
  - `training_advice_request_id=7070cf15-c8c5-448c-ab68-07e8cda0e223`
  - `training_request_id=50a33b31-15c3-4312-b986-6c22318639f0`
  - `training_record_request_id=cec316ac-d594-4903-b572-adeb1344d68a`
  - `dashboard_request_id=5e033164-cf4e-4f03-8c73-da8d643d3d0d`
- Updated release metadata:
  - `docs/governance/PHASE-2-RELEASE-CHECKLIST.md` status -> `fully_approved`.
  - `docs/governance/PHASE-2-RELEASE-RECORD.md` sign-off snapshot -> engineering/product/operations all `approved`.
- Latest verification timestamp (UTC): `2026-03-01T08:05:50Z`

## 2026-03-01 Sign-off Governance Hardening Evidence

- Fixed false-positive regex issue in `tests/governance/test_phase2_pending_signoff_controls.sh` by escaping leading `|` and aligning checks with `fully_approved` state.
- Hardened concurrent sign-off updates in `scripts/governance/approve_phase2_signoff.sh`:
  - Added file lock `.git/approve_phase2_signoff.lock`.
  - Added exclusive lock guard via `flock -x`.
- Updated gate `tests/governance/test_phase2_signoff_approval_script.sh` to require lock usage.
- Verification outputs:
  - `bash tests/governance/test_phase2_signoff_approval_script.sh` -> PASS.
  - `bash tests/governance/test_phase2_pending_signoff_controls.sh` -> PASS.
  - `REQUIRE_FULL_SIGNOFF=1 bash scripts/governance/check_phase2_signoff_gate.sh` -> PASS.
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T08:39:59Z`

## 2026-03-01 Phase3 Drill Sign-off Completion Evidence

- Added phase3 drill sign-off automation script:
  - `scripts/governance/approve_phase3_drill_signoff.sh`
- Added phase3 drill governance gates:
  - `tests/governance/test_phase3_drill_signoff_script.sh`
  - `tests/governance/test_phase3_drill_signoff_completion.sh`
- Signed off drill forms with approver `叶明君`:
  - incident: `engineering`, `operations`, `product operations`
  - rollback: `engineering`, `operations`, `release manager`
- Updated lock strategy for sign-off scripts to support environments without `flock`:
  - `scripts/governance/approve_phase2_signoff.sh`
  - `scripts/governance/approve_phase3_drill_signoff.sh`
  - fallback lock directory: `<lock-file>.d`
- Verification outputs:
  - `bash tests/governance/test_phase3_drill_signoff_script.sh` -> PASS.
  - `bash tests/governance/test_phase3_drill_signoff_completion.sh` -> PASS.
  - `bash tests/governance/test_phase3_drill_assets_presence.sh` -> PASS.
  - `bash scripts/ci/final_gate.sh` -> PASS (includes both new phase3 drill sign-off gates).
- Final-gate Phase2 weekly journey smoke sample:
  - `assessment_request_id=299e21ee-0ee9-4fae-b555-3e3bad9b6967`
  - `training_advice_request_id=46bd94e5-7661-4310-963f-8bba20e17e05`
  - `training_request_id=ff10a579-7fda-40a5-b7dc-cf02d865ca3d`
  - `training_record_request_id=457d8a48-2907-4b41-b9fb-4a9306a74453`
  - `dashboard_request_id=d71f3e04-ce4c-41eb-9dfb-9ab12e610e73`
- Latest verification timestamp (UTC): `2026-03-01T09:02:51Z`

## 2026-03-01 Phase2 Rollback Drill Sign-off Completion Evidence

- Added phase2 rollback drill sign-off automation script:
  - `scripts/governance/approve_phase2_rollback_drill_signoff.sh`
- Added phase2 rollback drill governance gates:
  - `tests/governance/test_phase2_rollback_drill_signoff_script.sh`
  - `tests/governance/test_phase2_rollback_drill_signoff_completion.sh`
- Signed off phase2 rollback drill log with approver `叶明君`:
  - `engineering` -> approved (`2026-03-01T09:08:10Z`)
  - `operations` -> approved (`2026-03-01T09:08:20Z`)
- Verification outputs:
  - `bash tests/governance/test_phase2_rollback_drill_signoff_script.sh` -> PASS.
  - `bash tests/governance/test_phase2_rollback_drill_signoff_completion.sh` -> PASS.
  - `bash tests/governance/test_phase2_release_artifacts.sh` -> PASS.
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
  - `bash scripts/ci/final_gate.sh` -> PASS.
- Final-gate Phase2 weekly journey smoke sample:
  - `assessment_request_id=0a8c6ebd-0805-429d-a806-33710ba8be10`
  - `training_advice_request_id=faa8162b-de34-4def-b6e7-f66d05428785`
  - `training_request_id=a0ebb076-6852-4025-aa6c-b7761ca2fd7b`
  - `training_record_request_id=e2c56c20-360c-4fab-88c0-af2db0062712`
  - `dashboard_request_id=556be1d8-25df-4da0-8565-9c620674e021`
- Latest verification timestamp (UTC): `2026-03-01T09:18:45Z`

## 2026-03-01 Phase3 Drill Sign-off Gate Integration Evidence

- Added phase3 drill sign-off gate script:
  - `scripts/governance/check_phase3_drill_signoff_gate.sh`
- Added governance gate coverage:
  - `tests/governance/test_phase3_drill_signoff_gate_script.sh`
- Updated release go-live sequence:
  - `scripts/ci/release_go_live.sh` now runs `bash scripts/governance/check_phase3_drill_signoff_gate.sh` before deploy.
- Updated CI release script contract:
  - `tests/ci/test_deploy_release_scripts_presence.sh` now requires phase3 drill signoff gate step.
- Verification outputs:
  - `bash tests/ci/test_deploy_release_scripts_presence.sh` -> PASS.
  - `bash tests/governance/test_phase3_drill_signoff_gate_script.sh` -> PASS.
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
  - `bash scripts/ci/final_gate.sh` -> PASS (includes new phase3 drill signoff gate script test).
- Final-gate Phase2 weekly journey smoke sample:
  - `assessment_request_id=d1bc4a0c-f3cc-4155-9dbc-548bf95aa1aa`
  - `training_advice_request_id=4ee2adb4-2a87-4444-95da-bcdb0cad327f`
  - `training_request_id=25406a48-cd23-4434-abce-511781f2c7f5`
  - `training_record_request_id=26f2e8a7-c0e7-41f4-8a0e-8f895bbe2c76`
  - `dashboard_request_id=1aca935c-5e17-451e-a8a7-05e2872dcbbb`
- Latest verification timestamp (UTC): `2026-03-01T12:18:58Z`

## 2026-03-01 Phase3 Gate Runbook Sync Evidence

- Updated governance docs to reflect phase3 drill signoff gate in release flows:
  - `docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md`
  - `docs/governance/PHASE-3-RELEASE-AUTOMATION.md`
- Added documentation contract coverage:
  - `tests/governance/test_docs_presence.sh` now requires runbook reference to `scripts/governance/check_phase3_drill_signoff_gate.sh`.
  - `tests/governance/test_phase3_release_automation_presence.sh` now requires the same command in automated verification sequence.
- Verification outputs:
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_phase3_release_automation_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T12:20:38Z`

## 2026-03-01 Strict Release Sign-off Default Evidence

- Hardened release policy in `scripts/ci/release_go_live.sh`:
  - default `REQUIRE_FULL_SIGNOFF=1`
  - default `REQUIRE_PHASE3_DRILL_SIGNOFF=1`
  - explicit env passthrough to both governance gate commands
- Added/updated gate coverage:
  - `tests/ci/test_deploy_release_scripts_presence.sh` now requires `REQUIRE_FULL_SIGNOFF` handling in release script.
  - `tests/governance/test_phase2_signoff_gate_script.sh` now requires strict default declaration.
- Synced governance docs with strict-default behavior:
  - `docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md`
  - `docs/governance/PHASE-3-RELEASE-AUTOMATION.md`
- Verification outputs:
  - `DRY_RUN=1 bash scripts/ci/release_go_live.sh` -> PASS.
  - `bash tests/ci/test_deploy_release_scripts_presence.sh` -> PASS.
  - `bash tests/governance/test_phase2_signoff_gate_script.sh` -> PASS.
  - `bash tests/governance/test_phase3_release_automation_presence.sh` -> PASS.
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T12:22:38Z`

## 2026-03-01 Final Gate Re-run Stability Evidence

- First `bash scripts/ci/final_gate.sh` run failed at `tests/e2e/test_orchestrator_idempotency_live.sh` under transient network instability:
  - observed transport errors: `curl: (6) Could not resolve host: innaguwdmdfugrbcoxng.supabase.co`
  - observed timeout: `curl: (28) Operation timed out ...`
  - observed duplicate completion under the same request id:
    - `request_id=804ba53d-56af-47f9-9f1f-5541bf68c377`
- Reproduction check:
  - direct rerun `bash tests/e2e/test_orchestrator_idempotency_live.sh` -> PASS.
  - sample pass request id: `request_id=9c98ea19-82c1-46d2-a6ff-aa5a6540efe8`.
- Confirmation full rerun:
  - re-run `bash scripts/ci/final_gate.sh` -> PASS (exit code 0).
  - final-gate weekly journey smoke sample:
    - `assessment_request_id=02d9632a-ff5e-4857-9bce-0a57c1e6e6c6`
    - `training_advice_request_id=d0a05da3-ea17-484b-b77f-0ac62ac47b96`
    - `training_request_id=796625b2-64de-455a-951e-bfd5e3419647`
    - `training_record_request_id=67fc8d23-1da7-4b4f-99b6-42e50d725bc7`
    - `dashboard_request_id=8d709c08-1f5e-4154-9461-ce5608db424b`
- Latest verification timestamp (UTC): `2026-03-01T13:59:43Z`

## 2026-03-01 Strict Go-live Execution Evidence

- Executed real release flow with strict sign-off defaults:
  - `bash scripts/ci/release_go_live.sh` -> PASS.
- Release run milestones:
  - phase2 sign-off gate pass (`require_full_signoff=1`).
  - phase3 drill sign-off gate pass (`require_phase3_drill_signoff=1`).
  - deployed modules: `orchestrator`, `chat-casual`, `assessment`, `training`, `training-advice`, `training-record`, `dashboard`.
  - embedded post-deploy verification gates all PASS (`final_gate`, `test_docs_presence`, `test_e2e_governance`).
- Release-run weekly journey smoke sample:
  - `assessment_request_id=fab7af8e-8792-4a3f-8800-d2162dfa4e3c`
  - `training_advice_request_id=1aa86e6a-aa5d-4209-9d46-f8baa8d3a886`
  - `training_request_id=1df9485e-2ac0-478e-a029-9abffccd11f9`
  - `training_record_request_id=405a3855-220f-482a-b7f6-7fdef58948fb`
  - `dashboard_request_id=c90bf8e8-2a29-47a5-acf0-ac213e8b7b5c`
- Updated release record:
  - `docs/governance/PHASE-2-RELEASE-RECORD.md` (`commit_sha=a8adaa804883`, `executed_at_utc=2026-03-01T14:24:16Z`).
- Latest verification timestamp (UTC): `2026-03-01T14:24:16Z`

## 2026-03-01 Supabase CLI Version Governance Evidence

- Added shared CLI version governance script:
  - `scripts/ci/check_supabase_cli_version.sh`
- Integrated CLI version check into execution entry points:
  - `scripts/db/preflight.sh`
  - `scripts/ci/deploy_functions.sh`
  - `scripts/ci/release_go_live.sh`
- Added CI gate coverage:
  - `tests/ci/test_supabase_cli_check_script.sh` (script contract + preflight integration)
  - `tests/ci/test_deploy_release_scripts_presence.sh` (deploy/release integration)
  - `tests/ci/test_supabase_cli_version_pinned.sh` (workflow pin and script default-version consistency)
- Synced governance docs:
  - `docs/governance/DEPLOY-TEST-GO-LIVE-RUNBOOK.md`
  - `docs/governance/PHASE-3-RELEASE-AUTOMATION.md`
- Verification outputs:
  - `bash scripts/ci/check_supabase_cli_version.sh` -> PASS (warn-only mismatch observed on local `2.47.2` vs expected `2.75.0`).
  - `bash tests/ci/test_deploy_release_scripts_presence.sh` -> PASS.
  - `bash tests/ci/test_supabase_cli_check_script.sh` -> PASS.
  - `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
  - `bash tests/governance/test_docs_presence.sh` -> PASS.
  - `bash tests/governance/test_phase3_release_automation_presence.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
  - `DRY_RUN=1 bash scripts/ci/release_go_live.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T14:31:29Z`

## 2026-03-01 CI CLI Version Enforcement Evidence

- Updated CI workflow to enforce CLI version governance before execution:
  - `.github/workflows/db-rebuild-and-chain-smoke.yml`
  - new step: `ENFORCE_SUPABASE_CLI_VERSION=1 bash scripts/ci/check_supabase_cli_version.sh`
- Extended workflow contract gate:
  - `tests/ci/test_workflow_presence.sh` now requires both `check_supabase_cli_version.sh` and `ENFORCE_SUPABASE_CLI_VERSION=1` patterns.
- Verification outputs:
  - `bash tests/ci/test_workflow_presence.sh` -> PASS.
  - `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T14:32:51Z`

## 2026-03-01 Workflow Deploy Script Reuse Evidence

- Removed duplicated module deploy commands from workflow and reused shared deploy script:
  - `.github/workflows/db-rebuild-and-chain-smoke.yml`
  - deploy step now runs: `bash scripts/ci/deploy_functions.sh`
- Updated workflow contract gate:
  - `tests/ci/test_workflow_presence.sh` now requires `bash scripts/ci/deploy_functions.sh`.
- Verification outputs:
  - `bash tests/ci/test_workflow_presence.sh` -> PASS.
  - `bash tests/ci/test_deploy_release_scripts_presence.sh` -> PASS.
  - `bash tests/ci/test_supabase_cli_version_pinned.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T14:34:32Z`

## 2026-03-01 CI Governance Consolidation Final Gate Evidence

- Ran full gate after CI governance consolidation commits (`be1bec5`, `845e41b`, `481bfbd`):
  - `bash scripts/ci/final_gate.sh` -> PASS (exit code 0).
- CI gate segment confirmation from final-gate run:
  - `tests/ci/test_deploy_release_scripts_presence.sh` -> PASS
  - `tests/ci/test_final_gate_script.sh` -> PASS
  - `tests/ci/test_supabase_cli_check_script.sh` -> PASS
  - `tests/ci/test_supabase_cli_version_pinned.sh` -> PASS
  - `tests/ci/test_workflow_presence.sh` -> PASS
- Final-gate weekly journey smoke sample:
  - `assessment_request_id=bab4a31a-ec84-4841-bf7a-7ffca0786bbc`
  - `training_advice_request_id=4ae97f46-bff0-4fb1-aa5a-c99f30b9ccb8`
  - `training_request_id=feb78d11-7f51-413c-b8c3-9e3e3449eee3`
  - `training_record_request_id=cc6af49c-c084-449b-8775-47ca5444371e`
  - `dashboard_request_id=f66dfa10-bef1-4563-84e0-698020b39f16`
- Latest verification timestamp (UTC): `2026-03-01T14:44:29Z`

## 2026-03-01 Preflight DB Password Contract Evidence

- Added DB preflight contract gate:
  - `tests/db/test_00_preflight_contract.sh`
- Hardened required key loop in `scripts/db/preflight.sh`:
  - now enforces `SUPABASE_DB_PASSWORD` alongside existing required keys.
- Verification outputs:
  - `bash tests/db/test_00_preflight_contract.sh` -> PASS.
  - `bash tests/db/test_00_preflight.sh` -> PASS.
  - `bash tests/governance/test_e2e_governance.sh` -> PASS.
- Latest verification timestamp (UTC): `2026-03-01T14:46:25Z`
