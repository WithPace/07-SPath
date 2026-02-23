#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/dump_schema.sh
for t in admin_users push_tasks child_snapshots users conversations chat_messages operation_logs snapshot_refresh_events; do
  grep -qi "create table public.${t}" /tmp/starpath_schema.sql
done

count=$(grep -Eic '^create table public\.' /tmp/starpath_schema.sql)
[ "$count" -eq 31 ]

echo "full table set exists in dump"
