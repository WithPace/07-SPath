#!/usr/bin/env bash
set -euo pipefail

f="docs/governance/PHASE-2-CONTRACT-CATALOG.md"
test -f "$f"

for module in chat-casual assessment training training-advice training-record dashboard; do
  rg -q "^### ${module}$" "$f"
done

rg -q "tests/e2e/test_phase2_parent_weekly_journey_live.sh" "$f"
rg -q "tests/e2e/test_phase2_parent_dashboard_followup_live.sh" "$f"
rg -q "tests/db/test_phase2_scenario_writeback_consistency.sh" "$f"
rg -q "tests/functions/test_phase2_business_output_contract.sh" "$f"

echo "phase2 contract catalog present"
