#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
USE_API="${USE_API:-1}"
VERIFY_JWT="${VERIFY_JWT:-0}"

if [ -z "$SUPABASE_PROJECT_REF" ]; then
  if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
    SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
  fi
fi

if [ -z "$SUPABASE_PROJECT_REF" ]; then
  echo "missing SUPABASE_PROJECT_REF (set env or .env)" >&2
  exit 1
fi

build_flags() {
  local flags=""
  if [ "$USE_API" = "1" ]; then
    flags="${flags} --use-api"
  fi
  if [ "$VERIFY_JWT" = "0" ]; then
    flags="${flags} --no-verify-jwt"
  fi
  printf "%s" "$flags"
}

run_cmd() {
  local cmd="$1"
  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY_RUN] ${cmd}"
    return 0
  fi

  echo "[RUN] ${cmd}"
  eval "$cmd"
}

EXTRA_FLAGS="$(build_flags)"

run_cmd "bash scripts/ci/check_supabase_cli_version.sh"
run_cmd "supabase functions deploy orchestrator --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy chat-casual --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy assessment --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy training --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy training-advice --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy training-record --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy dashboard --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"
run_cmd "supabase functions deploy sms-hook --project-ref ${SUPABASE_PROJECT_REF}${EXTRA_FLAGS}"

echo "deploy complete: project_ref=${SUPABASE_PROJECT_REF}"
