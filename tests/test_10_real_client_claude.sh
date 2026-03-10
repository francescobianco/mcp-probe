#!/usr/bin/env bash
# Integration test: real claude CLI client against local mock MCP server
# Skips automatically if the claude CLI is not installed.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
SERVER_PY="$REPO_ROOT/tests/lib/server.py"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_10_real_client_claude"

# Skip if claude CLI is not available
if ! command -v claude >/dev/null 2>&1; then
  echo "  SKIP  claude CLI not found — install from https://claude.ai/cli"
  echo ""
  echo "Results: 0 passed, 0 failed (skipped)"
  exit 0
fi

TEST_PORT=19100

# Start the local MCP test server
python3 "$SERVER_PY" "$TEST_PORT" &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Wait for server to be ready
for i in $(seq 1 10); do
  if bash -c "echo >/dev/tcp/localhost/$TEST_PORT" 2>/dev/null; then break; fi
  sleep 0.2
done

# Run mcp-probe with the real claude client
# Unset CLAUDECODE to allow running claude inside another claude session
out=$(CLAUDECODE="" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "what time is it in Shanghai? use the get_world_time tool" \
  --expect-tool get_world_time 2>&1)
code=$?

assert_exit 0 "$code" "real claude: exits 0"
assert_contains "get_world_time" "$out" "real claude: tool name in output"
assert_contains "Shanghai" "$out" "real claude: Shanghai in output"

echo ""
echo "--- claude output ---"
echo "$out"
echo "---------------------"

report
