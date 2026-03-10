MCP_PROBE_OPENAI_MODEL="${MCP_PROBE_OPENAI_MODEL:-gpt-4o}"

mcp_probe_clients_openai_run() {
  local prompt="$1"
  local server="$2"
  local no_interactive="$3"
  local verbose="$4"

  if [ -z "$OPENAI_API_KEY" ]; then
    mcp_probe_logging_error "OPENAI_API_KEY environment variable is not set"
    exit 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    mcp_probe_logging_error "curl not found"
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    mcp_probe_logging_error "jq not found. Install it to use the openai client"
    exit 1
  fi

  local mcp_server_url="$server"
  # Normalize: ensure protocol prefix
  if [[ "$mcp_server_url" != http://* ]] && [[ "$mcp_server_url" != https://* ]]; then
    mcp_server_url="http://$mcp_server_url"
  fi

  local payload
  payload=$(jq -n \
    --arg model "$MCP_PROBE_OPENAI_MODEL" \
    --arg prompt "$prompt" \
    --arg server "$mcp_server_url" \
    '{
      model: $model,
      input: $prompt,
      tools: [{
        type: "mcp",
        server_label: "mcp-probe-server",
        server_url: $server,
        require_approval: "never"
      }]
    }')

  mcp_probe_logging_verbose "OpenAI model: $MCP_PROBE_OPENAI_MODEL"
  mcp_probe_logging_verbose "Payload: $payload"

  local response
  response=$(curl -s -X POST "https://api.openai.com/v1/responses" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")

  if [ $? -ne 0 ]; then
    mcp_probe_logging_error "Failed to reach OpenAI API"
    exit 1
  fi

  mcp_probe_logging_verbose "Raw response: $response"

  # Extract text output from response
  local text
  text=$(echo "$response" | jq -r '
    .output[]
    | select(.type == "message")
    | .content[]
    | select(.type == "output_text")
    | .text' 2>/dev/null)

  if [ -z "$text" ]; then
    # Fallback: print full response if parsing fails
    echo "$response"
  else
    echo "$text"
  fi

  # Check for API errors
  local error
  error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
  if [ -n "$error" ]; then
    mcp_probe_logging_error "OpenAI API error: $error"
    exit 1
  fi
}
