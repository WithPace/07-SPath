#!/usr/bin/env bash
set -euo pipefail

DRY_RUN="${DRY_RUN:-1}"
LOG_FILE="${LOG_FILE:-docs/governance/PHASE-3-ROLLBACK-DRILL-LOG.md}"
DRILL_ID="${DRILL_ID:-phase3-rollback-drill-001}"
STARTED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS="${ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS:-3}"
ROLLBACK_DRILL_FINAL_GATE_RETRY_DELAY_SECONDS="${ROLLBACK_DRILL_FINAL_GATE_RETRY_DELAY_SECONDS:-15}"

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
precheck_commands=(
  "bash tests/e2e/test_phase2_parent_weekly_journey_live.sh"
  "bash tests/e2e/test_phase2_parent_dashboard_followup_live.sh"
)

for cmd in "${precheck_commands[@]}"; do
  if run_cmd "$cmd"; then
    results+=("| \`$cmd\` | PASS |")
  else
    results+=("| \`$cmd\` | FAIL |")
    break
  fi
done

if [ "${#results[@]}" -eq "${#precheck_commands[@]}" ]; then
  final_gate_cmd="bash scripts/ci/final_gate.sh"
  final_gate_ok=0
  for attempt in $(seq 1 "$ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS"); do
    if run_cmd "$final_gate_cmd"; then
      results+=("| \`${final_gate_cmd}\` | PASS |")
      final_gate_ok=1
      break
    fi
    if [ "$attempt" -lt "$ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS" ]; then
      echo "final_gate retry: attempt=${attempt}/${ROLLBACK_DRILL_FINAL_GATE_MAX_ATTEMPTS} sleep_seconds=${ROLLBACK_DRILL_FINAL_GATE_RETRY_DELAY_SECONDS}" >&2
      sleep "$ROLLBACK_DRILL_FINAL_GATE_RETRY_DELAY_SECONDS"
    fi
  done
  if [ "$final_gate_ok" -ne 1 ]; then
    results+=("| \`${final_gate_cmd}\` | FAIL |")
  else
    post_commands=(
      "bash tests/governance/test_docs_presence.sh"
      "bash tests/governance/test_e2e_governance.sh"
    )
    for cmd in "${post_commands[@]}"; do
      if run_cmd "$cmd"; then
        results+=("| \`$cmd\` | PASS |")
      else
        results+=("| \`$cmd\` | FAIL |")
        break
      fi
    done
  fi
fi

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
