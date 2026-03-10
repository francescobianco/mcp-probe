#!/usr/bin/env bash
# Test: client dispatch
# Verifies unknown client exits 1, and that each known client wrapper
# is dispatched correctly via mock binaries.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_03_clients"

TEST_PORT=19092
MOCK_DIR=$(mktemp -d)

# Start TCP listener so server check passes (one connection per test)
start_listener() {
  nc -l -p "$TEST_PORT" >/dev/null 2>&1 &
  echo $!
}

make_mock_client() {
  local name
  name=$1
  cat > "$MOCK_DIR/$name" <<EOF
#!/usr/bin/env bash
echo "mock $name output: used get_world_time tool"
EOF
  chmod +x "$MOCK_DIR/$name"
}

# Unknown client → exit 1
NC_PID=$(start_listener) ; sleep 0.2
PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client unknown_xyz \
  --server "localhost:$TEST_PORT" \
  --prompt "test" 2>/dev/null
code=$?
wait "$NC_PID" 2>/dev/null || true
assert_exit 1 "$code" "unknown client exits 1"

# Claude, ollama, gemini → mock binaries in PATH
for client in claude ollama gemini; do
  make_mock_client "$client"
  NC_PID=$(start_listener) ; sleep 0.2
  PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
    --client "$client" \
    --server "localhost:$TEST_PORT" \
    --prompt "test" 2>/dev/null
  code=$?
  wait "$NC_PID" 2>/dev/null || true
  assert_exit 0 "$code" "client $client dispatched and exits 0"
done

# OpenAI → calls curl directly; mock curl to return a valid Responses API payload
cat > "$MOCK_DIR/curl" <<'EOF'
#!/usr/bin/env bash
echo '{"output":[{"type":"message","content":[{"type":"output_text","text":"mock openai output: used get_world_time tool"}]}]}'
EOF
chmod +x "$MOCK_DIR/curl"

NC_PID=$(start_listener) ; sleep 0.2
OPENAI_API_KEY=test-key PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client openai \
  --server "localhost:$TEST_PORT" \
  --prompt "test" 2>/dev/null
code=$?
wait "$NC_PID" 2>/dev/null || true
assert_exit 0 "$code" "client openai dispatched and exits 0"

rm -rf "$MOCK_DIR"

report
