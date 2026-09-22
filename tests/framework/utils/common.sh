#!/usr/bin/env bash

TARGET_BASE_URL="${TARGET_BASE_URL:-http://localhost:8000}"

# Orchestrates a single test case using a template-method pattern
execute_test_case() {
  # CURRENT_TEST_FAILED is intentionally global to allow assertion functions to update it in assert.sh
  CURRENT_TEST_FAILED=0

  declare -A args
  parse_named_args args "$@"

  local method="${args[method]}"
  local path="${args[path]}"
  local body="${args[body]}"
  local assertion="${args[assert]}"

  RESPONSE=$(execute_operation method="$method" path="$path" body="$body")
  STATUS=$(extract_status "$RESPONSE")
  BODY=$(extract_body "$RESPONSE")

  # Pass status, body, path to assert function
  "$assertion" status="$STATUS" body="$BODY" path="$path"

  if [ "$CURRENT_TEST_FAILED" -ne 0 ]; then
    print_response "$STATUS" "$BODY"
  fi

  # Emit PASS only if no assertion failed in this test case
  if [ "$CURRENT_TEST_FAILED" -eq 0 ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi
}


#
# Framework execution boundary.
#
# Replace this function when adapting the framework to interact
# with a different type of target system or execution mechanism.
#
# Examples include:
#   - HTTP requests via curl
#   - aws lambda invoke
#   - docker compose exec
#   - kubectl exec
#   - local CLI execution
#
# The remainder of the framework should not generally require
# modification.
#
execute_operation() {
  declare -A args
  parse_named_args args "$@"

  local method="${args[method]}"
  local path="${args[path]}"

  curl -s -D - \
    -X "$method" \
    "${TARGET_BASE_URL}${path}"
}

# Extract the HTTP status from response
extract_status() {
  echo "$1" | head -n 1 | awk '{print $2}'
}

# Extract the JSON body (if present)
extract_body() {
  echo "$1" \
    | sed 's/\r$//' \
    | sed -n '/^$/,$p' \
    | tail -n +2
}

# Prints status + body
print_response() {
  local status="$1"
  local body="$2"

  echo
  echo "----------------- FAILURE RESPONSE -----------------" >&2
  echo "HTTP Status: $status" >&2
  echo "$body" >&2
  echo "----------------------------------------------------" >&2
  echo >&2
}

# Parse key=value arguments into a supplied associative array name
parse_named_args() {
  local -n _out=$1
  shift

  for kv in "$@"; do
    local key="${kv%%=*}"
    local val="${kv#*=}"
    # shellcheck disable=SC2004
    _out[$key]="$val"
  done
}
