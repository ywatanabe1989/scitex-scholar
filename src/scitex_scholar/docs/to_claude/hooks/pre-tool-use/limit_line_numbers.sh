#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-04-10 09:13:10 (ywatanabe)"
# File: ./src/.claude/to_claude/hooks/pre-tool-use/limit_line_numbers.sh

ORIG_DIR="$(pwd)"
THIS_DIR="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
LOG_PATH="$THIS_DIR/.$(basename $0).log"
echo > "$LOG_PATH"

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"

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

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$THIS_DIR/.$(basename "$0").log"
echo >"$LOG_PATH" 2>/dev/null || true

# Description: Claude Code hook to enforce file size limits

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: small file should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test_hook.py","content":"print(1)\nprint(2)\n"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: small file allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: small file should pass (exit $rc)"
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

# Read input early for bypass check
INPUT="$(cat)"

# Allow bypass with comment in content: hook-bypass: line-limit
if echo "$INPUT" | grep -qF 'hook-bypass: line-limit'; then
    exit 0
fi

# Thresholds (in lines)
THRESHOLD_TS=512
THRESHOLD_PY=512
THRESHOLD_CSS=512
THRESHOLD_HTML=1024
THRESHOLD_MARKDOWN=512
REFACTORING_MD="$GIT_ROOT/GITIGNORED/REFACTORING.md"

# Parse JSON using Python - outputs tab-separated values with line counts
# Capture output and exit code separately to properly handle parse failures
PARSED_OUTPUT=""
if ! PARSED_OUTPUT=$(echo "$INPUT" | python3 -c '
import json, sys
d = json.load(sys.stdin)
ti = d.get("tool_input", {}) or {}

def get_val(k):
    return (ti.get(k) or "").replace("\r\n", "\n")

file_path = get_val("file_path")
content = get_val("content")
old_string = get_val("old_string")
new_string = get_val("new_string")

# Count lines (add 1 if non-empty and no trailing newline for accurate count)
def count_lines(s):
    if not s:
        return 0
    return s.count("\n") + (1 if not s.endswith("\n") else 0)

content_lines = count_lines(content) if content else -1
old_lines = count_lines(old_string) if old_string else -1
new_lines = count_lines(new_string) if new_string else -1

print(f"{file_path}\t{content_lines}\t{old_lines}\t{new_lines}")
' 2>/dev/null); then
    # Failed to parse JSON - approve silently (non-monitored tool or malformed input)
    exit 0
fi

read -r FILE_PATH CONTENT_LINES OLD_LINES NEW_LINES <<<"$PARSED_OUTPUT"

# Exit if no file path (non-file operation or unsupported tool)
[ -n "$FILE_PATH" ] || exit 0

# Skip test files and CHANGELOG.md
case "$FILE_PATH" in
*/tests/* | */test_*.py | *_test.py | */CHANGELOG.md | CHANGELOG.md) exit 0 ;;
esac

# Determine threshold based on extension
ext="${FILE_PATH##*.}"
case "$ext" in
py | el | sh | src) THRESHOLD="$THRESHOLD_PY" ;;
ts | tsx | js | jsx) THRESHOLD="$THRESHOLD_TS" ;;
css) THRESHOLD="$THRESHOLD_CSS" ;;
html | htm) THRESHOLD="$THRESHOLD_HTML" ;;
md) THRESHOLD="$THRESHOLD_MARKDOWN" ;;
*) exit 0 ;;
esac

# Get current file line count
CURRENT=0
if [ -f "$FILE_PATH" ]; then
    CURRENT="$(wc -l <"$FILE_PATH" | tr -d ' ')"
fi

# Calculate proposed line count
if [ "$CONTENT_LINES" -ge 0 ]; then
    # Write operation: content specifies full file
    PROPOSED="$CONTENT_LINES"
elif [ "$OLD_LINES" -ge 0 ]; then
    # Edit operation: calculate delta
    PROPOSED=$((CURRENT - OLD_LINES + NEW_LINES))
    [ "$PROPOSED" -lt 0 ] && PROPOSED=0
else
    PROPOSED="$CURRENT"
fi

# Allow incremental reduction if currently over limit and edit shrinks it
if [ "$CURRENT" -gt "$THRESHOLD" ] && [ "$PROPOSED" -lt "$CURRENT" ]; then
    exit 0
fi

# Active refactoring — bypass line limit
if [ -f "$REFACTORING_MD" ]; then
    exit 0
fi

# Block any change that leaves file above threshold
if [ "$PROPOSED" -gt "$THRESHOLD" ]; then
    {
        echo "File size violation: $FILE_PATH"
        echo "  Lines: $PROPOSED (max: $THRESHOLD for .$ext)"
        echo ""
        echo "Rules:"
        echo "  - PY/SH/EL: max $THRESHOLD_PY lines"
        echo "  - TS/JS:    max $THRESHOLD_TS lines"
        echo "  - CSS:      max $THRESHOLD_CSS lines"
        echo "  - HTML:     max $THRESHOLD_HTML lines"
        echo "  - MD:       max $THRESHOLD_MARKDOWN lines"
        echo ""
        echo "Refactoring required:"
        echo "  0.  Prioritize this refactoring over any tasks assigned now."
        echo "  1.  Document context in $REFACTORING_MD"
        echo "  1.1 When $REFACTORING_MD exists, this hook itself is bypassed."
        echo "  2.  Refactor into small files, preparing thin orchestrator."
        echo "  2.1 Following convensions in the project"
        echo "  2.2 Use subdirectories wisely"
        echo "  2.3 DO NOT PATCH WITH WORKAROUND LIKE DELETING LINES"
        echo "  2.4 Linters may add additional lines"
        echo "  3.  Delete $REFACTORING_MD after completion"
    } >&2
    exit 2
fi

exit 0

# EOF