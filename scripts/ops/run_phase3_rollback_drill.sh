#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-1}"
LOG_FILE="${LOG_FILE:-docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md}"
DRILL_ID="${DRILL_ID:-phase3-rollback-drill-001}"
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
  "bash tests/e2e/test_phase2_parent_weekly_journey_live.sh"
  "bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh"
  "bash scripts/ci/final_gate.sh"
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

echo "phase3 rollback drill run complete"
echo "log_file=${LOG_FILE}"
