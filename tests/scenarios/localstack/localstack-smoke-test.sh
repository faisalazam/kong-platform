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
    "localstack smoke test"

  assert_jq_expr \
    "$body" \
    '.body | contains("hello from localstack")' \
    "localstack smoke test response"
}

execute_test_case \
  method=GET \
  path="/poc/localstack/test" \
  assert=assert_response
