#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "$1" >&2
  exit 1
}

hook_file="supabase/functions/sms-hook/index.ts"
hook_test_file="supabase/functions/sms-hook/index_test.ts"

test -f "$hook_file" || fail "missing sms-hook function file"
test -f "$hook_test_file" || fail "missing sms-hook unit test file"

rg -q 'Deno\.serve\(handleSmsHook\)' "$hook_file" || fail "sms-hook missing Deno serve entry"
rg -q 'function resolveAliyunConfig' "$hook_file" || fail "sms-hook missing aliyun config resolver"
rg -q 'sendAliyunSms' "$hook_file" || fail "sms-hook missing aliyun sender"
rg -q 'buildAliyunHookError' "$hook_file" || fail "sms-hook missing provider error mapping"
rg -q 'extractPhoneAndOtp' "$hook_file" || fail "sms-hook missing payload extractor"

rg -q 'normalizeChinaPhone strips \+86 prefix' "$hook_test_file" || fail "sms-hook tests missing phone normalization case"
rg -q 'buildAliyunHookError maps limit code to 429' "$hook_test_file" || fail "sms-hook tests missing rate-limit mapping case"

echo "sms-hook contract present"
