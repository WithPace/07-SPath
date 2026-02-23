#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "missing .env" >&2
  exit 1
fi

for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY DOUBAO_API_KEY KIMI_API_KEY; do
  if ! grep -q "^${key}=" .env; then
    echo "missing key in .env: ${key}" >&2
    exit 1
  fi
done

if [ ! -f supabase/config.toml ]; then
  supabase init
fi

project_ref="${SUPABASE_PROJECT_REF:-}"
if [ -z "$project_ref" ]; then
  project_ref=$(awk -F= '$1=="SUPABASE_URL"{print $2}' .env | sed -E 's#https?://([^.]+)\..*#\1#')
fi

echo "project_ref=${project_ref}"

# Optional remote project link (disabled by default to avoid interactive prompts)
if [ "${SUPABASE_LINK:-0}" = "1" ] && [ -n "$project_ref" ]; then
  if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
    supabase link --project-ref "$project_ref" --password "$SUPABASE_DB_PASSWORD"
  else
    supabase link --project-ref "$project_ref"
  fi
else
  echo "skip supabase link (set SUPABASE_LINK=1 to enable)"
fi
