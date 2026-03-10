mcp_probe_args_parse() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        usage; exit 0 ;;
      -V|--version)
        echo "mcp-probe 0.1.0"; exit 0 ;;
      --prompt)
        prompt="$2"; shift ;;
      --server)
        server="$2"; shift ;;
      --client)
        client="$2"; shift ;;
      --expect-tool)
        expect_tool="$2"; shift ;;
      --no-interactive)
        no_interactive=true ;;
      --verbose)
        verbose=true ;;
      *)
        mcp_probe_logging_error "Unknown option: $1"
        usage
        exit 1 ;;
    esac
    shift
  done
}
