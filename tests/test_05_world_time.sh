#!/usr/bin/env bash
# Integration test: get_world_time tool
# Starts the local MCP test server, runs mcp-probe with the mock client,
# and verifies that the tool is discovered, called, and its result returned.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
SERVER_PY="$REPO_ROOT/tests/lib/server.py"
MOCK_CLIENT="$REPO_ROOT/tests/lib/mock_client.sh"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_05_world_time"

TEST_PORT=19094
MOCK_DIR=$(mktemp -d)

# Place the mock client as 'claude' in a temp dir
cp "$MOCK_CLIENT" "$MOCK_DIR/claude"
chmod +x "$MOCK_DIR/claude"

# Start the MCP test server
python3 "$SERVER_PY" "$TEST_PORT" &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$MOCK_DIR"
}
trap cleanup EXIT

# Wait for server to be ready
for i in $(seq 1 10); do
  if bash -c "echo >/dev/tcp/localhost/$TEST_PORT" 2>/dev/null; then break; fi
  sleep 0.2
done

# Run mcp-probe: expect the get_world_time tool to be used
out=$(PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "what time is it in Shanghai?" \
  --expect-tool get_world_time 2>&1)
code=$?

assert_exit 0 "$code" "world time: exits 0"
assert_contains "get_world_time" "$out" "world time: tool name in output"
assert_contains "Asia/Shanghai" "$out" "world time: timezone in result"
assert_contains "Current time" "$out" "world time: result text present"

report
