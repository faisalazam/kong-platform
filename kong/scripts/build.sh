#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-local}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

shopt -s nullglob

services_dir="$kong_dir/services"
service_files=("$services_dir"/*.yml)

generated_dir="$services_dir/.generated"
generated_empty_file="$generated_dir/empty_kong.yml"

echo "INFO: Kong directory: $kong_dir"
echo "INFO: Environment: $ENVIRONMENT"

echo "INFO: Loading environment variables"

# shellcheck source=/dev/null
source "$kong_dir/.config/${ENVIRONMENT}.env"

rm -rf "$generated_dir"
mkdir -p "$generated_dir"

if [ ${#service_files[@]} -eq 0 ]; then
    echo "INFO: No service definitions found"

    cat > "$generated_empty_file" <<EOF
_format_version: "3.0"
EOF

    echo "INFO: Generated empty Kong configuration"
fi

echo "INFO: Validating Kong configuration"

deck \
  --config "$kong_dir/.config/${ENVIRONMENT}.deck.yml" \
  gateway validate \
  "$services_dir"

echo "SUCCESS: Kong configuration is valid"
