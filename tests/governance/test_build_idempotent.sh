#!/usr/bin/env bash
set -euo pipefail

tmp1=$(mktemp)
tmp2=$(mktemp)
trap 'rm -f "$tmp1" "$tmp2"' EXIT

bash governance/agent-contract/scripts/build-contract.sh >/dev/null
cp governance/agent-contract/contract.lock.json "$tmp1"

sleep 1

bash governance/agent-contract/scripts/build-contract.sh >/dev/null
cp governance/agent-contract/contract.lock.json "$tmp2"

if ! cmp -s "$tmp1" "$tmp2"; then
  echo "contract build is not idempotent" >&2
  diff -u "$tmp1" "$tmp2" || true
  exit 1
fi

echo "contract build idempotent"
