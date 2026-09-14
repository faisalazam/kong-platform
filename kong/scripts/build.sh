#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"
generated_file="$kong_dir/generated/kong.yml"

shopt -s nullglob

service_files=("$kong_dir/services"/*.yml)
plugin_files=("$kong_dir/plugins"/*.yml)

echo "INFO: Kong directory: $kong_dir"

mkdir -p "$(dirname "$generated_file")"
rm -f "$generated_file"

if [ ${#service_files[@]} -eq 0 ]; then
    echo "INFO: No Service definitions found, generating empty Kong configuration"

    cat > "$generated_file" <<EOF
_format_version: "3.0"
EOF

    echo "SUCCESS: Generated empty Kong configuration"

else

    {
      echo '_format_version: "3.0"'

      echo
      echo 'services:'
      sed 's/^/  /' "${service_files[@]}"
      echo

      if [ ${#plugin_files[@]} -gt 0 ]; then
        echo
        echo 'plugins:'
        sed 's/^/  /' "${plugin_files[@]}"
        echo
      fi

    } > "$generated_file"

    echo "SUCCESS: Generated $generated_file"

fi

echo "INFO: Validating generated configuration..."

# Preferred validation approach for database-backed Kong deployments.
#
# The generated manifest is synchronized into Kong using:
#   deck gateway sync
#
# which mirrors the production deployment flow:
#   generated kong.yml → decK validate → decK sync → Kong + PostgreSQL
deck gateway validate "$generated_file"

# Alternative validation approach for DB-less Kong deployments.
#
# In DB-less mode Kong loads the declarative configuration directly via: KONG_DECLARATIVE_CONFIG
#
# In that scenario validating with the Kong runtime itself is often
# preferable because Kong is the component directly consuming the file.
#
#kong_image="kong:3.9"
#docker run --rm \
#  -e KONG_DATABASE=off \
#  -v "$kong_dir/generated:/kong" \
#  "$kong_image" \
#  kong config parse /kong/kong.yml

echo "SUCCESS: Kong configuration is valid"
