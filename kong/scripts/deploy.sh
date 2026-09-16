#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-local}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"
services_dir="$kong_dir/services"

echo "INFO: Environment: $ENVIRONMENT"
echo "INFO: Loading environment variables"

# shellcheck source=/dev/null
source "$kong_dir/.config/${ENVIRONMENT}.env"

"$script_dir/build.sh"

echo "INFO: Synchronizing Kong configuration"

deck \
  --config "$kong_dir/.config/${ENVIRONMENT}.deck.yml" \
  gateway sync \
  "$services_dir"

echo "SUCCESS: Kong configuration synchronized"
