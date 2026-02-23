#!/usr/bin/env bash
set -euo pipefail

bash scripts/db/rebuild_remote.sh
echo "remote rebuild done"
