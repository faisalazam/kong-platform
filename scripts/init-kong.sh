#!/usr/bin/env bash

set -euo pipefail

AWS_MODE="${AWS_MODE:-localstack}"
ENVIRONMENT="${ENVIRONMENT:-local}"

RETRIES="${RETRIES:-30}"
RETRY_DELAY="${RETRY_DELAY:-2}"

CURL_MAX_TIME="${CURL_MAX_TIME:-10}"
CURL_CONNECT_TIMEOUT="${CURL_CONNECT_TIMEOUT:-3}"

log()   { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*"; }
error() { echo "[ERROR] $*" >&2; }

log "Environment: ${ENVIRONMENT}"
log "AWS mode: ${AWS_MODE}"

if [ "${AWS_MODE}" = "aws" ]; then
  log "Exporting AWS credentials"

  AWS_PROFILE="${AWS_PROFILE:-cloud-automation-dev}"
  log "AWS profile: ${AWS_PROFILE}"

  if ! creds="$(
    aws configure export-credentials \
      --profile "${AWS_PROFILE}" \
      --format env
  )"; then

    error "Failed to export AWS credentials"

    cat >&2 <<EOF

Please reauthenticate using:

  aws login --profile "${AWS_PROFILE}"

EOF

    exit 1
  fi

  eval "${creds}"

  log "Refreshing Kong container with updated AWS credentials"

  docker compose up -d --force-recreate kong

elif [ "${AWS_MODE}" = "localstack" ]; then
  export AWS_REGION="${AWS_REGION}"
  export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
  export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}"
  export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"

  log "Using LocalStack credentials"

else
  error "Unsupported AWS_MODE: ${AWS_MODE}"
  exit 1
fi

wait_for_http_endpoint() {
  local name="$1"
  local url="$2"

  log "Waiting for ${name}..."

  for ((i=1; i<=RETRIES; i++)); do
    if curl -sf \
      --connect-timeout "${CURL_CONNECT_TIMEOUT}" \
      --max-time "${CURL_MAX_TIME}" \
      "${url}" >/dev/null; then

      log "${name} is ready"
      return 0
    fi

    warn "Attempt ${i}/${RETRIES} failed, retrying in ${RETRY_DELAY}s..."
    sleep "${RETRY_DELAY}"
  done

  error "${name} did not become ready in time"
  exit 1
}

wait_for_http_endpoint \
  "Kong Admin API" \
  "http://localhost:8001/status"

