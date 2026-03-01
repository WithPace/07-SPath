#!/usr/bin/env bash
set -euo pipefail

f=".github/workflows/db-rebuild-and-chain-smoke.yml"
cli_check_script="scripts/ci/check_supabase_cli_version.sh"
test -f "$f"

workflow_version="$(sed -nE 's/^[[:space:]]*version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)$/\1/p' "$f" | head -n 1)"
[ -n "$workflow_version" ] || {
  echo "unable to parse pinned supabase cli version from workflow" >&2
  exit 1
}

grep -q "version: ${workflow_version}" "$f"
if grep -q "version: latest" "$f"; then
  echo "supabase cli version must be pinned, not latest" >&2
  exit 1
fi

test -f "$cli_check_script"
grep -F -q "SUPABASE_CLI_EXPECTED_VERSION=\"\${SUPABASE_CLI_EXPECTED_VERSION:-${workflow_version}}\"" "$cli_check_script" || {
  echo "cli check script expected version must match workflow pin (${workflow_version})" >&2
  exit 1
}

echo "supabase cli version pinned"
