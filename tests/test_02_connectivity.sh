#!/usr/bin/env bash
# Test: MCP server connectivity check
# Verifies exit code 3 when server is unreachable, and that the check
# passes when a TCP listener is actually up.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_02_connectivity"

TEST_PORT=19091

# Unreachable server → exit 3
"$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "test" 2>/dev/null
code=$?
assert_exit 3 "$code" "unreachable server exits 3"

# Reachable server: open a TCP listener, check connectivity passes (no client binary needed yet)
# We use a mock client that exits 0 immediately so mcp-probe proceeds past server check
MOCK_DIR=$(mktemp -d)
cat > "$MOCK_DIR/claude" <<'EOF'
#!/usr/bin/env bash
echo "mock claude output"
EOF
chmod +x "$MOCK_DIR/claude"

# Start a one-shot TCP listener on TEST_PORT
nc -l -p "$TEST_PORT" >/dev/null 2>&1 &
NC_PID=$!
sleep 0.3  # give nc time to bind

PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "test" 2>/dev/null
code=$?

wait "$NC_PID" 2>/dev/null || true
rm -rf "$MOCK_DIR"

assert_exit 0 "$code" "reachable server exits 0"

report
