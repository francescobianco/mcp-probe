#!/usr/bin/env bash
# Mock LLM client used by integration tests.
# Behaves like `claude --print --mcp-server URL PROMPT`:
#   1. Initializes an MCP session with the server
#   2. Discovers available tools
#   3. Calls the first matching tool
#   4. Returns a response that mentions the tool name (required by --expect-tool)

set -e

server=""
prompt=""

while [ $# -gt 0 ]; do
  case "$1" in
    --print)     shift ;;
    --verbose)   shift ;;
    --mcp-server) server="$2"; shift 2 ;;
    *) prompt="$1"; shift ;;
  esac
done

if [ -z "$server" ]; then
  echo "mock_client: --mcp-server is required" >&2
  exit 1
fi

# Normalize URL
if [[ "$server" != http://* ]] && [[ "$server" != https://* ]]; then
  server="http://$server"
fi

mcp_post() {
  local payload
  payload=$1
  curl -sf -X POST "$server" \
    -H "Content-Type: application/json" \
    -d "$payload"
}

# 1. Initialize
mcp_post '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"mock-client","version":"1.0"}}}' > /dev/null

# 2. Discover tools
tools_resp=$(mcp_post '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}')
first_tool=$(echo "$tools_resp" | python3 -c "
import sys, json
tools = json.load(sys.stdin)['result']['tools']
print(tools[0]['name'] if tools else '')
" 2>/dev/null)

if [ -z "$first_tool" ]; then
  echo "mock_client: no tools found on MCP server" >&2
  exit 1
fi

# 3. Call the tool with sensible default arguments
call_resp=$(mcp_post "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"$first_tool\",\"arguments\":{\"timezone\":\"Asia/Shanghai\",\"country\":\"IT\",\"year\":2026}}}")
tool_result=$(echo "$call_resp" | python3 -c "
import sys, json
content = json.load(sys.stdin)['result']['content']
print(content[0]['text'] if content else '')
" 2>/dev/null)

# 4. Return a response that mentions the tool name
echo "I used the $first_tool tool to answer your question."
echo ""
echo "$tool_result"
