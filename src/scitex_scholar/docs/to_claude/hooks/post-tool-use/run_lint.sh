#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-02-06 20:01:09 (ywatanabe)"
# File: ./src/.claude/to_claude/hooks/post-tool-use/run_lint.sh

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
# Description: Run linters with auto-fix after Write/Edit (PostToolUse hook)
#
# Supported languages:
#   - Python: ruff check --fix (or flake8 as fallback)
#   - TypeScript/JavaScript: eslint --fix
#   - Emacs Lisp: byte-compile
#   - Shell: shellcheck
#   - HTML: htmlhint
#
# Exit codes:
#   0 = Success
#   1 = Warning (Claude sees feedback but continues)
#   2 = Error (Claude must fix)

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

# If no file path or file doesn't exist, nothing to lint
[ -n "$FILE_PATH" ] || exit 0
[ -f "$FILE_PATH" ] || exit 0

lint_python() {
    local file="$1"

    # SciTeX pattern check (runs first, blocks on structural errors)
    local stx_lint=""
    if command -v scitex-linter &>/dev/null; then
        stx_lint="scitex-linter"
    elif command -v scitex &>/dev/null && scitex linter --help &>/dev/null; then
        stx_lint="scitex linter"
    fi
    if [ -n "$stx_lint" ]; then
        $stx_lint check "$file" --severity error --no-color >&2 || exit 2
        $stx_lint check "$file" --severity warning --no-color >&2 || true
    fi

    # Standard linting
    if command -v ruff &>/dev/null; then
        # Show what ruff will auto-fix (so agents understand removals)
        local preview
        preview=$(ruff check --diff "$file" 2>/dev/null || true)
        if echo "$preview" | grep -q "^-.*import" 2>/dev/null; then
            echo "HINT: ruff --fix will remove import(s) from $file." >&2
            echo "If you added an import for code you haven't written yet," >&2
            echo "add both import and usage in a single edit to prevent removal." >&2
        fi
        ruff check --fix "$file" 2>&1
        return $?
    elif command -v flake8 &>/dev/null; then
        flake8 "$file" 2>&1
        return $?
    fi
    return 0
}

lint_js_ts() {
    local file="$1"
    if command -v eslint &>/dev/null; then
        eslint --fix "$file" 2>&1
        return $?
    fi
    return 0
}

lint_elisp() {
    local file="$1"
    local exit_code=0
    # Check for common Emacs Lisp issues using emacs batch mode
    if command -v emacs &>/dev/null; then
        # Basic syntax check via byte-compilation
        emacs --batch \
            --eval "(setq byte-compile-error-on-warn t)" \
            --eval "(byte-compile-file \"$file\")" \
            2>&1
        exit_code=$?
        # Clean up .elc file
        rm -f "${file}c" 2>/dev/null || true
    fi
    return $exit_code
}

lint_shell() {
    local file="$1"
    if command -v shellcheck &>/dev/null; then
        shellcheck "$file" >&2 # Send to stderr so Claude sees it
        return $?
    fi
    return 0
}

lint_html() {
    local file="$1"
    if command -v htmlhint &>/dev/null; then
        htmlhint "$file" 2>&1
        return $?
    fi
    return 0
}

# Lint based on file extension and exit with code 2 on errors
case "$FILE_PATH" in
*.py)
    lint_python "$FILE_PATH" || exit 2
    ;;
*.ts | *.tsx | *.js | *.jsx)
    lint_js_ts "$FILE_PATH" || exit 2
    ;;
*.el)
    lint_elisp "$FILE_PATH" || exit 2
    ;;
*.sh | *.src | *.bash)
    lint_shell "$FILE_PATH" || exit 2
    ;;
*.html | *.htm)
    lint_html "$FILE_PATH" || exit 2
    ;;
esac

exit 0

# EOF
