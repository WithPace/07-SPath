#!/usr/bin/env bash
set -euo pipefail

migration_file="supabase/migrations/20260223170000_rebuild_all.sql"
output_file="/tmp/starpath_schema.sql"

if [ ! -f "$migration_file" ]; then
  echo "missing migration file: $migration_file" >&2
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

dump_remote_schema_with_pg_dump() {
  local out_file="$1"
  local project_ref db_password db_host db_port db_user db_name

  if ! command -v pg_dump >/dev/null 2>&1; then
    echo "pg_dump is not installed; skip remote schema dump" >&2
    return 1
  fi

  project_ref="$(read_env_or_file SUPABASE_PROJECT_REF)"
  if [ -z "$project_ref" ] && [ -f .env ]; then
    project_ref=$(awk -F= '$1=="SUPABASE_URL"{print $2}' .env | sed -E 's#https?://([^.]+)\..*#\1#')
  fi

  db_password="$(read_env_or_file SUPABASE_DB_PASSWORD)"
  db_host="$(read_env_or_file SUPABASE_DB_HOST)"
  db_port="$(read_env_or_file SUPABASE_DB_PORT "5432")"
  db_user="$(read_env_or_file SUPABASE_DB_USER "postgres")"
  db_name="$(read_env_or_file SUPABASE_DB_NAME "postgres")"
  if [ -z "$db_host" ] && [ -n "$project_ref" ]; then
    db_host="db.${project_ref}.supabase.co"
  fi

  if [ -z "$db_password" ] || [ -z "$db_host" ]; then
    echo "missing db connection fields for pg_dump; skip remote schema dump" >&2
    return 1
  fi

  PGPASSWORD="$db_password" PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-15}" pg_dump \
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

if [ "${USE_REMOTE_DUMP:-0}" = "1" ]; then
  if ! dump_remote_schema_with_pg_dump "$output_file"; then
    cp "$migration_file" "$output_file"
    echo "fallback schema snapshot written from migration file"
  fi
else
  cp "$migration_file" "$output_file"
fi

echo "schema dumped to $output_file"
