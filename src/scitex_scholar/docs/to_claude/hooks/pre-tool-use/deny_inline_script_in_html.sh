#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-01-27 06:45:04 (ywatanabe)"
# File: ./src/.claude/to_claude/hooks/pre-tool-use/deny_inline_script_in_html.sh

# Description: Blocks inline <script> tags in HTML files
# Allows: <script src="..."></script> (external references)
# Blocks: <script>...code...</script> (inline code)

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

    # Test 2: inline script in HTML should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.html","content":"<html><script>alert(1)</script></html>"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: inline script blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: inline script should block (exit $rc)"
    fi

    # Test 3: inline script with hook-bypass should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.html","content":"<!-- hook-bypass: inline-script -->\n<html><script>var x=1</script></html>"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: hook-bypass allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: hook-bypass should pass (exit $rc)"
    fi

    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$THIS_DIR/.$(basename "$0").log"
echo >"$LOG_PATH" 2>/dev/null || true

# Check if hook is enabled
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

# Read input from stdin
INPUT="$(cat)"

# Parse tool name, file_path, and content from JSON input
read -r TOOL_NAME FILE_PATH CONTENT < <(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    tool = d.get("tool_name", "")
    ti = d.get("tool_input", {}) or {}
    fp = ti.get("file_path", "") or ""
    # For Write: content field, for Edit: new_string field
    content = ti.get("content", "") or ti.get("new_string", "") or ""
    # Escape for shell (replace newlines with space for detection)
    content_escaped = content.replace("\n", " ")
    print(f"{tool}\t{fp}\t{content_escaped}")
except:
    print("\t\t")
' 2>/dev/null) || true

# Only check Write and Edit tools
[[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]] || exit 0

# Only check HTML files
case "$FILE_PATH" in
*.html | *.htm) ;;
*) exit 0 ;;
esac

# Allow bypass with explicit comment: <!-- hook-bypass: inline-script -->
# Use for legitimate cases like critical JS (feature detection, polyfills)
if echo "$CONTENT" | grep -qF 'hook-bypass: inline-script'; then
    exit 0
fi

# Check for inline script tags (script tags with content, not just src references)
# Pattern: <script> followed by anything other than just whitespace and </script>
if echo "$CONTENT" | grep -qiE '<script[^>]*>[^<]+</script>'; then
    echo "BLOCKED: Inline <script> tags detected in HTML file" >&2
    echo "" >&2
    echo "File: $FILE_PATH" >&2
    echo "" >&2
    echo "Best practice:" >&2
    echo "  - Move JavaScript to external .js files" >&2
    echo "  - Use <script src=\"path/to/file.js\"></script>" >&2
    echo "" >&2
    echo "Why: Separation of concerns improves maintainability," >&2
    echo "     enables caching, and follows Django/web best practices." >&2
    echo "" >&2
    echo "Bypass: Add <!-- hook-bypass: inline-script --> to the file" >&2
    echo "        if this is critical JS (feature detection, polyfills)." >&2
    exit 2
fi

exit 0

# EOF
