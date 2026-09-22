#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT=${ENVIRONMENT:-local}
SYNC_CONFIG="${SYNC_CONFIG:-false}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kong_dir="$(cd "$script_dir/.." && pwd)"

source "${script_dir}/common.sh"

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

  if [ "$ENVIRONMENT" = "local" ]; then
    # Wait until the Kong proxy has observed the configuration synchronized through the Admin API.
    #
    # Route visibility via:
    #
    #   http://localhost:8001/routes
    #
    # is not sufficient because proxy workers may still be propagating the updated configuration.
    #
    # A successful request through the proxy proves that:
    #
    #   - routes are available
    #   - services are available
    #   - plugins are active
    #   - proxy workers have applied configuration
    #   - LocalStack is reachable
    #   - the target Lambda function is active and invokable
    #
    # During development I investigated replacing this readiness check with:
    #
    #   aws lambda wait function-active-v2
    #
    # because LocalStack occasionally logs:
    #
    #   AWS lambda.Invoke => 409 (ResourceConflictException)
    #
    # and recommends waiting for Lambda functions to transition from Pending to Active.
    #
    # However, Lambda readiness alone proved insufficient. Tests executed immediately after a successful
    # function-active-v2 wait still intermittently failed with:
    #
    #   404 no Route matched with those values
    #
    # demonstrating that Kong proxy workers had not yet applied the configuration synchronized through decK.
    #
    # A successful request through the proxy therefore acts as a stronger end-to-end readiness signal than either:
    #
    #   - route visibility via the Admin API
    #   - Lambda Active state via function-active-v2
    #
    # Without this check, API requests and automated tests may intermittently fail immediately after a successful decK
    # sync, even though both:
    #
    #   - routes are visible through the Admin API
    #   - Lambda functions report an Active state
    #
    # See also:
    #
    #   https://docs.localstack.cloud/aws/services/lambda/#function-in-pending-state
    wait_for_http_endpoint \
      "Kong Proxy Configuration" \
      "http://localhost:8000/poc/localstack/test" \
      60
  fi

  log "SUCCESS: Kong configuration synchronized"
fi
