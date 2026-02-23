#!/usr/bin/env bash
set -euo pipefail

python3 governance/agent-contract/scripts/validate_contract.py
python3 governance/agent-contract/scripts/build_contract.py

mkdir -p .cursor/rules
cp governance/agent-contract/generated/AGENTS.generated.md AGENTS.md
cp governance/agent-contract/generated/CLAUDE.generated.md CLAUDE.md
cp governance/agent-contract/generated/cursor.generated.mdc .cursor/rules/starpath-contract.mdc
