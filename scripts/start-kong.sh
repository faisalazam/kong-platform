#!/usr/bin/env bash

set -euo pipefail

PROFILE=cloud-automation-dev

echo "INFO: AWS profile: $PROFILE"

# Login before running this script.
# aws login --profile "$PROFILE"

echo "INFO: Exporting AWS credentials"

# Required for Kong → AWS Lambda invocations
eval "$(aws configure export-credentials \
  --profile "$PROFILE" \
  --format env)"

echo "INFO: Restarting Kong containers"

docker compose down kong
docker compose up -d kong

echo "SUCCESS: Kong container restarted"
