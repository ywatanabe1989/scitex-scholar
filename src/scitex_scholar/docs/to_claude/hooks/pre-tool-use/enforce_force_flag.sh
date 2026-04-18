#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-02-06 (ywatanabe)"
# File: ./.claude/hooks/pre-tool-use/enforce_force_flag.sh

# Description: Enforces -f flag on rm and cp commands to avoid
# interactive prompts that hang Claude Code sessions.
# Blocks: rm, cp without -f
# Allows: rm -f, rm -rf, cp -f, cp -rf, etc.

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: allowed command should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls -la"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: allowed command (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: allowed command (exit $rc)"
    fi

    # Test 2: rm without -f should block (exit 2)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"rm foo.txt"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: rm without -f blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: rm without -f should block (exit $rc)"
    fi

    # Test 3: rm -f should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"rm -f foo.txt"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: rm -f allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: rm -f should pass (exit $rc)"
    fi

    # Test 4: yes | cp should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"yes | cp foo.txt bar.txt"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-4"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: yes | cp allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: yes | cp should pass (exit $rc)"
    fi

    # Test 5: yes | rm should pass (exit 0)
    # shellcheck disable=SC2034
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"yes | rm foo.txt"},"cwd":"/tmp","session_id":"test","tool_use_id":"test-5"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: yes | rm allowed (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: yes | rm should pass (exit $rc)"
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

# Allow bypass with comment: # hook-bypass: force-flag
if echo "$INPUT" | grep -qF 'hook-bypass: force-flag'; then
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
    # Flatten multiline commands for analysis
    cmd_flat = cmd.replace("\n", " ; ")
    print(f"{tool}\t{cmd_flat}")
except:
    print("\t")
' 2>/dev/null) || true

# Only check Bash tool
[[ "$TOOL_NAME" == "Bash" ]] || exit 0

# Exit if no command
[[ -n "$COMMAND" ]] || exit 0

# Check each command in pipes/chains/semicolons
# Uses Python for reliable parsing of shell command structures
# shellcheck disable=SC2016
echo "$COMMAND" | python3 -c '
import sys, re

command = sys.stdin.read().strip()

# First, split on non-pipe separators: ;, &&, ||
# Keep pipes intact so we can detect "yes | cp" patterns
chain_segments = re.split(r"\s*(?:;|&&|\|\|)\s*|\$\(", command)

violations = []

for chain in chain_segments:
    chain = chain.strip()
    if not chain:
        continue

    # Split this chain on single pipes to get pipeline stages
    pipe_stages = re.split(r"\s*\|\s*", chain)

    for idx, seg in enumerate(pipe_stages):
        seg = seg.strip()
        if not seg:
            continue

        # Tokenize roughly
        tokens = seg.split()
        if not tokens:
            continue

        # Find the actual command (skip env vars, sudo, etc.)
        cmd_idx = 0
        for i, t in enumerate(tokens):
            if "=" in t and not t.startswith("-"):
                continue  # ENV=val
            if t in ("sudo", "env", "nice", "time", "command"):
                continue  # prefix commands
            cmd_idx = i
            break

        if cmd_idx >= len(tokens):
            continue

        cmd = tokens[cmd_idx]
        # Get just the command name (handle /usr/bin/rm etc.)
        cmd_base = cmd.rsplit("/", 1)[-1]

        if cmd_base not in ("rm", "cp"):
            continue

        # Allow if piped from "yes" (yes | cp is equivalent to cp -f)
        if idx > 0:
            prev = pipe_stages[idx - 1].strip().split()
            if prev and prev[-1] in ("yes",):
                continue

        # Collect all flags from remaining tokens
        flags = ""
        for t in tokens[cmd_idx + 1:]:
            if t.startswith("-") and not t.startswith("--"):
                flags += t[1:]
            elif t == "--force":
                flags += "f"
            elif t.startswith("--"):
                pass  # other long options
            else:
                break  # first non-flag argument

        if "f" not in flags:
            violations.append((cmd_base, seg.strip()))

if violations:
    for cmd, context in violations:
        print(f"BLOCKED: {cmd} without -f flag", file=sys.stderr)
    print("", file=sys.stderr)
    print("Commands detected without -f:", file=sys.stderr)
    for cmd, context in violations:
        print(f"  {context[:120]}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Required:", file=sys.stderr)
    print("  rm -f   (or rm -rf for directories)", file=sys.stderr)
    print("  cp -f   (or cp -rf for directories)", file=sys.stderr)
    print("  yes | cp  (piping yes also works)", file=sys.stderr)
    print("", file=sys.stderr)
    print("Why: Commands without -f may trigger interactive prompts", file=sys.stderr)
    print("     that hang automated sessions (Claude Code, CI/CD).", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
'

exit $?

# EOF
