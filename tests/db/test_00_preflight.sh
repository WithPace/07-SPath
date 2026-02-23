#!/usr/bin/env bash
set -euo pipefail

test -f .env
for key in SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY DOUBAO_API_KEY KIMI_API_KEY; do
  grep -q "^${key}=" .env
done
test -f supabase/config.toml
echo "preflight prerequisites present"
