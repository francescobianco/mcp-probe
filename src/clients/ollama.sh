MCP_PROBE_OLLAMA_MODEL="${MCP_PROBE_OLLAMA_MODEL:-llama3}"

mcp_probe_clients_ollama_run() {
  local prompt="$1"
  local server="$2"
  local no_interactive="$3"
  local verbose="$4"

  if ! command -v ollama >/dev/null 2>&1; then
    mcp_probe_logging_error "ollama not found. Install it from https://ollama.com"
    exit 1
  fi

  local full_prompt="You have access to MCP tools from $server. Use them to answer: $prompt"

  mcp_probe_logging_verbose "Model: $MCP_PROBE_OLLAMA_MODEL"
  mcp_probe_logging_verbose "Full prompt: $full_prompt"

  ollama run "$MCP_PROBE_OLLAMA_MODEL" "$full_prompt"
}
