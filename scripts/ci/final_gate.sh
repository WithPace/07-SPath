#!/usr/bin/env bash
set -euo pipefail

bash governance/agent-contract/scripts/build-contract.sh
bash governance/agent-contract/scripts/verify-contract.sh

for t in tests/db/*.sh tests/functions/*.sh tests/e2e/*.sh tests/ci/*.sh; do
  echo "running $t"
  bash "$t"
done
