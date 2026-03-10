mcp_probe_logging_info() {
  echo "[mcp-probe] $*" >&2
}

mcp_probe_logging_error() {
  echo "[mcp-probe] ERROR: $*" >&2
}

mcp_probe_logging_verbose() {
  if [ -n "$verbose" ]; then
    echo "[mcp-probe] DEBUG: $*" >&2
  fi
}
