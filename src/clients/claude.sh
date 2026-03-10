mcp_probe_clients_claude_run() {
  local prompt="$1"
  local server="$2"
  local no_interactive="$3"
  local verbose="$4"

  if ! command -v claude >/dev/null 2>&1; then
    mcp_probe_logging_error "claude CLI not found. Install it from https://claude.ai/cli"
    exit 1
  fi

  # Normalize URL
  local server_url
  server_url="$server"
  if [[ "$server_url" != http://* ]] && [[ "$server_url" != https://* ]]; then
    server_url="http://$server_url"
  fi

  # Build --mcp-config inline JSON for HTTP transport
  local mcp_config
  mcp_config="{\"mcpServers\":{\"mcp-probe-server\":{\"url\":\"$server_url\",\"type\":\"http\"}}}"

  local args=("-p" "--dangerously-skip-permissions" "--output-format" "stream-json" "--verbose" "--strict-mcp-config")

  if [ -n "$verbose" ]; then
    args+=("--verbose")
  fi

  mcp_probe_logging_verbose "Running: claude ${args[*]} --mcp-config '...' \"$prompt\""

  local raw
  raw=$(claude "${args[@]}" "$prompt" --mcp-config "$mcp_config" 2>/dev/null)
  local exit_code=$?

  # Extract tool names from stream-json events (mcp__server__toolname → toolname)
  local tools_used
  tools_used=$(echo "$raw" | python3 -c "
import sys, json
tools = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'assistant':
            for block in obj.get('message', {}).get('content', []):
                if block.get('type') == 'tool_use':
                    name = block.get('name', '')
                    parts = name.split('__')
                    tools.append(parts[-1] if len(parts) >= 3 else name)
    except Exception:
        pass
for t in tools:
    print(t)
" 2>/dev/null)

  # Extract final text result from stream-json
  local text_output
  text_output=$(echo "$raw" | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
        if obj.get('type') == 'result':
            print(obj.get('result', ''))
            break
    except Exception:
        pass
" 2>/dev/null)

  # Print tool names first (so --expect-tool grep finds them), then the response
  if [ -n "$tools_used" ]; then
    echo "$tools_used"
    echo ""
  fi
  echo "$text_output"

  return $exit_code
}
