#!/usr/bin/env bash
set -euo pipefail

f="scripts/db/rebuild_remote.sh"
test -f "$f"
grep -q "ALLOW_DESTRUCTIVE_REBUILD" "$f"
grep -q "ALLOWED_PROJECT_REFS" "$f"
grep -q "refuse destructive rebuild" "$f"
echo "rebuild safety guard present"
