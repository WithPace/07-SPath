#!/usr/bin/env bash
set -euo pipefail

RELEASE_TAG="${RELEASE_TAG:-release-main-$(date -u +%Y-%m-%d)}"
TARGET_BRANCH="${TARGET_BRANCH:-main}"
REQUIRE_ORIGIN="${REQUIRE_ORIGIN:-0}"

BACKEND_REPO_PATH="${BACKEND_REPO_PATH:-.}"
FRONTEND_REPO_PATH="${FRONTEND_REPO_PATH:-../starpath-frontend}"
ADMIN_REPO_PATH="${ADMIN_REPO_PATH:-../starpath-admin-web}"

fail() {
  echo "$1" >&2
  exit 1
}

validate_mode() {
  case "$REQUIRE_ORIGIN" in
    0|1) ;;
    *)
      fail "REQUIRE_ORIGIN must be 0 or 1"
      ;;
  esac
}

check_repo() {
  local name="$1"
  local repo_path="$2"
  local branch short_sha origin_url

  test -d "$repo_path/.git" || fail "repo=${name} missing git dir: ${repo_path}"

  branch="$(git -C "$repo_path" branch --show-current)"
  [ "$branch" = "$TARGET_BRANCH" ] || fail "repo=${name} must be on branch=${TARGET_BRANCH}, got=${branch}"

  if [ -n "$(git -C "$repo_path" status --porcelain)" ]; then
    fail "repo=${name} has uncommitted changes"
  fi

  git -C "$repo_path" rev-parse -q --verify "refs/tags/${RELEASE_TAG}" >/dev/null \
    || fail "repo=${name} missing tag=${RELEASE_TAG}"

  short_sha="$(git -C "$repo_path" rev-parse --short=12 HEAD)"
  origin_url="$(git -C "$repo_path" remote get-url origin 2>/dev/null || true)"

  if [ -z "$origin_url" ]; then
    if [ "$REQUIRE_ORIGIN" = "1" ]; then
      fail "repo=${name} missing origin remote"
    fi
    origin_url="<missing-origin>"
  fi

  echo "${name}|${repo_path}|${branch}|${short_sha}|${origin_url}"
}

print_row() {
  local row="$1"
  local name repo_path branch short_sha origin_url

  IFS='|' read -r name repo_path branch short_sha origin_url <<<"$row"
  printf "| %s | %s | %s | %s | %s |\n" "$name" "$repo_path" "$branch" "$short_sha" "$origin_url"
}

print_push_commands() {
  local row="$1"
  local name repo_path branch short_sha origin_url

  IFS='|' read -r name repo_path branch short_sha origin_url <<<"$row"
  echo "# ${name}"
  echo "git -C \"${repo_path}\" push origin ${TARGET_BRANCH}"
  echo "git -C \"${repo_path}\" push origin ${RELEASE_TAG}"
}

validate_mode

backend_row="$(check_repo "backend" "$BACKEND_REPO_PATH")"
frontend_row="$(check_repo "frontend" "$FRONTEND_REPO_PATH")"
admin_row="$(check_repo "admin-web" "$ADMIN_REPO_PATH")"

echo "== remote publish precheck =="
echo "| repo | path | branch | commit_sha | origin |"
echo "|---|---|---|---|---|"
print_row "$backend_row"
print_row "$frontend_row"
print_row "$admin_row"

if printf "%s\n%s\n%s\n" "$backend_row" "$frontend_row" "$admin_row" | rg -q '<missing-origin>'; then
  echo "WARN: one or more repositories are missing origin remote; set REQUIRE_ORIGIN=1 to enforce hard failure."
fi

echo
echo "== push command plan (not executed) =="
print_push_commands "$backend_row"
print_push_commands "$frontend_row"
print_push_commands "$admin_row"

echo
echo "remote publish precheck pass (release_tag=${RELEASE_TAG} target_branch=${TARGET_BRANCH} require_origin=${REQUIRE_ORIGIN})"
