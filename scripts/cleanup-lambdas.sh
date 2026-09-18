#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# LocalStack Lambda Runtime Cleanup
#
# LocalStack executes Lambda functions inside Docker containers based on
# the Lambda runtime image (e.g. public.ecr.aws/lambda/python:3.12).
#
# These runtime containers are created dynamically on first invocation and
# are not defined in docker-compose.yml.
#
# This script removes all LocalStack-managed Lambda runtime containers for
# the current project.
#
# Example containers:
#
#   kong-aws-localstack-lambda-echo-path-*
#   kong-aws-localstack-lambda-event-dump-*
# -----------------------------------------------------------------------------

docker ps -aq \
  --filter "name=kong-aws-localstack-lambda-" \
| xargs -r docker rm -f
