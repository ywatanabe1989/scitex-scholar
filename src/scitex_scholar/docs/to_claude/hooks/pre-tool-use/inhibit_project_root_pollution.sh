#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-01-04 19:33:24 (ywatanabe)"
# File: ./.claude/hooks/pre-tool-use/inhibit_project_root_pollution.sh

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

# Description: Prevents project root pollution by enforcing whitelist policy

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
CRITERIA_FILE="$(dirname "$THIS_DIR")/project-switch/project-root-pollution-criteria.yaml"

# Read input from stdin
INPUT="$(cat)"

# Allow bypass with comment in content: hook-bypass: root-pollution
if echo "$INPUT" | grep -qF 'hook-bypass: root-pollution'; then
    exit 0
fi

# Parse file_path from JSON input
FILE_PATH=$(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    print(ti.get("file_path", "") or "")
except:
    print("")
' 2>/dev/null) || true

# Exit if no file path
[ -n "$FILE_PATH" ] || exit 0

# Get git root to determine project root
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# Get absolute path of target file
if [[ "$FILE_PATH" == /* ]]; then
    ABS_PATH="$FILE_PATH"
else
    ABS_PATH="$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd)/$(basename "$FILE_PATH")" 2>/dev/null || ABS_PATH="$PWD/$FILE_PATH"
fi

# Get directory of the file
FILE_DIR="$(dirname "$ABS_PATH")"

# Only check files directly in project root
[ "$FILE_DIR" = "$GIT_ROOT" ] || exit 0

# Get basename for matching
BASENAME="$(basename "$FILE_PATH")"

# If no criteria file configured, allow all (no restrictions)
[ -f "$CRITERIA_FILE" ] || exit 0

# Load criteria and check whitelist
python3 - "$CRITERIA_FILE" "$BASENAME" <<'PYTHON_SCRIPT'
import sys
import fnmatch
import os

criteria_file = sys.argv[1]
basename = sys.argv[2]

# No criteria file = allow all
if not os.path.exists(criteria_file):
    sys.exit(0)

# Default criteria
whitelist = []
whitelist_patterns = []
relocations = {}
custom_messages = {}

# Try to load YAML criteria
try:
    import yaml
    if os.path.exists(criteria_file):
        with open(criteria_file) as f:
            data = yaml.safe_load(f)
            whitelist = data.get('whitelist', []) or []
            whitelist_patterns = data.get('whitelist_patterns', []) or []
            relocations = data.get('relocations', {}) or {}
            custom_messages = data.get('custom_messages', {}) or {}
except ImportError:
    # Fallback: parse YAML manually for simple structure
    if os.path.exists(criteria_file):
        with open(criteria_file) as f:
            content = f.read()
            in_whitelist = False
            in_patterns = False
            for line in content.split('\n'):
                stripped = line.strip()
                if line.startswith('whitelist:'):
                    in_whitelist = True
                    in_patterns = False
                elif line.startswith('whitelist_patterns:'):
                    in_whitelist = False
                    in_patterns = True
                elif line.startswith('relocations:') or line.startswith('custom_messages:'):
                    in_whitelist = False
                    in_patterns = False
                elif stripped.startswith('- ') and in_whitelist:
                    item = stripped[2:].strip().strip('"').strip("'")
                    whitelist.append(item)
                elif stripped.startswith('- ') and in_patterns:
                    item = stripped[2:].strip().strip('"').strip("'")
                    whitelist_patterns.append(item)
except Exception:
    pass

# Check exact whitelist match
if basename in whitelist:
    sys.exit(0)

# Check pattern matches
for pattern in whitelist_patterns:
    if fnmatch.fnmatch(basename, pattern):
        sys.exit(0)

# Not allowed - find custom message first, then relocation suggestion
custom_msg = None
for pattern, msg in custom_messages.items():
    if fnmatch.fnmatch(basename, pattern) or basename == pattern:
        custom_msg = msg
        break

suggestion = relocations.get('_default', './.claude/ or appropriate subdirectory')
for pattern, loc in relocations.items():
    if pattern != '_default' and fnmatch.fnmatch(basename, pattern):
        suggestion = loc
        break

# Output descriptive message to stderr (readable by both humans and AI agents)
print(f"Project root pollution blocked: {basename}", file=sys.stderr)
print(f"  Not in whitelist - keeping project root clean", file=sys.stderr)
print(f"", file=sys.stderr)

if custom_msg:
    print(f"Note: {custom_msg}", file=sys.stderr)
    print(f"", file=sys.stderr)

print(f"Suggested location:", file=sys.stderr)
print(f"  {suggestion}", file=sys.stderr)
print(f"", file=sys.stderr)

print(f"Action required:", file=sys.stderr)
print(f"  1. Move file to suggested location, OR", file=sys.stderr)
print(f"  2. Add to whitelist in: {criteria_file}", file=sys.stderr)

sys.exit(2)
PYTHON_SCRIPT

# EOF
