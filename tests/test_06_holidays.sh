#!/usr/bin/env bash
# Integration test: get_holidays tool
# Same server as test_05, but drives the mock client to call get_holidays.
# Uses a specialized mock client that calls get_holidays explicitly.
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
SERVER_PY="$REPO_ROOT/tests/lib/server.py"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_06_holidays"

TEST_PORT=19095
MOCK_DIR=$(mktemp -d)

# Specialized mock client that calls get_holidays
cat > "$MOCK_DIR/claude" <<'MOCK'
#!/usr/bin/env bash
server=""
while [ $# -gt 0 ]; do
  case "$1" in
    --print|--verbose) shift ;;
    --mcp-server) server="$2"; shift 2 ;;
    *) shift ;;
  esac
done
[[ "$server" != http://* ]] && [[ "$server" != https://* ]] && server="http://$server"

curl -sf -X POST "$server" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mock","version":"1"}}}' \
  > /dev/null

resp=$(curl -sf -X POST "$server" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_holidays","arguments":{"country":"IT","year":2026}}}')

result=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['content'][0]['text'])" 2>/dev/null)

echo "I used the get_holidays tool to list Italian public holidays."
echo ""
echo "$result"
MOCK
chmod +x "$MOCK_DIR/claude"

# Start MCP test server
python3 "$SERVER_PY" "$TEST_PORT" &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$MOCK_DIR"
}
trap cleanup EXIT

for i in $(seq 1 10); do
  if bash -c "echo >/dev/tcp/localhost/$TEST_PORT" 2>/dev/null; then break; fi
  sleep 0.2
done

out=$(PATH="$MOCK_DIR:$PATH" "$MCP_PROBE" \
  --client claude \
  --server "localhost:$TEST_PORT" \
  --prompt "quali sono le festività italiane nel 2026?" \
  --expect-tool get_holidays 2>&1)
code=$?

assert_exit 0 "$code" "holidays: exits 0"
assert_contains "get_holidays" "$out" "holidays: tool name in output"
assert_contains "Natale" "$out" "holidays: Christmas in result"
assert_contains "Capodanno" "$out" "holidays: New Year in result"
assert_contains "2026" "$out" "holidays: year in result"

report
