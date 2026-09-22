#!/usr/bin/env bash

# Shared shell helpers used by Kong scripts.

RETRIES="${RETRIES:-30}"
RETRY_DELAY="${RETRY_DELAY:-2}"

CURL_MAX_TIME="${CURL_MAX_TIME:-10}"
CURL_CONNECT_TIMEOUT="${CURL_CONNECT_TIMEOUT:-3}"

log()   { echo "[INFO]  $*"; }
warn()  { echo "[WARN]  $*"; }
error() { echo "[ERROR] $*" >&2; }

wait_for_http_endpoint() {
  local name="$1"
  local url="$2"
  local retries="${3:-$RETRIES}"

  log "Waiting for ${name}..."

  for ((i=1; i<=retries; i++)); do

    status="$(
      curl \
        -s \
        -o /dev/null \
        -w '%{http_code}' \
        --connect-timeout "${CURL_CONNECT_TIMEOUT}" \
        --max-time "${CURL_MAX_TIME}" \
        "${url}" || true
    )"

    if [ "${status}" = "200" ]; then
      log "${name} is ready"
      return 0
    fi

    warn "Attempt ${i}/${retries} returned HTTP ${status}, retrying in ${RETRY_DELAY}s..."

    sleep "${RETRY_DELAY}"
  done

  error "${name} did not become ready after ${retries} attempts"
  exit 1
}
