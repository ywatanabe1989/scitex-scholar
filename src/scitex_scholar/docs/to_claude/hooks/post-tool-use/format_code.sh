#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-01-27 06:42:47 (ywatanabe)"
# File: ./src/.claude/to_claude/hooks/post-tool-use/format_code.sh

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$THIS_DIR/.$(basename "$0").log"
echo >"$LOG_PATH" 2>/dev/null || true

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
#!/usr/bin/env bash
# Description: Auto-format code after Write/Edit (PostToolUse hook)
#
# Supported languages:
#   - Python: ruff format (or black as fallback)
#   - TypeScript/JavaScript: prettier
#   - CSS: prettier
#   - Emacs Lisp: elinter
#   - Shell: shfmt
#   - HTML/Django templates: djlint (prettier as fallback for non-Django HTML)
#
# Exit codes:
#   0 = Success
#   1 = Warning (non-blocking)

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: non-existent file should pass gracefully (exit 0)
    echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/nonexistent_test_hook_file.py","content":"x=1"},"tool_response":{"stdout":"","stderr":""},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" >/dev/null 2>&1 && rc=$? || rc=$?
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

# Add tool paths if they exist
NPM_GLOBAL_BIN="$HOME/.npm-global/bin"
LOCAL_BIN="$HOME/.local/bin"
GOPATH_BIN="$(go env GOPATH 2>/dev/null || true)/bin"

[ -d "$NPM_GLOBAL_BIN" ] && export PATH="$NPM_GLOBAL_BIN:$PATH"
[ -d "$LOCAL_BIN" ] && export PATH="$LOCAL_BIN:$PATH"
[ -d "$GOPATH_BIN" ] && export PATH="$GOPATH_BIN:$PATH"

# Read hook input JSON from stdin
INPUT=$(cat)

# Extract file_path from hook input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', '') or '')
" 2>/dev/null || echo "")

# If no file path or file doesn't exist, nothing to format
[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0

format_python() {
    local file="$1"
    if command -v ruff &>/dev/null; then
        ruff format "$file" 2>/dev/null || true
    elif command -v black &>/dev/null; then
        black "$file" 2>/dev/null || true
    fi
}

format_js_ts() {
    local file="$1"
    if command -v prettier &>/dev/null; then
        prettier --write "$file" 2>/dev/null || true
    fi
}

format_elisp() {
    local file="$1"
    local elinter_path="$HOME/.emacs.d/lisp/elinter"
    if command -v emacs &>/dev/null && [ -d "$elinter_path" ]; then
        # Use elinter for formatting
        emacs --batch \
            --eval "(add-to-list 'load-path \"$elinter_path\")" \
            --eval "(require 'elinter)" \
            --eval "(find-file \"$file\")" \
            --eval "(elinter-lint-buffer)" \
            --eval "(save-buffer)" \
            2>/dev/null || true
    elif command -v emacs &>/dev/null; then
        # Fallback to basic indent
        emacs --batch "$file" \
            --eval "(indent-region (point-min) (point-max))" \
            --eval "(save-buffer)" \
            2>/dev/null || true
    fi
}

format_shell() {
    local file="$1"
    if command -v shfmt &>/dev/null; then
        shfmt -w -i 4 "$file" 2>/dev/null || true
    fi
}

format_html() {
    local file="$1"
    # Always use djlint for HTML - safer for Django/Jinja templates
    # and works fine for regular HTML too
    if command -v djlint &>/dev/null; then
        djlint --reformat "$file" 2>/dev/null || true
    fi
}

# Format based on file extension
case "$FILE_PATH" in
*.py)
    format_python "$FILE_PATH"
    ;;
*.ts | *.tsx | *.js | *.jsx)
    format_js_ts "$FILE_PATH"
    ;;
*.css)
    format_js_ts "$FILE_PATH"
    ;;
*.el)
    format_elisp "$FILE_PATH"
    ;;
*.sh | *.src | *.bash)
    format_shell "$FILE_PATH"
    ;;
*.html | *.htm)
    format_html "$FILE_PATH"
    ;;
esac

exit 0

# EOF
