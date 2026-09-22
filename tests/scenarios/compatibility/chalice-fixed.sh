#!/usr/bin/env bash

source tests/framework/utils/bootstrap.sh

assert_response() {
  declare -A args
  parse_named_args args "$@"

  local status="${args[status]}"
  local body="${args[body]}"

  assert_status \
    200 \
    "$status" \
    "chalice fixed"

  assert_jq_type \
    "$body" \
    '.body | fromjson | .resource' \
    'string' \
    'resource normalization'

  assert_jq_nullish \
    "$body" \
    '.body | fromjson | .stageVariables' \
    'stageVariables normalization'
}

execute_test_case \
  method=GET \
  path="/poc/chalice-fixed" \
  assert=assert_response
