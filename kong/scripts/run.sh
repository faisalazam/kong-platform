#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-local}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

echo "INFO: Kong directory: $kong_dir"
echo "INFO: Environment: $ENVIRONMENT"

echo "INFO: Loading environment variables"

# shellcheck source=/dev/null
source "$kong_dir/.config/${ENVIRONMENT}.env"

services_dir="$kong_dir/services"

# Expand globs that match nothing to an empty array instead of
# leaving the literal pattern (e.g. services/*.yml).
shopt -s nullglob

service_files=("$services_dir"/*.yml)

generated_dir="$services_dir/.generated"
generated_empty_file="$generated_dir/empty_kong.yml"

rm -rf "$generated_dir"

if [ ${#service_files[@]} -eq 0 ]; then
    echo "INFO: No service definitions found"

    mkdir -p "$generated_dir"

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

echo "INFO: Synchronizing Kong configuration"

deck \
  --config "$kong_dir/.config/${ENVIRONMENT}.deck.yml" \
  gateway sync \
  "$services_dir"

echo "SUCCESS: Kong configuration synchronized"
