#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$script_dir/build.sh"

echo "INFO: Restarting Kong..."

docker compose restart kong

echo "SUCCESS: Kong reloaded with generated configuration"
