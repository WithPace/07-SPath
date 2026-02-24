#!/usr/bin/env bash
set -euo pipefail
bash governance/agent-contract/scripts/build-contract.sh
grep -q "Module Contracts (4)" governance/agent-contract/generated/AGENTS.generated.md
grep -q '`orchestrator`' governance/agent-contract/generated/AGENTS.generated.md
grep -q '`assessment`' governance/agent-contract/generated/AGENTS.generated.md
grep -q '`training`' governance/agent-contract/generated/AGENTS.generated.md
grep -q '`dashboard`' governance/agent-contract/generated/AGENTS.generated.md
echo "build includes modules"
