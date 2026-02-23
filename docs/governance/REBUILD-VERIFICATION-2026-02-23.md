# Rebuild Verification (2026-02-23)

## Scope

- Supabase linked project destructive rebuild applied via migration.
- Runtime chain verified: `orchestrator -> chat-casual -> finalize_writeback`.
- Live assertions include `chat_messages`, `operation_logs`, `snapshot_refresh_events`, and `conversations`.

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
6. `/tmp/final_gate.sh` -> PASS (`governance + db + functions + e2e + ci` full sweep).
7. Smoke run output sample:
   - `request_id=2a66dca7-55c1-4e20-ad3a-2bcb7b243305`
   - `user_id=94d775e1-ac7b-4cdb-a061-4590c89fb1b9`
   - `child_id=a8bff8a7-fd94-4596-992f-6e7701700828`
8. Final sweep smoke output sample:
   - `request_id=2a03ced1-1b23-4df7-bb12-aa973463383a`
   - `user_id=12317b89-39a7-473b-a82d-65e27050b862`
   - `child_id=1afb3f43-9b98-40e1-80c6-21e61a8fb779`
9. `bash tests/governance/test_build_idempotent.sh` -> PASS.
10. Latest verification timestamp (UTC): `2026-02-23T15:47:26Z`

## Assertions Confirmed

- `orchestrator` returns SSE `event: done`.
- One or more `user` and `assistant` messages persisted for the same child/user.
- `operation_logs` contains `action_name=chat_casual_reply` with same `request_id`.
- `snapshot_refresh_events` contains row for same `request_id`.
- Conversation header sync works (`message_count >= 2`).

## Remaining Gaps

- No blocking gaps for rebuild + execution chain baseline.
- Known local constraint: `supabase db dump` requires Docker; current scripts already apply migration fallback when Docker is unavailable.
