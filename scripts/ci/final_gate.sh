#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export PATH="$REPO_ROOT/scripts/bin:$PATH"

bash governance/agent-contract/scripts/build-contract.sh
bash governance/agent-contract/scripts/verify-contract.sh

for t in tests/governance/test_phase*_*.sh; do
  [ -f "$t" ] || continue
  echo "running $t"
  bash "$t"
done

for t in tests/db/*.sh tests/functions/*.sh tests/e2e/*.sh tests/ci/*.sh; do
  echo "running $t"
  bash "$t"
done
