# Auto-log: every test that sources assert.sh writes output to /tmp/mcp-probe-tests/<test>.log
_MCP_PROBE_LOG_DIR="/tmp/mcp-probe-tests"
mkdir -p "$_MCP_PROBE_LOG_DIR"
_MCP_PROBE_LOG_FILE="$_MCP_PROBE_LOG_DIR/$(basename "$0" .sh).log"
exec > >(tee "$_MCP_PROBE_LOG_FILE") 2>&1

TESTS_PASSED=0
TESTS_FAILED=0

assert_exit() {
  local expected
  local actual
  local label
  expected=$1
  actual=$2
  label="${3:-assert_exit}"

  if [ "$actual" -eq "$expected" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS  $label"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL  $label (expected exit $expected, got $actual)"
  fi
}

assert_contains() {
  local needle
  local haystack
  local label
  needle=$1
  haystack=$2
  label="${3:-assert_contains}"

  if echo "$haystack" | grep -qi "$needle"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "  PASS  $label"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "  FAIL  $label (expected to find '$needle' in output)"
  fi
}

report() {
  echo ""
  echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
  [ "$TESTS_FAILED" -eq 0 ]
}
