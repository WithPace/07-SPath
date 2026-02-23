#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/verify-contract.sh
echo "verification passed"
