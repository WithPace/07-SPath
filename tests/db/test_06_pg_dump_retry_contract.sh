#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

f="scripts/db/rebuild_remote.sh"
test -f "$f" || fail "missing rebuild script"

rg -q 'PG_DUMP_MAX_ATTEMPTS' "$f" || fail "missing PG_DUMP_MAX_ATTEMPTS config"
rg -q 'PG_DUMP_RETRY_BASE_DELAY_SECONDS' "$f" || fail "missing PG_DUMP_RETRY_BASE_DELAY_SECONDS config"
rg -q 'pg_dump retry:' "$f" || fail "missing pg_dump retry log"
rg -q 'for attempt in \$\(seq 1 "\$max_attempts"\)' "$f" || fail "missing pg_dump retry loop"
rg -q 'sleep "\$sleep_seconds"' "$f" || fail "missing retry backoff sleep"
rg -q 'attempt=\$\{attempt\}/\$\{max_attempts\}' "$f" || fail "missing retry attempt trace"

echo "pg_dump retry contract present"
