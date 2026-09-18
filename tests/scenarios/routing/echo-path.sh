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
    "echo-path"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .path == "/ad/groups"' \
    "strip_path validation"
}

execute_test_case \
  method=GET \
  path="/poc/echo-path/ad/groups" \
  assert=assert_response
