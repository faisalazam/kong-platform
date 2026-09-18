#!/usr/bin/env bash

source tests/utils/bootstrap.sh

assert_response() {
  declare -A args
  parse_named_args args "$@"

  local status="${args[status]}"
  local body="${args[body]}"

  assert_status \
    200 \
    "$status" \
    "event dump"

  assert_jq_expr \
    "$body" \
    '.statusCode == 200' \
    "lambda response status"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .requestContext != null' \
    "requestContext present"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .headers != null' \
    "headers present"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .httpMethod == "GET"' \
    "http method"

  assert_jq_expr \
    "$body" \
    '.body | fromjson | .path != null' \
    "path present"
}

execute_test_case \
  method=GET \
  path="/poc/event-dump" \
  assert=assert_response
