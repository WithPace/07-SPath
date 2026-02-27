#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-1}"
LOG_FILE="${LOG_FILE:-docs/governance/PHASE-3-INCIDENT-DRILL-LOG.md}"
DRILL_ID="${DRILL_ID:-phase3-incident-drill-001}"
STARTED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

run_cmd() {
  local cmd="$1"
  if [ "$DRY_RUN" = "1" ]; then
    echo "[dry-run] $cmd"
    return 0
  fi
  echo "[run] $cmd"
  eval "$cmd"
}

if [ ! -f "$LOG_FILE" ]; then
  echo "missing drill log form: $LOG_FILE" >&2
  exit 1
fi

results=()
commands=(
  "bash tests/governance/test_phase3_slo_runbook_presence.sh"
  "bash tests/governance/test_phase3_security_ops_presence.sh"
  "bash tests/governance/test_phase3_cost_guardrails_presence.sh"
  "bash tests/governance/test_phase3_release_automation_presence.sh"
  "bash tests/governance/test_docs_presence.sh"
  "bash tests/governance/test_e2e_governance.sh"
)

for cmd in "${commands[@]}"; do
  if run_cmd "$cmd"; then
    results+=("| \`$cmd\` | PASS |")
  else
    results+=("| \`$cmd\` | FAIL |")
    break
  fi
done

{
  echo ""
  echo "## Execution Record: ${DRILL_ID}-${STARTED_AT_UTC}"
  echo ""
  echo "| field | value |"
  echo "|---|---|"
  echo "| drill_id | ${DRILL_ID} |"
  echo "| started_at_utc | ${STARTED_AT_UTC} |"
  echo "| dry_run | ${DRY_RUN} |"
  echo ""
  echo "### Command Results"
  echo ""
  echo "| command | result |"
  echo "|---|---|"
  for row in "${results[@]}"; do
    echo "$row"
  done
} >> "$LOG_FILE"

echo "phase3 incident drill run complete"
echo "log_file=${LOG_FILE}"
