mcp_probe_clients_claude_run() {
  local prompt="$1"
  local server="$2"
  local no_interactive="$3"
  local verbose="$4"

  if ! command -v claude >/dev/null 2>&1; then
    mcp_probe_logging_error "claude CLI not found. Install it from https://claude.ai/cli"
    exit 1
  fi

  local args=("--print")

  if [ -n "$verbose" ]; then
    args+=("--verbose")
  fi

  mcp_probe_logging_verbose "Running: claude ${args[*]} --mcp-server \"$server\" \"$prompt\""

  claude "${args[@]}" --mcp-server "$server" "$prompt"
}
