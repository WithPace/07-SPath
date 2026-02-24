#!/usr/bin/env bash
set -euo pipefail

f="scripts/db/rebuild_remote.sh"
test -f "$f"
grep -q "ALLOW_DESTRUCTIVE_REBUILD" "$f"
grep -q "ALLOWED_PROJECT_REFS" "$f"
grep -q "refuse destructive rebuild" "$f"
grep -q "pg_dump" "$f"
if grep -q "supabase db dump --linked" "$f"; then
  echo "rebuild should not depend on supabase db dump docker path" >&2
  exit 1
fi

dumper="scripts/db/dump_schema.sh"
test -f "$dumper"
grep -q "pg_dump" "$dumper"
if grep -q "supabase db dump --linked" "$dumper"; then
  echo "schema dump script should not depend on supabase db dump docker path" >&2
  exit 1
fi
echo "rebuild safety guard present"
