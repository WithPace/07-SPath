#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
grep -qi "create function public.finalize_writeback" /tmp/starpath_schema.sql
grep -qi "create function public.sync_conversation_after_message" /tmp/starpath_schema.sql
grep -qi "create trigger trg_chat_message_update_conversation" /tmp/starpath_schema.sql
echo "outbox rpc and trigger present"
