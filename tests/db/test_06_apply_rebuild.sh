#!/usr/bin/env bash
set -euo pipefail

project_ref="${SUPABASE_PROJECT_REF:-}"
if [ -z "$project_ref" ] && [ -f .env ]; then
  project_ref=$(awk -F= '$1=="SUPABASE_URL"{print $2}' .env | sed -E 's#https?://([^.]+)\..*#\1#')
fi

if [ -z "$project_ref" ]; then
  echo "unable to derive project_ref for safety guard" >&2
  exit 1
fi

export ALLOW_DESTRUCTIVE_REBUILD=1
export ALLOWED_PROJECT_REFS="$project_ref"

bash scripts/db/rebuild_remote.sh
echo "remote rebuild done"
