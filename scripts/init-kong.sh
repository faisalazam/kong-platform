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



# Next update readme according to the evolved implementation and add readme in tests...



# Client
#   ↓
# Route53 DNS
#   ↓
# API Gateway Custom Domain
# (
#   api.dev.cmdb-api.cloud-automation.nonp.cloud-automation.c1.tpgtelecom.com.au
#       → d-c2fdnp1im2.execute-api.ap-southeast-2.amazonaws.com
#  )
#   ↓
# API Mapping
# (cmdb_api / Stage=api)
#   ↓
# API Gateway API
# (API ID=nfk3bdg4fa | Invoke URL=https://nfk3bdg4fa.execute-api.ap-southeast-2.amazonaws.com/api)
#   ↓
# Lambda / Backend Service


# Client
#   ↓
# Route53 DNS
#   ↓
# Kong
# (
#   api.dev.cmdb-api.cloud-automation.nonp.cloud-automation.c1.tpgtelecom.com.au
# )
#   ↓
# API Gateway API
# (
#   API ID=nfk3bdg4fa
#   Invoke URL=https://nfk3bdg4fa.execute-api.ap-southeast-2.amazonaws.com/api
# )
#   ↓
# Lambda / Backend Service


# Current architecture is not publicly callable cause API Gateway resource policies
# restrict access to specific AWS principals.
#
# Removing API Gateway will require an equivalent authorization model within Kong.




#  curl -i 'https://api.dev.directory-api.cloud-automation.nonp.cloud-automation.c1.tpgtelecom.com.au/ad/groups?domain=TPGT'
#  curl -i 'http://localhost:8000/poc/api-gateway/directory/ad/groups?domain=TPGT'
#  curl -i 'http://localhost:8000/poc/lambda/directory/ad/groups?domain=TPGT'
#
#  curl -i 'https://api.dev.cmdb-api.cloud-automation.nonp.cloud-automation.c1.tpgtelecom.com.au/account_category'
#  NOT_WORKING => curl -i 'http://localhost:8000/poc/lambda/cmdb/account_category'
#  curl -i 'http://localhost:8000/poc/api-gateway/cmdb/account_category'
#
#  curl http://localhost:8001/services
#  curl http://localhost:8001/routes
#  curl http://localhost:8001/plugins



# CloudFormation manages AWS resources
#
# decK manages Kong resources instead of 'Clicking around GUI'


# Kong 3.9.3 aws-lambda plugin with awsgateway_compatible=true produces an API-Gateway-like event
# but not an identical AWS REST API proxy event. Comparison against a real API Gateway invocation
# shows missing fields including stageVariables and resource, different requestContext contents,
# and different body encoding behaviour. Chalice 1.32.0 expects stageVariables to exist and fails
# with KeyError: 'stageVariables' when invoked through Kong.
#
# Injecting event["stageVariables"] = None before Chalice request processing resolves the issue
# and allows successful execution through Kong. See the solution below after the table.
#
# | Field                             | API Gateway         | Kong (awsgateway_compatible: true) |
# | --------------------------------- | ------------------- | ---------------------------------- |
# | `resource`                        | ✅ present          | ❌ missing                         |
# | `path`                            | `/account_category` | `/account_category`                |
# | `httpMethod`                      | ✅                  | ✅                                 |
# | `headers`                         | `null`              | populated object                   |
# | `multiValueHeaders`               | `null`              | populated object                   |
# | `queryStringParameters`           | `null`              | `{}`                               |
# | `multiValueQueryStringParameters` | `null`              | `{}`                               |
# | `pathParameters`                  | `null`              | `{}`                               |
# | `stageVariables`                  | ✅ `null`           | ❌ missing                         |
# | `requestContext`                  | rich AWS object     | simplified object                  |
# | `body`                            | `null`              | `""`                               |
# | `isBase64Encoded`                 | `false`             | `true`                             |
# | `version`                         | absent              | `"1.0"`                            |
#
# So awsgateway_compatible=true does not generate the same event shape as a
# real AWS API Gateway REST API (AWS_PROXY) invocation.




# sam-orchestrator-dev-dev
