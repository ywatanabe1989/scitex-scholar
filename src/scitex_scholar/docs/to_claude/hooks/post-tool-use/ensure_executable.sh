#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# Timestamp: "2025-12-24 (ywatanabe)"
# File: ~/.claude/hooks/ensure_executable.sh
# Description: Make script files executable after Write/Edit (PostToolUse hook)
#
# Supported extensions:
#   - Shell: .sh, .bash, .zsh, .src
#   - Python: .py
#   - Perl: .pl
#   - Ruby: .rb
#   - Node: .js (with shebang)
#   - Lua: .lua
#   - PHP: .php (with shebang)
#
# Exit codes:
#   0 = Success

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: should succeed on non-existent file (exit 0, no-op)
    echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/nonexistent_test_hook_file.py","content":"print(1)"},"tool_response":{"stdout":"","stderr":""},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" >/dev/null 2>&1 && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: non-existent file handled (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: should handle gracefully (exit $rc)"
    fi

    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

set -euo pipefail

# Check if hook is enabled via centralized project-switch/switch.yaml
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file_path from hook input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', '') or '')
" 2>/dev/null || echo "")

# If no file path or file doesn't exist, nothing to do
[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0

# Function to check if file has a shebang
has_shebang() {
    local file="$1"
    head -1 "$file" 2>/dev/null | grep -q '^#!' && return 0 || return 1
}

# Make executable based on file extension
case "$FILE_PATH" in
# Always make these executable
*.sh | *.bash | *.zsh | *.src)
    chmod +x "$FILE_PATH"
    ;;
*.py | *.pl | *.rb | *.lua)
    chmod +x "$FILE_PATH"
    ;;
# Only make these executable if they have a shebang
*.js | *.php | *.tcl | *.awk)
    if has_shebang "$FILE_PATH"; then
        chmod +x "$FILE_PATH"
    fi
    ;;
# Check for shebang in extensionless files
*)
    if has_shebang "$FILE_PATH"; then
        # Verify it's a known interpreter
        SHEBANG=$(head -1 "$FILE_PATH" 2>/dev/null || true)
        case "$SHEBANG" in
        *bash* | *sh* | *python* | *perl* | *ruby* | *node* | *lua* | *php* | *env\ *)
            chmod +x "$FILE_PATH"
            ;;
        esac
    fi
    ;;
esac

exit 0
