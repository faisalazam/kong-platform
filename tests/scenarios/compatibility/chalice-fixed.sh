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

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .resource != null' \
    "resource normalization"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .stageVariables == null' \
    "stageVariables normalization"
}

execute_test_case \
  method=GET \
  path="/poc/chalice-fixed" \
  assert=assert_response
