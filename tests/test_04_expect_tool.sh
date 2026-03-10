#!/usr/bin/env bash
# Test: --expect-tool flag
# Verifies exit 0 when tool appears in output, exit 2 when it does not.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_04_expect_tool"

TEST_PORT=19093
MOCK_DIR=$(mktemp -d)

start_listener() {
  nc -l -p "$TEST_PORT" >/dev/null 2>&1 &
  echo $!
}

# Mock client that mentions get_world_time in its output
cat > "$MOCK_DIR/claude" <<'EOF'
#!/usr/bin/env bash
echo "I used the get_world_time tool to answer: current time in Asia/Shanghai is 10:30 CST"
EOF
chmod +x "$MOCK_DIR/claude"

# --expect-tool matches → exit 0
NC_PID=$(start_listener) ; sleep 0.2
PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "what time is it in china?" \
  --expect-tool get_world_time 2>/dev/null
code=$?
wait "$NC_PID" 2>/dev/null || true
assert_exit 0 "$code" "--expect-tool found in output exits 0"

# --expect-tool does NOT match → exit 2
NC_PID=$(start_listener) ; sleep 0.2
PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "what time is it in china?" \
  --expect-tool nonexistent_tool 2>/dev/null
code=$?
wait "$NC_PID" 2>/dev/null || true
assert_exit 2 "$code" "--expect-tool not found in output exits 2"

rm -rf "$MOCK_DIR"

report
