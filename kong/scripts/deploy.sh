#!/usr/bin/env bash

set -euo pipefail

kong_admin_api="http://localhost:8001"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"
services_dir="$kong_dir/services"

"$script_dir/build.sh"

echo "INFO: Synchronizing Kong configuration..."

# No GUI, no restarts of Kong required, just sync it.
deck gateway sync \
  --kong-addr "$kong_admin_api" \
  "$services_dir"

echo "SUCCESS: Kong configuration synchronized"
