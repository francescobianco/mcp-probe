public ollama
public claude
public gemini
public openai

mcp_probe_clients_run() {
  local client="$1"
  local prompt="$2"
  local server="$3"
  local no_interactive="$4"
  local verbose="$5"

  mcp_probe_logging_verbose "Running client: $client"
  mcp_probe_logging_verbose "Prompt: $prompt"
  mcp_probe_logging_verbose "Server: $server"

  case "$client" in
    ollama)  mcp_probe_clients_ollama_run  "$prompt" "$server" "$no_interactive" "$verbose" ;;
    claude)  mcp_probe_clients_claude_run  "$prompt" "$server" "$no_interactive" "$verbose" ;;
    gemini)  mcp_probe_clients_gemini_run  "$prompt" "$server" "$no_interactive" "$verbose" ;;
    openai)  mcp_probe_clients_openai_run  "$prompt" "$server" "$no_interactive" "$verbose" ;;
    *)
      mcp_probe_logging_error "Unknown client: $client"
      mcp_probe_logging_error "Supported clients: ollama, claude, gemini, openai"
      exit 1 ;;
  esac
}
