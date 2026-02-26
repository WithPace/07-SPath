#!/usr/bin/env bash
set -euo pipefail

helper="tests/e2e/_shared/orchestrator_retry.sh"
test -f "$helper"

# Retry reason must map to retry action path.
grep -q 'if \[ "\$attempt" -lt "\$max_attempts" \] && echo "\$response" | grep -q "\${ORCH_RETRY_REASON_WORKER_LIMIT}"; then' "$helper"
grep -q 'if \[ "\$curl_exit" -ne 0 \]; then' "$helper"
grep -q 'reason=\${ORCH_RETRY_REASON_TRANSPORT_ERROR}' "$helper"
grep -q 'sleep_seconds=\$((base_delay_seconds \* (1 << (attempt - 1))))' "$helper"
grep -q 'sleep "\$sleep_seconds"' "$helper"
grep -q 'continue' "$helper"

# Terminal reasons must map to terminal action path.
grep -q 'failure_reason="\${ORCH_TERMINAL_REASON_DONE_EVENT_MISSING}"' "$helper"
grep -q 'failure_reason="\${ORCH_TERMINAL_REASON_WORKER_LIMIT_EXHAUSTED}"' "$helper"
grep -q 'failure_reason="\${ORCH_TERMINAL_REASON_CARDS_PAYLOAD_MISSING}"' "$helper"
grep -q 'failure_reason="\${ORCH_TERMINAL_REASON_TRANSPORT_ERROR_EXHAUSTED}"' "$helper"
grep -q 'orchestrator terminal_failure: module=\${module_label} request_id=\${request_id} attempt=\${attempt}/\${max_attempts} reason=\${failure_reason}' "$helper"
grep -q 'ORCH_LAST_REQUEST_ID="\$request_id"' "$helper"
grep -q 'ORCH_LAST_RESPONSE="\$response"' "$helper"
grep -q 'return 1' "$helper"

echo "live smoke retry reason action contract present"
