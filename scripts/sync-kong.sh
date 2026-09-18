#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-local}
SYNC_CONFIG="${SYNC_CONFIG:-false}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

log()   { echo "[INFO]  $*"; }

log "Kong directory: $kong_dir"
log "Environment: $ENVIRONMENT"
log "Synchronization enabled: $SYNC_CONFIG"

log "Loading environment variables"

# shellcheck source=/dev/null
source "$kong_dir/.config/${ENVIRONMENT}.env"

services_dir="$kong_dir/services"
tests_kong_dir="$kong_dir/tests/kong"

# Expand globs that match nothing to an empty array instead of
# leaving the literal pattern (e.g. services/*.yml).
shopt -s nullglob

service_files=("$services_dir"/*.yml)

generated_dir="$services_dir/.generated"
generated_empty_file="$generated_dir/empty_kong.yml"

rm -rf "$generated_dir"

if [ ${#service_files[@]} -eq 0 ]; then
    log "No service definitions found"

    mkdir -p "$generated_dir"

    cat > "$generated_empty_file" <<EOF
_format_version: "3.0"
EOF

    log "Generated empty Kong configuration"
fi

log "Validating Kong configuration"

validate_sources=(
  "$services_dir"
  "$tests_kong_dir"
)

deck \
  --config "$kong_dir/.config/${ENVIRONMENT}.deck.yml" \
  gateway validate \
  "${validate_sources[@]}"

log "SUCCESS: Kong configuration is valid"


if [ "${SYNC_CONFIG}" = "true" ]; then
  log "Synchronizing Kong configuration"

  sync_sources=(
    "$services_dir"
  )

  if [ "$ENVIRONMENT" = "local" ]; then
    sync_sources+=("$tests_kong_dir")
  fi

  deck \
    --config "$kong_dir/.config/${ENVIRONMENT}.deck.yml" \
    gateway sync \
    "${sync_sources[@]}"

  log "SUCCESS: Kong configuration synchronized"
fi

# TODO: Remove the below block and find a better solution instead of sleeping for 5 seconds
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
#
#curl -s http://localhost:8001/routes | jq '.data | length'
#
#REGION="ap-southeast-2"
#ENDPOINT="http://localhost:4566"
#AUTOMATION_ACCOUNT_ID="179857410264"
#AUTOMATION_ACCOUNT_ACCESS_KEY="test"
#AWS_ACCESS_KEY_ID="${AUTOMATION_ACCOUNT_ID}" \
#AWS_SECRET_ACCESS_KEY="${AUTOMATION_ACCOUNT_ACCESS_KEY}" \
#aws \
#  --region "${REGION}" \
#  --endpoint-url "${ENDPOINT}" \
#  lambda wait function-active-v2 --function-name echo-path
sleep 5
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
