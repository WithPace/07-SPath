#!/usr/bin/env bash
set -euo pipefail

test -f supabase/functions/_shared/auth.ts
test -f supabase/functions/_shared/model-router.ts
test -f supabase/functions/_shared/finalize.ts
test -f supabase/functions/_shared/sse.ts
echo "shared modules exist"
