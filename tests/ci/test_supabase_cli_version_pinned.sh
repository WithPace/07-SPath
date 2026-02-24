#!/usr/bin/env bash
set -euo pipefail

f=".github/workflows/db-rebuild-and-chain-smoke.yml"
test -f "$f"
grep -q "version: 2.75.0" "$f"
if grep -q "version: latest" "$f"; then
  echo "supabase cli version must be pinned, not latest" >&2
  exit 1
fi
echo "supabase cli version pinned"
