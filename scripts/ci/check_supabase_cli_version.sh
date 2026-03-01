#!/usr/bin/env bash
set -euo pipefail

SUPABASE_CLI_EXPECTED_VERSION="${SUPABASE_CLI_EXPECTED_VERSION:-2.75.0}"
ENFORCE_SUPABASE_CLI_VERSION="${ENFORCE_SUPABASE_CLI_VERSION:-0}"

fail() {
  echo "$1" >&2
  exit 1
}

case "$ENFORCE_SUPABASE_CLI_VERSION" in
  0|1) ;;
  *)
    fail "ENFORCE_SUPABASE_CLI_VERSION must be 0 or 1"
    ;;
esac

if ! command -v supabase >/dev/null 2>&1; then
  fail "supabase cli not installed"
fi

raw_version="$(supabase --version | head -n 1 | tr -d '\r')"
current_version="$(echo "$raw_version" | sed -nE 's/.*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')"
[ -n "$current_version" ] || fail "unable to parse supabase version from: ${raw_version}"

if [ "$current_version" = "$SUPABASE_CLI_EXPECTED_VERSION" ]; then
  echo "supabase cli version ok: ${current_version}"
  exit 0
fi

message="must update supabase cli: expected=${SUPABASE_CLI_EXPECTED_VERSION} current=${current_version}"
if [ "$ENFORCE_SUPABASE_CLI_VERSION" = "1" ]; then
  fail "$message"
fi

echo "WARN: ${message}" >&2
