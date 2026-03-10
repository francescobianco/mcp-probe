mcp_probe_clients_gemini_run() {
  local prompt="$1"
  local server="$2"
  local no_interactive="$3"
  local verbose="$4"

  if ! command -v gemini >/dev/null 2>&1; then
    mcp_probe_logging_error "gemini CLI not found. Install it from https://ai.google.dev/gemini-api/docs/gemini-cli"
    exit 1
  fi

  local args=("chat" "--prompt" "$prompt" "--tools" "mcp=$server")

  if [ -n "$no_interactive" ]; then
    args+=("--no-interactive")
  fi

  mcp_probe_logging_verbose "Running: gemini ${args[*]}"

  gemini "${args[@]}"
}
