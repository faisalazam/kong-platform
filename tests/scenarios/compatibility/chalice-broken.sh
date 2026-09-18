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
    "chalice broken invocation"

  assert_jq_expr \
    "$body" \
    '.errorType == "KeyError"' \
    "missing stageVariables"

  assert_jq_expr \
    "$body" \
    '.errorMessage == "\u0027stageVariables\u0027"' \
    "stageVariables key missing"
}

execute_test_case \
  method=GET \
  path="/poc/chalice-broken" \
  assert=assert_response
