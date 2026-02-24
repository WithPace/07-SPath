#!/usr/bin/env bash
set -euo pipefail

# Ensure linked project or try linking from SUPABASE_URL-derived ref.
if [ ! -f .env ]; then
  echo "missing .env" >&2
  exit 1
fi

read_env_or_file() {
  local key="$1"
  local default_value="${2:-}"
  local value="${!key:-}"
  if [ -z "$value" ] && [ -f .env ]; then
    value=$(awk -F= -v k="$key" '$1==k{print substr($0, index($0, "=") + 1)}' .env | tail -n 1)
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
  fi
  if [ -z "$value" ]; then
    value="$default_value"
  fi
  echo "$value"
}

resolve_pg_dump_bin() {
  if [ -n "${PG_DUMP_BIN:-}" ] && [ -x "${PG_DUMP_BIN}" ]; then
    echo "${PG_DUMP_BIN}"
    return 0
  fi

  for candidate in \
    /opt/homebrew/opt/postgresql@17/bin/pg_dump \
    /usr/local/opt/postgresql@17/bin/pg_dump
  do
    if [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done

  if command -v pg_dump >/dev/null 2>&1; then
    command -v pg_dump
    return 0
  fi

  return 1
}

project_ref="$(read_env_or_file SUPABASE_PROJECT_REF)"
if [ -z "$project_ref" ]; then
  project_ref=$(awk -F= '$1=="SUPABASE_URL"{print $2}' .env | sed -E 's#https?://([^.]+)\..*#\1#')
fi

if [ "${ALLOW_DESTRUCTIVE_REBUILD:-0}" != "1" ]; then
  echo "refuse destructive rebuild: set ALLOW_DESTRUCTIVE_REBUILD=1" >&2
  exit 1
fi

allowed_refs="${ALLOWED_PROJECT_REFS:-}"
if [ -z "$allowed_refs" ]; then
  echo "refuse destructive rebuild: missing ALLOWED_PROJECT_REFS allowlist" >&2
  exit 1
fi

if ! echo ",${allowed_refs}," | grep -q ",${project_ref},"; then
  echo "refuse destructive rebuild: project_ref '${project_ref}' not in ALLOWED_PROJECT_REFS" >&2
  exit 1
fi

if [ -n "$project_ref" ]; then
  db_password="$(read_env_or_file SUPABASE_DB_PASSWORD)"
  if [ -n "$db_password" ]; then
    supabase link --project-ref "$project_ref" --password "$db_password" --yes
  else
    supabase link --project-ref "$project_ref" --yes
  fi
fi

dump_remote_schema_with_pg_dump() {
  local out_file="$1"
  local db_password="$2"
  local db_host="$3"
  local db_port="$4"
  local db_user="$5"
  local db_name="$6"
  local pg_dump_bin

  pg_dump_bin="$(resolve_pg_dump_bin || true)"
  if [ -z "$pg_dump_bin" ]; then
    echo "pg_dump is not installed; skip remote schema dump" >&2
    return 1
  fi

  if [ -z "$db_password" ] || [ -z "$db_host" ] || [ -z "$db_user" ] || [ -z "$db_name" ]; then
    echo "missing db connection fields for pg_dump; skip remote schema dump" >&2
    return 1
  fi

  PGPASSWORD="$db_password" PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-15}" "$pg_dump_bin" \
    --host="$db_host" \
    --port="$db_port" \
    --username="$db_user" \
    --dbname="$db_name" \
    --schema=public \
    --schema-only \
    --no-owner \
    --no-privileges \
    --no-comments \
    --file="$out_file" \
    --no-password
}

db_password="$(read_env_or_file SUPABASE_DB_PASSWORD)"
db_host="$(read_env_or_file SUPABASE_DB_HOST)"
db_port="$(read_env_or_file SUPABASE_DB_PORT "5432")"
db_user="$(read_env_or_file SUPABASE_DB_USER "postgres")"
db_name="$(read_env_or_file SUPABASE_DB_NAME "postgres")"
if [ -z "$db_host" ] && [ -n "$project_ref" ]; then
  db_host="db.${project_ref}.supabase.co"
fi

if [ -n "$db_password" ]; then
  supabase db push --linked --include-all --password "$db_password"
else
  supabase db push --linked --include-all
fi

if ! dump_remote_schema_with_pg_dump /tmp/starpath_schema.sql "$db_password" "$db_host" "$db_port" "$db_user" "$db_name"; then
  cp supabase/migrations/20260223170000_rebuild_all.sql /tmp/starpath_schema.sql
  echo "fallback schema snapshot written from migration file"
fi
