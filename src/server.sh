mcp_probe_server_check() {
  local server="$1"

  # Normalize: strip protocol prefix for host:port extraction
  local host_port
  host_port="${server#http://}"
  host_port="${host_port#https://}"
  host_port="${host_port%%/*}"

  local host="${host_port%%:*}"
  local port="${host_port##*:}"

  # If no port extracted (no colon), default to 80
  if [ "$host" = "$port" ]; then
    port=80
  fi

  mcp_probe_logging_verbose "Checking MCP server at $host:$port..."

  if ! timeout 5 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
    mcp_probe_logging_error "MCP server not reachable: $server"
    exit 3
  fi

  mcp_probe_logging_verbose "MCP server is reachable."
}
