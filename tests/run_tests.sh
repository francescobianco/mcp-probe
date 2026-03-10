#!/usr/bin/env bash
# Test runner: builds mcp-probe then runs all test_*.sh files in order.
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Building mcp-probe..."
mush build

echo ""
echo "==> Running tests..."
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

for test_file in "$REPO_ROOT/tests"/test_*.sh; do
  chmod +x "$test_file"

  output=$(bash "$test_file" 2>&1)
  exit_code=$?

  echo "$output"

  pass=$(echo "$output" | grep -c "  PASS  " || true)
  fail=$(echo "$output" | grep -c "  FAIL  " || true)
  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))

  if [ "$exit_code" -ne 0 ] || [ "$fail" -gt 0 ]; then
    FAILED_SUITES+=("$(basename "$test_file")")
  fi

  echo ""
done

echo "=============================="
echo " Total:  $((TOTAL_PASS + TOTAL_FAIL)) tests"
echo " Passed: $TOTAL_PASS"
echo " Failed: $TOTAL_FAIL"

if [ "${#FAILED_SUITES[@]}" -gt 0 ]; then
  echo ""
  echo " Failed suites:"
  for s in "${FAILED_SUITES[@]}"; do
    echo "   - $s"
  done
  echo "=============================="
  exit 1
fi

echo "=============================="
exit 0
