#!/usr/bin/env bash

set +e   # do NOT stop on first failure

RED="\033[0;31m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

FAILED_FILES=()
TOTAL_FILES_COUNT=0
FAILED_FILES_COUNT=0
TOTAL_PASSED_TESTS=0
TOTAL_FAILED_TESTS=0
SUITE_START=$(date +%s)

echo "===================================================="
echo "                   Executing test suite"
echo "===================================================="
echo

############################################
# BUILD LIST OF TEST FILES
############################################

# List available test files
if [ "${1:-}" = "--list" ]; then
  find tests \
    -type f \
    -name "*.sh" \
    ! -name "run-tests.sh" \
    ! -path "*/utils/*" \
    | sort
  exit 0
fi

if [ -n "${1:-}" ]; then
  QUERY="$1"

  # Exact file match
  if [ -f "$QUERY" ]; then
    TEST_FILES=("$QUERY")

  # Partial path or filename match
  else
    mapfile -t TEST_FILES < <(
      find tests \
        -type f \
        -name "*.sh" \
        ! -path "*/utils/*" \
        | grep "$QUERY"
    )
  fi
else
  mapfile -t TEST_FILES < <(
    find tests \
      -type f \
      -name "*.sh" \
      ! -name "run-tests.sh" \
      ! -path "*/utils/*" \
      | sort
  )
fi

if [ ${#TEST_FILES[@]} -eq 0 ]; then
  echo -e "${RED}No matching test files found${NO_COLOR}"
  exit 1
fi

# Extract machine-readable test counts from test output.
# Usage: get_test_count "output" "KEY"
get_test_count() {
  local output="$1"
  local key="$2"

  local value
  value=$(echo "$output" | grep "^${key}=" | cut -d= -f2)

  echo "${value:-0}"
}

############################################
# RUN TEST FILES
############################################

for file in "${TEST_FILES[@]}"; do

  TOTAL_FILES_COUNT=$((TOTAL_FILES_COUNT + 1))

  echo "----------------------------------------------------"
  echo "▶ Running test: $file"
  START=$(date +%s)

  # Temp file is used here to allow:
  # - live streaming of test output
  # - reliable exit-code capture
  # - post-run parsing of machine-readable test metadata
  tmp_output=$(mktemp)

  # Stdout is captured for protocol parsing (test counts),
  # stderr is streamed live for human-readable logs.
  bash "$file" > "$tmp_output"
  EXIT_CODE=$?

  TEST_OUTPUT=$(cat "$tmp_output")
  rm -f "$tmp_output"

  FAILED_TESTS_COUNT_PER_FILE=$(get_test_count "$TEST_OUTPUT" "FAILED_TESTS_COUNT_PER_FILE")
  (( TOTAL_FAILED_TESTS += FAILED_TESTS_COUNT_PER_FILE ))

  PASSED_TESTS_COUNT_PER_FILE=$(get_test_count "$TEST_OUTPUT" "PASSED_TESTS_COUNT_PER_FILE")
  (( TOTAL_PASSED_TESTS += PASSED_TESTS_COUNT_PER_FILE ))

  END=$(date +%s)
  DURATION=$((END - START))

  if [ "$EXIT_CODE" -ne 0 ]; then
    echo
    echo -e "${RED}FAILED${NO_COLOR}: $file (${PASSED_TESTS_COUNT_PER_FILE} passed, ${FAILED_TESTS_COUNT_PER_FILE} failed, duration ${DURATION}s)"
    FAILED_FILES_COUNT=$((FAILED_FILES_COUNT + 1))
    FAILED_FILES+=("$file")
  else
    echo
    echo -e "${GREEN}PASSED${NO_COLOR}: $file (${PASSED_TESTS_COUNT_PER_FILE} passed, ${FAILED_TESTS_COUNT_PER_FILE} failed, duration ${DURATION}s)"
  fi

  echo
done

SUITE_END=$(date +%s)
SUITE_DURATION=$((SUITE_END - SUITE_START))
TOTAL_TESTS=$((TOTAL_PASSED_TESTS + TOTAL_FAILED_TESTS))

# Print human-readable output to stderr so it streams correctly in CI.
# Stdout is reserved for machine-readable test metadata.
{
  echo "===================================================="
  echo "                    Test Summary"
  echo "===================================================="
  echo
  echo -e "  Files    : $TOTAL_FILES_COUNT total, ${RED}$FAILED_FILES_COUNT failed${NO_COLOR}"
  echo -e "  Tests    : $TOTAL_TESTS total (${GREEN}$TOTAL_PASSED_TESTS passed${NO_COLOR}, ${RED}$TOTAL_FAILED_TESTS failed${NO_COLOR})"
  printf "  Duration : %dm %ds\n" $((SUITE_DURATION/60)) $((SUITE_DURATION%60))
  echo

  if [ $FAILED_FILES_COUNT -ne 0 ]; then
    echo "----------------------------------------------------"
    echo -e "${RED} Failed test files${NO_COLOR}"
    echo "----------------------------------------------------"
    for f in "${FAILED_FILES[@]}"; do
      echo "  - $f"
    done
    echo
  else
    echo -e "${GREEN}All tests completed successfully${NO_COLOR}"
  fi
} >&2

# Exit codes still go to the shell, not the stream
if [ $FAILED_FILES_COUNT -ne 0 ]; then
  exit 1
fi

exit 0
