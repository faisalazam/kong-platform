#!/usr/bin/env bash

set +e

RED="\033[0;31m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

FAILED_FILES=()
FAILED_FILES_COUNT=0
TOTAL_FILES_COUNT=0
TOTAL_PASSED_TESTS=0
TOTAL_FAILED_TESTS=0

if [ "$1" = "--list" ] 2>/dev/null; then
  find tests \
    -type f \
    -name "*.sh" \
    ! -name "run-tests.sh" \
    ! -path "*/utils/*" \
    | sort
  exit 0
fi

if [ -n "${1:-}" ]; then
  mapfile -t TEST_FILES < <(
    find tests \
      -type f \
      -name "*.sh" \
      ! -path "*/utils/*" \
      | grep "$1"
  )
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

for file in "${TEST_FILES[@]}"; do

  TOTAL_FILES_COUNT=$((TOTAL_FILES_COUNT+1))

  echo "----------------------------------------"
  echo "▶ Running $file"

  tmp_output=$(mktemp)

  bash "$file" > "$tmp_output"
  EXIT_CODE=$?

  rm -f "$tmp_output"

  if [ "$EXIT_CODE" -ne 0 ]; then
    TOTAL_FAILED_TESTS=$((TOTAL_FAILED_TESTS + 1))
  else
    TOTAL_PASSED_TESTS=$((TOTAL_PASSED_TESTS + 1))
  fi

  if [ "$EXIT_CODE" -ne 0 ]; then
    FAILED_FILES_COUNT=$((FAILED_FILES_COUNT+1))
    FAILED_FILES+=("$file")

    echo -e "${RED}FAILED${NO_COLOR}: $file"
  else
    echo -e "${GREEN}PASSED${NO_COLOR}: $file"
  fi

  echo
done

echo "========================================"
echo "              Test Summary              "
echo "========================================"
echo

echo "Files  : $TOTAL_FILES_COUNT"
echo "Passed : $TOTAL_PASSED_TESTS"
echo "Failed : $TOTAL_FAILED_TESTS"
echo

if [ "$FAILED_FILES_COUNT" -ne 0 ]; then
  echo -e "${RED}Failed files:${NO_COLOR}"

  for f in "${FAILED_FILES[@]}"; do
    echo "  - $f"
  done

  exit 1
fi

echo -e "${GREEN}All tests passed${NO_COLOR}"
