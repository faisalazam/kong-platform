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
    "event dump"

  assert_jq_eq \
    "$body" \
    '.statusCode' \
    '200' \
    'lambda response status'

  assert_jq_type \
    "$body" \
    '.body | fromjson | .requestContext' \
    'object' \
    'requestContext present'

  assert_jq_type \
    "$body" \
    '.body | fromjson | .headers' \
    'object' \
    'headers present'

  assert_jq_eq \
    "$body" \
    '.body | fromjson | .httpMethod' \
    '"GET"' \
    'http method'

  assert_jq_type \
    "$body" \
    '.body | fromjson | .path' \
    'string' \
    'path present'
}

execute_test_case \
  method=GET \
  path="/poc/event-dump" \
  assert=assert_response
