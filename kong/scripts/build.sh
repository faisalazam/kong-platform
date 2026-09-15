#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

shopt -s nullglob

services_dir="$kong_dir/services"
service_files=("$services_dir"/*.yml)
generated_dir="$kong_dir/services/.generated"
generated_empty_file="$generated_dir/empty_kong.yml"

echo "INFO: Kong directory: $kong_dir"

mkdir -p "$(dirname "$generated_empty_file")"
rm -rf "$generated_dir"

if [ ${#service_files[@]} -eq 0 ]; then
    echo "INFO: No Service definitions found, generating empty Kong configuration"

    cat > "$generated_empty_file" <<EOF
_format_version: "3.0"
EOF

    echo "SUCCESS: Generated empty Kong configuration"
fi

echo "INFO: Validating generated configuration..."

deck gateway validate "$services_dir"

echo "SUCCESS: Kong configuration is valid"
