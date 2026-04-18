#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-13 (ywatanabe)"
# File: ./.claude/hooks/pre-tool-use/enforce_git_dash_C.sh

# Description: Enforces git -C /full/path on ALL git commands.
# You may be in a different directory than expected — always be explicit.
# Blocks: git status, git log, cd /dir && git ...
# Allows: git -C /full/path status, git --version, git help

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: git without -C should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git status"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: git without -C blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: git without -C should block (exit $rc)"
    fi

    # Test 2: git -C should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git -C /home/user/project log --oneline -3"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: git -C allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: git -C should pass (exit $rc)"
    fi

    # Test 3: cd dir && git should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"cd /some/repo && git status"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: cd && git blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: cd && git should block (exit $rc)"
    fi

    # Test 4: git --version should pass (no repo needed)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git --version"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-4"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: git --version allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: git --version should pass (exit $rc)"
    fi

    # Test 5: git help should pass (no repo needed)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git help log"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-5"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: git help allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: git help should pass (exit $rc)"
    fi

    # Test 6: non-git command should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls -la"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-6"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: non-git command allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: non-git command should pass (exit $rc)"
    fi

    # Test 7: git -C with ~ should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git -C ~/.dotfiles status"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-7"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: git -C ~/path allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: git -C ~/path should pass (exit $rc)"
    fi

    # Test 8: piped git without -C should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git log --oneline | head -5"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-8"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: piped git without -C blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: piped git without -C should block (exit $rc)"
    fi

    # Test 9: chained git commands all with -C should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git -C /proj add . && git -C /proj commit -m \"fix\""},"cwd":"/tmp","session_id":"test","tool_use_id":"test-9"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: chained git -C allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: chained git -C should pass (exit $rc)"
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

# Allow bypass with comment: # hook-bypass: git-dash-C
if echo "$INPUT" | grep -qF 'hook-bypass: git-dash-C'; then
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

# Enforce git -C on every git invocation
# shellcheck disable=SC2016
echo "$COMMAND" | python3 -c '
import sys, re

command = sys.stdin.read().strip()

# Git subcommands that do NOT need a repo (no -C required)
NO_REPO_SUBCOMMANDS = {
    "--version", "help", "--help", "config", "init", "clone",
    "--exec-path", "--html-path", "--man-path", "--info-path",
    "credential", "credential-store", "credential-cache",
}

# Split on chain/pipe separators to find every git invocation
segments = re.split(r"\s*(?:&&|\|\||\||;)\s*", command)

violations = []

for seg in segments:
    seg = seg.strip()
    if not seg:
        continue

    tokens = seg.split()
    if not tokens:
        continue

    # Find git command (skip prefixes like sudo, env, etc.)
    git_idx = None
    for i, t in enumerate(tokens):
        if "=" in t and not t.startswith("-"):
            continue  # ENV=val
        if t in ("sudo", "env", "nice", "time", "command"):
            continue
        if t == "git" or t.endswith("/git"):
            git_idx = i
        break  # first real command

    if git_idx is None:
        continue

    # Get tokens after "git"
    git_args = tokens[git_idx + 1:]

    # Check if -C is present (before the subcommand)
    has_C = False
    subcommand = None
    i = 0
    while i < len(git_args):
        arg = git_args[i]
        if arg == "-C" and i + 1 < len(git_args):
            has_C = True
            i += 2  # skip -C and its argument
            continue
        if arg.startswith("-C"):
            # git -C/path/to/dir (no space)
            has_C = True
            i += 1
            continue
        if arg.startswith("-") and arg != "--":
            # Other global flags like --no-pager, -c key=val
            if arg in ("-c",) and i + 1 < len(git_args):
                i += 2
                continue
            i += 1
            continue
        # First non-flag token is the subcommand
        subcommand = arg
        break

    if has_C:
        continue

    # Allow subcommands that dont need a repo
    if subcommand in NO_REPO_SUBCOMMANDS:
        continue

    # Also allow bare --version, --help at git level
    if not subcommand and git_args and git_args[0] in ("--version", "--help"):
        continue

    violations.append(seg.strip())

if violations:
    print("BLOCKED: git command(s) without -C flag", file=sys.stderr)
    print("", file=sys.stderr)
    print("You may be in a different directory than expected.", file=sys.stderr)
    print("Always use git -C /full/path/to/project/root", file=sys.stderr)
    print("", file=sys.stderr)
    print("Detected:", file=sys.stderr)
    for v in violations:
        print(f"  {v[:120]}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Required: add -C with full path, e.g.:", file=sys.stderr)
    for v in violations:
        tokens = v.split()
        git_i = next((i for i, t in enumerate(tokens) if t == "git"), 0)
        rest = " ".join(tokens[git_i + 1:])
        print(f"  git -C /full/path/to/project {rest}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
'

exit $?

# EOF
