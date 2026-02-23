#!/usr/bin/env bash
set -euo pipefail
python3 governance/agent-contract/scripts/validate_contract.py
echo "schema validation passed"
