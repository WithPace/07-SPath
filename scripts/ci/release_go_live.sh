#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"

run_cmd() {
  local cmd="$1"
  if [ "$DRY_RUN" = "1" ]; then
    echo "[DRY_RUN] ${cmd}"
    return 0
  fi

  echo "[RUN] ${cmd}"
  eval "$cmd"
}

echo "== go-live sequence start =="
run_cmd "bash scripts/governance/check_phase2_signoff_gate.sh"
run_cmd "bash scripts/ci/deploy_functions.sh"
run_cmd "bash scripts/ci/final_gate.sh"
run_cmd "bash tests/governance/test_docs_presence.sh"
run_cmd "bash tests/governance/test_e2e_governance.sh"
echo "== go-live sequence complete =="
