#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"

# shellcheck source=tests/e2e/_shared/orchestrator_retry.sh
source "$helper"

# Range/format guard behavior contract (max attempts range [2,6]).
test "$(orchestrator_sanitize_positive_int "4" "4" "2" "6")" = "4"
test "$(orchestrator_sanitize_positive_int "2" "4" "2" "6")" = "2"
test "$(orchestrator_sanitize_positive_int "6" "4" "2" "6")" = "6"
test "$(orchestrator_sanitize_positive_int "1" "4" "2" "6")" = "4"
test "$(orchestrator_sanitize_positive_int "7" "4" "2" "6")" = "4"
test "$(orchestrator_sanitize_positive_int "abc" "4" "2" "6")" = "4"

# Range/format guard behavior contract (base delay range [1,5]).
test "$(orchestrator_sanitize_positive_int "1" "1" "1" "5")" = "1"
test "$(orchestrator_sanitize_positive_int "5" "1" "1" "5")" = "5"
test "$(orchestrator_sanitize_positive_int "0" "1" "1" "5")" = "1"
test "$(orchestrator_sanitize_positive_int "9" "1" "1" "5")" = "1"
test "$(orchestrator_sanitize_positive_int "nan" "1" "1" "5")" = "1"

# Wiring contract in orchestrator retry path.
grep -Fq 'max_attempts=$(orchestrator_sanitize_positive_int "${ORCH_MAX_ATTEMPTS:-4}" "4" "2" "6")' "$helper"
grep -Fq 'base_delay_seconds=$(orchestrator_sanitize_positive_int "${ORCH_RETRY_BASE_DELAY_SECONDS:-1}" "1" "1" "5")' "$helper"

echo "live smoke retry limits contract present"
