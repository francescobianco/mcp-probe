#!/usr/bin/env bash
# Test: CLI flags — --help, --version, missing required arguments
# Tests check non-zero exits explicitly — do not use set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MCP_PROBE="$REPO_ROOT/target/debug/mcp-probe"
# shellcheck source=lib/assert.sh
source "$REPO_ROOT/tests/lib/assert.sh"

echo "==> test_01_cli"

# --help exits 0 and prints usage
out=$("$MCP_PROBE" --help 2>&1) ; code=$?
assert_exit 0 "$code" "--help exits 0"
assert_contains "Usage:" "$out" "--help prints usage"

# --version exits 0
out=$("$MCP_PROBE" --version 2>&1) ; code=$?
assert_exit 0 "$code" "--version exits 0"
assert_contains "mcp-probe" "$out" "--version prints name"

# missing --prompt → exit 1
"$MCP_PROBE" --server localhost:9090 2>/dev/null ; code=$?
assert_exit 1 "$code" "missing --prompt exits 1"

# missing --server → exit 1
"$MCP_PROBE" --prompt "test" 2>/dev/null ; code=$?
assert_exit 1 "$code" "missing --server exits 1"

# unknown flag → exit 1
"$MCP_PROBE" --unknown-flag 2>/dev/null ; code=$?
assert_exit 1 "$code" "unknown flag exits 1"

report
