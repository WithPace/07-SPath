#!/usr/bin/env bash
set -euo pipefail

# Ensure linked project or try linking from SUPABASE_URL-derived ref.
if [ ! -f .env ]; then
  echo "missing .env" >&2
  exit 1
fi

project_ref="${SUPABASE_PROJECT_REF:-}"
if [ -z "$project_ref" ]; then
  project_ref=$(awk -F= '$1=="SUPABASE_URL"{print $2}' .env | sed -E 's#https?://([^.]+)\..*#\1#')
fi

if [ -n "$project_ref" ]; then
  if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
    supabase link --project-ref "$project_ref" --password "$SUPABASE_DB_PASSWORD" --yes
  else
    supabase link --project-ref "$project_ref" --yes
  fi
fi

if [ -n "${SUPABASE_DB_PASSWORD:-}" ]; then
  supabase db push --linked --include-all --password "$SUPABASE_DB_PASSWORD"
  if ! supabase db dump --linked --schema public -f /tmp/starpath_schema.sql --password "$SUPABASE_DB_PASSWORD"; then
    cp supabase/migrations/20260223170000_rebuild_all.sql /tmp/starpath_schema.sql
    echo "fallback schema snapshot written from migration file"
  fi
else
  supabase db push --linked --include-all
  if ! supabase db dump --linked --schema public -f /tmp/starpath_schema.sql; then
    cp supabase/migrations/20260223170000_rebuild_all.sql /tmp/starpath_schema.sql
    echo "fallback schema snapshot written from migration file"
  fi
fi
