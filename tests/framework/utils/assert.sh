#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Assertion Helpers
#
# Common Examples
#
# HTTP Status
#
#   assert_status \
#     200 \
#     "$status" \
#     "localstack smoke test"
#
# Equality Comparison
#
#   assert_jq_eq \
#     "$body" \
#     '.statusCode' \
#     '200' \
#     'lambda response status'
#
# Type Validation
#
#   assert_jq_type \
#     "$body" \
#     '.body | fromjson | .requestContext' \
#     'object' \
#     'requestContext present'
#
# Generic jq Expression
#
#   assert_jq_expr \
#     "$body" \
#     '.body | fromjson | .path == "/ad/groups"' \
#     '"/ad/groups"' \
#     'strip_path validation' \
#     'Expected path to match'
#
# Null / Empty Validation
#
#   assert_jq_nullish \
#     "$body" \
#     '.body | fromjson | .stageVariables' \
#     'stageVariables normalization'
#
# Boolean Validation
#
#   assert_jq_booleanish \
#     "$body" \
#     '.enabled' \
#     'feature enabled flag'
#
# Non-Empty String Array
#
#   assert_jq_non_empty_string_array \
#     "$body" \
#     '.groups' \
#     'groups present'
#
# Field Ends With Another Field
#
#   assert_jq_field_endswith_field \
#     "$body" \
#     '.path' \
#     '.resource' \
#     'resource matches path'
#
# -----------------------------------------------------------------------------

# Track assertion results per test file
PASSED_TESTS=0
FAILED_TESTS=0

fail_assertion() {
  local actual="$1"
  local context="$2"
  local expected="$3"
  local reason="$4"

  echo "FAIL [$actual] ($context -> expected $expected)" >&2
  [ -n "$reason" ] && echo "Reason: $reason" >&2
  echo >&2

  if [ "$CURRENT_TEST_FAILED" -eq 0 ]; then
    FAILED_TESTS=$((FAILED_TESTS + 1))
    CURRENT_TEST_FAILED=1
  fi
}

assert_jq_expr() {
  local body="$1"
  local jq_expr="$2"
  local expected="$3"
  local context="$4"
  local reason="$5"

  if ! echo "$body" | jq -e "$jq_expr" > /dev/null; then
    fail_assertion "body" "$context" "$expected" "$reason"
  fi
}

assert_jq_type() {
  local body="$1"
  local jq_path="$2"
  local expected_type="$3"
  local context="$4"

  assert_jq_expr \
    "$body" \
    "$jq_path | select(. != null) | type == \"$expected_type\"" \
    "$expected_type" \
    "$context" \
    "jq assertion failed for path: $jq_path"
}

assert_jq_booleanish() {
  local body="$1"
  local jq_path="$2"
  local context="$3"

  assert_jq_expr \
    "$body" \
    "$jq_path
     | select(. != null)
     | (type == \"boolean\" or (type == \"string\" and (. == \"true\" or . == \"false\")))" \
    "boolean" \
    "$context" \
    "Expected boolean or boolean-like string at $jq_path"
}

assert_jq_non_empty_string_array() {
  local body="$1"
  local jq_path="$2"
  local context="$3"

  # must exist and be an array
  assert_jq_type "$body" "$jq_path" "array" "$context"

  # must not be empty
  assert_jq_expr \
    "$body" \
    "$jq_path | length > 0" \
    "non-empty array" \
    "$context" \
    "Expected $jq_path to be a non-empty array"

  # all elements must be strings
  assert_jq_expr \
    "$body" \
    "all(${jq_path}[]; type == \"string\")" \
    "string array" \
    "$context" \
    "Expected all elements in $jq_path to be strings"
}

assert_jq_field_endswith_field() {
  local body="$1"
  local field_path="$2"
  local suffix_path="$3"
  local context="$4"

  assert_jq_expr \
    "$body" \
    "$field_path as \$a | $suffix_path as \$b | (\$a | endswith(\$b))" \
    "field ends with field" \
    "$context" \
    "Expected $field_path to end with $suffix_path"
}

assert_jq_eq() {
  local body="$1"
  local jq_path="$2"
  local expected="$3"
  local context="$4"

  assert_jq_expr \
    "$body" \
    "$jq_path == $expected" \
    "$expected" \
    "$context" \
    "Expected $jq_path to equal $expected"
}

assert_jq_nullish() {
  local body="$1"
  local jq_path="$2"
  local context="$3"

  assert_jq_expr \
    "$body" \
    "($jq_path == null) or ($jq_path == \"\")" \
    "null or empty string" \
    "$context" \
    "Expected $jq_path to be null or empty"
}

assert_status() {
  local expected="$1"
  local actual="$2"
  local context="$3"

  # 1. Missing status
  if [ -z "$actual" ]; then
    fail_assertion "no status" "$context" "$expected" \
      "HTTP status was empty. Curl request failed or response parsing broke."
    return
  fi

  # 2. Non-numeric status
  if ! [[ "$actual" =~ ^[0-9]+$ ]]; then
    fail_assertion "$actual" "$context" "$expected" \
      "HTTP status is not numeric. Something is wrong with the request or parsing."
    return
  fi

  # 3. Numeric comparison
  if [ "$actual" -ne "$expected" ]; then
    fail_assertion "$actual" "$context" "$expected"
    return
  fi
}

# Emit per-file test counts as machine-readable output.
# This is consumed by the test runner, not intended for human logs.
# So, these echos shouldn't go to stderr (i.e. >&2).
finalize_assertions() {
  echo "PASSED_TESTS_COUNT_PER_FILE=$PASSED_TESTS"
  echo "FAILED_TESTS_COUNT_PER_FILE=$FAILED_TESTS"

  if [ "$FAILED_TESTS" -ne 0 ]; then
    exit 1
  fi
}

# Install EXIT trap only once per process => runs when the test file exits
if [[ -z "$ASSERT_TRAP_INSTALLED" ]]; then
  ASSERT_TRAP_INSTALLED=1
  trap finalize_assertions EXIT
fi
