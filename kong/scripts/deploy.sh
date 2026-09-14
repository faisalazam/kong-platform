#!/usr/bin/env bash

set -euo pipefail

kong_admin_api="http://localhost:8001"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

"$script_dir/build.sh"

echo "INFO: Synchronizing Kong configuration..."

# No GUI, no restarts of Kong required, just sync it.
deck gateway sync \
  --kong-addr "$kong_admin_api" \
  "$kong_dir/generated/kong.yml"

echo "SUCCESS: Kong configuration synchronized"
