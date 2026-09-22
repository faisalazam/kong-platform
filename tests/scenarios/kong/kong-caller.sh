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
    "kong caller"

  assert_jq_eq \
    "$body" \
    '.status' \
    '200' \
    'nested lambda response status'

  assert_jq_type \
    "$body" \
    '.response' \
    'string' \
    'nested lambda response body'
}

execute_test_case \
  method=GET \
  path="/poc/kong/caller" \
  assert=assert_response
