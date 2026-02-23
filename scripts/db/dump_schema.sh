#!/usr/bin/env bash
set -euo pipefail

migration_file="supabase/migrations/20260223170000_rebuild_all.sql"
output_file="/tmp/starpath_schema.sql"

if [ ! -f "$migration_file" ]; then
  echo "missing migration file: $migration_file" >&2
  exit 1
fi

if [ "${USE_REMOTE_DUMP:-0}" = "1" ]; then
  supabase db dump --linked --schema public -f "$output_file"
else
  cp "$migration_file" "$output_file"
fi

echo "schema dumped to $output_file"
