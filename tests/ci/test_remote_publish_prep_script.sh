#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

script="scripts/ci/prepare_remote_publish.sh"

test -f "$script" || fail "missing remote publish precheck script"
test -x "$script" || fail "remote publish precheck script must be executable"

rg -q 'RELEASE_TAG' "$script" || fail "script missing RELEASE_TAG handling"
rg -q 'TARGET_BRANCH' "$script" || fail "script missing TARGET_BRANCH handling"
rg -q 'REQUIRE_ORIGIN' "$script" || fail "script missing REQUIRE_ORIGIN handling"
rg -q 'BACKEND_REPO_PATH' "$script" || fail "script missing backend repo path handling"
rg -q 'FRONTEND_REPO_PATH' "$script" || fail "script missing frontend repo path handling"
rg -q 'ADMIN_REPO_PATH' "$script" || fail "script missing admin repo path handling"
rg -q 'refs/tags/\$\{RELEASE_TAG\}' "$script" || fail "script must verify tag presence"
rg -q 'status --porcelain' "$script" || fail "script must verify clean working tree"
rg -q 'push origin \$\{TARGET_BRANCH\}' "$script" || fail "script must print branch push command"
rg -q 'push origin \$\{RELEASE_TAG\}' "$script" || fail "script must print tag push command"
rg -q 'not executed' "$script" || fail "script output must declare no push execution"

echo "remote publish precheck script present"
