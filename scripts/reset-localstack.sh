#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# LocalStack Reset
#
# LocalStack maintains internal runtime state for Lambda execution.
#
# Removing Lambda runtime containers without restarting LocalStack can leave
# LocalStack holding stale runtime references, causing subsequent Lambda
# invocations to fail or hang while attempting to reconnect to containers that
# no longer exist.
#
# This script performs a full LocalStack reset by:
#
#   1. Removing all LocalStack-managed Lambda runtime containers.
#   2. Restarting the LocalStack service.
#
# This ensures LocalStack internal state and Lambda runtimes are recreated
# consistently before the next test run.
# -----------------------------------------------------------------------------

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/cleanup-lambdas.sh"

docker compose restart localstack
