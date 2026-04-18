#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-13 (ywatanabe)"
# File: ./.claude/hooks/pre-tool-use/enforce_pytest_fullpath.sh

# Description: Enforces full path for pytest to avoid pwd mistakes.
# You may be in a different directory — always specify the full path.
# Blocks: pytest tests/, python -m pytest tests/, cd dir && pytest
# Allows: pytest /full/path/to/tests/, python -m pytest /full/path/tests/

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: pytest with relative path should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"pytest tests/"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: pytest relative path blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: pytest relative path should block (exit $rc)"
    fi

    # Test 2: pytest with full path should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"pytest /home/user/proj/tests/"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: pytest full path allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: pytest full path should pass (exit $rc)"
    fi

    # Test 3: python -m pytest with relative path should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"python -m pytest tests/ -x -q"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: python -m pytest relative blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: python -m pytest relative should block (exit $rc)"
    fi

    # Test 4: python -m pytest with full path should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"python -m pytest /home/user/proj/tests/ -x -q"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-4"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: python -m pytest full path allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: python -m pytest full path should pass (exit $rc)"
    fi

    # Test 5: cd dir && pytest should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"cd /some/dir && pytest tests/"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-5"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: cd && pytest blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: cd && pytest should block (exit $rc)"
    fi

    # Test 6: non-pytest command should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls -la"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-6"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: non-pytest allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: non-pytest should pass (exit $rc)"
    fi

    # Test 7: pytest with --rootdir should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"pytest --rootdir=/home/user/proj tests/"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-7"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: pytest --rootdir allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: pytest --rootdir should pass (exit $rc)"
    fi

    # Test 8: pytest with piped output and full path should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"python -m pytest /home/user/proj/tests/ -q 2>&1 | tail -5"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-8"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: piped pytest full path allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: piped pytest full path should pass (exit $rc)"
    fi

    # Test 9: pytest with no path args (just flags) should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"pytest -x -q --tb=short"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-9"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: pytest no path blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: pytest no path should block (exit $rc)"
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

# Allow bypass with comment: # hook-bypass: pytest-fullpath
if echo "$INPUT" | grep -qF 'hook-bypass: pytest-fullpath'; then
    exit 0
fi

# Parse tool name and command from JSON input
read -r TOOL_NAME COMMAND < <(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    tool = d.get("tool_name", "")
    ti = d.get("tool_input", {}) or {}
    cmd = ti.get("command", "") or ""
    cmd_flat = cmd.replace("\n", " ; ")
    print(f"{tool}\t{cmd_flat}")
except:
    print("\t")
' 2>/dev/null) || true

# Only check Bash tool
[[ "$TOOL_NAME" == "Bash" ]] || exit 0

# Exit if no command
[[ -n "$COMMAND" ]] || exit 0

# Enforce full path for pytest
# shellcheck disable=SC2016
echo "$COMMAND" | python3 -c '
import sys, re

command = sys.stdin.read().strip()

# Split on chain/pipe separators
segments = re.split(r"\s*(?:&&|\|\||\||;)\s*", command)

violations = []

for seg in segments:
    seg = seg.strip()
    if not seg:
        continue

    tokens = seg.split()
    if not tokens:
        continue

    # Detect pytest invocations
    # Pattern 1: pytest ...
    # Pattern 2: python -m pytest ...
    # Pattern 3: python3 -m pytest ...
    pytest_idx = None
    for i, t in enumerate(tokens):
        if t in ("pytest", "py.test") or t.endswith("/pytest"):
            pytest_idx = i
            break
        if t in ("python", "python3") and i + 2 < len(tokens):
            if tokens[i + 1] == "-m" and tokens[i + 2] in ("pytest", "py.test"):
                pytest_idx = i + 2
                break

    if pytest_idx is None:
        continue

    # Get args after pytest
    pytest_args = tokens[pytest_idx + 1:]

    # Check if --rootdir is specified (explicit root = OK)
    has_rootdir = any(a.startswith("--rootdir") for a in pytest_args)
    if has_rootdir:
        continue

    # Find path arguments (non-flag tokens)
    # Also skip known value-taking flags
    value_flags = {"-k", "-m", "-p", "-c", "-o", "--co", "--rootdir",
                   "--tb", "--override-ini", "--log-file", "--junitxml",
                   "--html", "--cov", "--cov-report", "--cov-config",
                   "--timeout", "-n", "--numprocesses"}
    path_args = []
    skip_next = False
    for a in pytest_args:
        if skip_next:
            skip_next = False
            continue
        if a in value_flags:
            skip_next = True
            continue
        if "=" in a and a.split("=")[0] in value_flags:
            continue
        if a.startswith("-"):
            continue
        # Skip shell redirections (2>&1, etc.)
        if re.match(r"^\d*>[>&]", a):
            continue
        # This is a path argument
        path_args.append(a)

    # If no path args at all, pytest uses cwd — block it
    if not path_args:
        violations.append(seg.strip())
        continue

    # Check each path arg — must be absolute (starts with /)
    for p in path_args:
        if not p.startswith("/"):
            violations.append(seg.strip())
            break

if violations:
    print("BLOCKED: pytest without full path", file=sys.stderr)
    print("", file=sys.stderr)
    print("You may be in a different directory than expected.", file=sys.stderr)
    print("Always use full paths with pytest.", file=sys.stderr)
    print("", file=sys.stderr)
    print("Detected:", file=sys.stderr)
    for v in violations:
        print(f"  {v[:120]}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Required: use full path, e.g.:", file=sys.stderr)
    print("  pytest /full/path/to/project/tests/", file=sys.stderr)
    print("  python -m pytest /full/path/to/project/tests/ -x -q", file=sys.stderr)
    print("  pytest --rootdir=/full/path/to/project tests/", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
'

exit $?

# EOF
