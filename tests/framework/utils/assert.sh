#!/usr/bin/env bash

PASSED_TESTS=0
FAILED_TESTS=0

fail_assertion() {
  local actual="$1"
  local context="$2"
  local expected="$3"

  echo "FAIL [$actual] ($context -> expected $expected)" >&2
  echo >&2

  if [ "$CURRENT_TEST_FAILED" -eq 0 ]; then
    FAILED_TESTS=$((FAILED_TESTS + 1))
    CURRENT_TEST_FAILED=1
  fi
}

assert_status() {
  local expected="$1"
  local actual="$2"
  local context="$3"

  if [ -z "$actual" ]; then
    fail_assertion "empty" "$context" "$expected"
    return
  fi

  if [ "$actual" -ne "$expected" ]; then
    fail_assertion "$actual" "$context" "$expected"
  fi
}

assert_jq_expr() {
  local body="$1"
  local expr="$2"
  local context="$3"

  if ! echo "$body" | jq -e "$expr" >/dev/null; then
    fail_assertion "body" "$context" "$expr"
  fi
}

finalize_assertions() {
  echo "PASSED_TESTS_COUNT_PER_FILE=$PASSED_TESTS"
  echo "FAILED_TESTS_COUNT_PER_FILE=$FAILED_TESTS"

  if [ "$FAILED_TESTS" -ne 0 ]; then
    exit 1
  fi
}

if [[ -z "${ASSERT_TRAP_INSTALLED:-}" ]]; then
  ASSERT_TRAP_INSTALLED=1
  trap finalize_assertions EXIT
fi
