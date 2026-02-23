#!/usr/bin/env bash
set -euo pipefail

test -f governance/agent-contract/source/contract.yaml
grep -q "evidence_before_claim" governance/agent-contract/source/contract.yaml
test -f governance/agent-contract/mapping/codex.map.yaml
test -f governance/agent-contract/templates/agents.md.tmpl
echo "seed contract files exist"
