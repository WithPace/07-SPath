#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
grep -qi "alter table public.chat_messages enable row level security" /tmp/starpath_schema.sql
grep -qi "alter table public.conversations enable row level security" /tmp/starpath_schema.sql
grep -qi "create policy" /tmp/starpath_schema.sql
grep -qi "to_user_id" /tmp/starpath_schema.sql
echo "rls policy baseline exists"
