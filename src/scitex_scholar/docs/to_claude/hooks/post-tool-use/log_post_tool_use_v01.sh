#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-01-09 16:50:10 (ywatanabe)"
# File: ./.claude/hooks/post-tool-use/log_post_tool_use.sh

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$THIS_DIR/.$(basename "$0").log"
echo >"$LOG_PATH" 2>/dev/null || true

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo_info() { echo -e "${GRAY}INFO: $1${NC}"; }
echo_success() { echo -e "${GREEN}SUCC: $1${NC}"; }
echo_warning() { echo -e "${YELLOW}WARN: $1${NC}"; }
echo_error() { echo -e "${RED}ERRO: $1${NC}"; }
echo_header() { echo_info "=== $1 ==="; }
# ---------------------------------------

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: should always pass (exit 0) - logging only
    echo '{"tool_name":"Bash","tool_input":{"command":"echo test"},"tool_response":{"stdout":"hello","stderr":""},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" >/dev/null 2>&1 && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: logging succeeded (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: logging failed (exit $rc)"
    fi

    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

# Check if hook is enabled via centralized project-switch/switch.yaml
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

# Description: Logs tool output (stdout/stderr) after execution

# Log file location - use GIT_ROOT if available, fallback to home
if [[ -n "$GIT_ROOT" ]]; then
    LOG_DIR="$GIT_ROOT/logs/"
else
    LOG_DIR="$HOME/.claude/logs/"
fi
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/claude-code.log"

echo "$0" >>"$LOG_FILE"

# Read input from stdin
INPUT="$(cat)"

# DEBUG: Dump raw JSON to debug file
DEBUG_FILE="$LOG_DIR/claude-code-debug.json"
echo "=== $(date) ===" >>"$DEBUG_FILE"
echo "$INPUT" >>"$DEBUG_FILE"

# Parse and log using Python for reliable JSON handling
# Pass input via environment variable to avoid pipe/heredoc conflict
INPUT="$INPUT" python3 - "$LOG_FILE" <<'PYTHON_SCRIPT'
import json
import sys
import os

input_data = os.environ.get("INPUT", "{}")
log_file = sys.argv[1]
MAX_STDOUT = 1500
MAX_STDERR = 500

try:
    d = json.loads(input_data)
    tool_name = d.get("tool_name", "unknown")
    tool_response = d.get("tool_response", {})

    lines = []

    # Handle different response formats
    if isinstance(tool_response, str):
        stdout = tool_response
        stderr = ""
        exit_code = None
    elif isinstance(tool_response, dict):
        stdout = tool_response.get("stdout", tool_response.get("output", ""))
        stderr = tool_response.get("stderr", "")
        exit_code = tool_response.get("exit_code", tool_response.get("exitCode"))
    else:
        stdout = str(tool_response) if tool_response else ""
        stderr = ""
        exit_code = None

    # Convert to string if needed
    stdout = str(stdout) if stdout else ""
    stderr = str(stderr) if stderr else ""

    # Add exit code for Bash commands
    if exit_code is not None and tool_name == "Bash":
        lines.append(f"Exit: {exit_code}")

    # Log stdout (truncated)
    if stdout and stdout not in ("None", "", "null"):
        truncated = len(stdout) > MAX_STDOUT
        stdout_display = stdout[:MAX_STDOUT]
        lines.append("--- stdout ---")
        lines.append(stdout_display)
        if truncated:
            lines.append(f"... [truncated, {len(stdout)} chars total]")

    # Log stderr
    if stderr and stderr not in ("None", "", "null"):
        truncated = len(stderr) > MAX_STDERR
        stderr_display = stderr[:MAX_STDERR]
        lines.append("--- stderr ---")
        lines.append(stderr_display)
        if truncated:
            lines.append(f"... [truncated]")

    # Write to log if there's content
    if lines:
        with open(log_file, "a") as f:
            f.write("\n".join(lines) + "\n")

except Exception as e:
    with open(log_file, "a") as f:
        f.write(f"PostHook Error: {e}\n")

PYTHON_SCRIPT

# Always exit 0 - logging hook should never block
exit 0

# EOF
