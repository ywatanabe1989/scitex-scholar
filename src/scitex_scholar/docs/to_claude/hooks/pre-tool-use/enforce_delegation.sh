#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-27 (ywatanabe)"
# File: ~/.claude/hooks/pre-tool-use/enforce_delegation.sh

# Description: Enforces 7-second timeout rule for the master orchestrator agent.
# Instead of pattern-matching specific commands, this checks whether the Bash tool
# call has a timeout <= 7000ms or run_in_background=true set.
# If neither, the command is BLOCKED — the agent must either:
#   1. Set timeout: 7000 (for quick commands)
#   2. Set run_in_background: true
#   3. Delegate to a subagent via Agent tool
#
# Only active when CLAUDE_ORCHESTRATOR=1 (master agent context).
# Quick-lookup commands (git status, ls, cat, echo, grep, etc.) are always allowed.
#
# Previous version (pattern-match based) backed up as:
#   enforce_delegation.sh.bak-pattern-match

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Export orchestrator flag so inner "$0" calls activate the hook
    export CLAUDE_ORCHESTRATOR=1

    # Test 1: command with timeout <= 7000 — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm install","timeout":7000},"cwd":"/tmp","session_id":"test","tool_use_id":"t1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: command with timeout=7000 — allowed"
    else
        ((fail++))
        echo "  FAIL: command with timeout=7000 — expected allow (exit 0), got exit $rc"
    fi

    # Test 2: command with no timeout — BLOCK
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm install"},"cwd":"/tmp","session_id":"test","tool_use_id":"t2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]] && echo "$result" | grep -q "BLOCKED"; then
        ((pass++))
        echo "  PASS: command with no timeout — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: command with no timeout — expected block exit 2, got exit $rc"
    fi

    # Test 3: command with timeout > 7000 — BLOCK
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"make all","timeout":15000},"cwd":"/tmp","session_id":"test","tool_use_id":"t3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: command with timeout=15000 — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: command with timeout=15000 — expected block exit 2, got exit $rc"
    fi

    # Test 4: command with run_in_background=true — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm install","run_in_background":true},"cwd":"/tmp","session_id":"test","tool_use_id":"t4"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: command with run_in_background=true — allowed"
    else
        ((fail++))
        echo "  FAIL: command with run_in_background=true — expected allow (exit 0), got exit $rc"
    fi

    # Test 5: non-Bash tool — ALLOW
    result=$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello"},"cwd":"/tmp","session_id":"test","tool_use_id":"t5"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]] && [[ -z "$result" ]]; then
        ((pass++))
        echo "  PASS: non-Bash tool — allowed silently"
    else
        ((fail++))
        echo "  FAIL: non-Bash tool — expected silent allow, got exit $rc"
    fi

    # Test 6: quick-lookup command (ls) with no timeout — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls -la /tmp"},"cwd":"/tmp","session_id":"test","tool_use_id":"t6"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: quick-lookup ls — allowed without timeout"
    else
        ((fail++))
        echo "  FAIL: quick-lookup ls — expected allow (exit 0), got exit $rc"
    fi

    # Test 7: quick-lookup command (git status) — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git status"},"cwd":"/tmp","session_id":"test","tool_use_id":"t7"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: quick-lookup git status — allowed without timeout"
    else
        ((fail++))
        echo "  FAIL: quick-lookup git status — expected allow (exit 0), got exit $rc"
    fi

    # Test 8: without CLAUDE_ORCHESTRATOR — ALLOW everything
    unset CLAUDE_ORCHESTRATOR
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"make all"},"cwd":"/tmp","session_id":"test","tool_use_id":"t8"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]] && [[ -z "$result" ]]; then
        ((pass++))
        echo "  PASS: without CLAUDE_ORCHESTRATOR — allowed silently"
    else
        ((fail++))
        echo "  FAIL: without CLAUDE_ORCHESTRATOR — expected silent allow, got exit $rc"
    fi

    # Test 9: hook-bypass comment — ALLOW
    export CLAUDE_ORCHESTRATOR=1
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"make all # hook-bypass: delegation"},"cwd":"/tmp","session_id":"test","tool_use_id":"t9"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: hook-bypass comment — allowed"
    else
        ((fail++))
        echo "  FAIL: hook-bypass comment — expected allow (exit 0), got exit $rc"
    fi

    # Test 10: sleep command without background — BLOCK
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"sleep 5"},"cwd":"/tmp","session_id":"test","tool_use_id":"t10a"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]] && echo "$result" | grep -q "sleep command detected"; then
        ((pass++))
        echo "  PASS: sleep command — blocked"
    else
        ((fail++))
        echo "  FAIL: sleep command — expected block exit 2 with sleep message, got exit $rc"
    fi

    # Test 10b: sleep in chained command — BLOCK
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"sleep 5 && cat /tmp/file","timeout":7000},"cwd":"/tmp","session_id":"test","tool_use_id":"t10b"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]] && echo "$result" | grep -q "sleep command detected"; then
        ((pass++))
        echo "  PASS: sleep in chained command — blocked"
    else
        ((fail++))
        echo "  FAIL: sleep in chained command — expected block exit 2 with sleep message, got exit $rc"
    fi

    # Test 10c: sleep with run_in_background=true — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"sleep 10 && echo done","run_in_background":true},"cwd":"/tmp","session_id":"test","tool_use_id":"t10c"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: sleep with run_in_background=true — allowed"
    else
        ((fail++))
        echo "  FAIL: sleep with run_in_background=true — expected allow (exit 0), got exit $rc"
    fi

    # Test 10d: quick-lookup cat — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"cat /etc/hostname"},"cwd":"/tmp","session_id":"test","tool_use_id":"t10d"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: quick-lookup cat — allowed without timeout"
    else
        ((fail++))
        echo "  FAIL: quick-lookup cat — expected allow (exit 0), got exit $rc"
    fi

    # Test 11: quick-lookup git diff — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git diff HEAD~1"},"cwd":"/tmp","session_id":"test","tool_use_id":"t11"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: quick-lookup git diff — allowed without timeout"
    else
        ((fail++))
        echo "  FAIL: quick-lookup git diff — expected allow (exit 0), got exit $rc"
    fi

    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PATH="$THIS_DIR/.$(basename "$0").log"
echo >"$LOG_PATH" 2>/dev/null || true

# Check if hook is enabled via switch.yaml
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

# Only enforce in master agent (orchestrator) context.
# Subagents are allowed to run long commands directly.
if [[ "${CLAUDE_ORCHESTRATOR:-}" != "1" ]] && [[ ! -f /tmp/.claude_orchestrator_flag ]]; then
    exit 0
fi

# Read input from stdin
INPUT="$(cat)"

# Allow bypass with comment: # hook-bypass: delegation
if echo "$INPUT" | grep -qF 'hook-bypass: delegation'; then
    exit 0
fi

# Parse tool name, command, timeout, and run_in_background from JSON input
PARSED="$(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    tool = d.get("tool_name", "")
    ti = d.get("tool_input", {}) or {}
    cmd = ti.get("command", "") or ""
    cmd_flat = " ; ".join(cmd.splitlines())
    timeout = ti.get("timeout", -1)
    if timeout is None:
        timeout = -1
    bg = ti.get("run_in_background", False)
    if bg is None:
        bg = False
    print(f"{tool}\t{cmd_flat}\t{timeout}\t{bg}")
except Exception:
    print("\t\t-1\tFalse")
' 2>/dev/null)" || true

TOOL_NAME="$(echo "$PARSED" | cut -f1)"
COMMAND="$(echo "$PARSED" | cut -f2)"
TIMEOUT="$(echo "$PARSED" | cut -f3)"
RUN_IN_BG="$(echo "$PARSED" | cut -f4)"

# Only check Bash tool
[[ "$TOOL_NAME" == "Bash" ]] || exit 0

# Exit if no command
[[ -n "$COMMAND" ]] || exit 0

# Allow if run_in_background is true
if [[ "$RUN_IN_BG" == "True" ]]; then
    exit 0
fi

# BLOCK sleep commands — they hang the orchestrator regardless of timeout
# (run_in_background=true was already allowed above, so this only catches foreground sleep)
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)sleep\s'; then
    echo "BLOCKED: sleep command detected. Use run_in_background: true instead of sleep." >&2
    echo "" >&2
    echo "Command: ${COMMAND:0:120}" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  1. Add run_in_background: true to the Bash tool call" >&2
    echo "  2. Delegate to a subagent via Agent tool" >&2
    echo "  3. Remove the sleep entirely" >&2
    echo "" >&2
    echo "Bypass: add '# hook-bypass: delegation' in the command" >&2
    exit 2
fi

# Allow if timeout is set and <= 7000ms
if [[ "$TIMEOUT" != "-1" ]] && [[ "$TIMEOUT" -le 7000 ]] 2>/dev/null; then
    exit 0
fi

# Allow quick-lookup commands that are always fast (no timeout needed)
# These are simple read-only commands that complete near-instantly
FIRST_CMD="$(echo "$COMMAND" | sed 's/[;&|].*//' | sed 's/^[[:space:]]*//')"
if echo "$FIRST_CMD" | grep -qE '^(ls|cat|head|tail|echo|printf|pwd|whoami|hostname|date|wc|file|which|type|id|uname|realpath|dirname|basename|stat|test|true|false|\[)(\s|$)'; then
    exit 0
fi
if echo "$FIRST_CMD" | grep -qE '^git[[:space:]]+(status|log|diff|show|branch|tag|remote|rev-parse|describe|config)(\s|$)'; then
    exit 0
fi
if echo "$FIRST_CMD" | grep -qE '^(grep|rg|find|fd|ag)[[:space:]]'; then
    exit 0
fi
if echo "$FIRST_CMD" | grep -qE '^(cp|mv|mkdir|touch|chmod|chown|ln|tee)[[:space:]]'; then
    exit 0
fi
if echo "$FIRST_CMD" | grep -qE '^screen[[:space:]]'; then
    exit 0
fi

# BLOCK: no timeout set or timeout > 7000ms
echo "BLOCKED: Bash command without timeout <= 7s (7000ms)." >&2
echo "" >&2
echo "Command: ${COMMAND:0:120}" >&2
echo "Timeout: ${TIMEOUT}ms (need <= 7000, or run_in_background)" >&2
echo "" >&2
echo "Options:" >&2
echo "  1. Add timeout: 7000 to the Bash tool call (for quick commands)" >&2
echo "  2. Add run_in_background: true (for longer commands)" >&2
echo "  3. Delegate to a subagent via Agent tool" >&2
echo "" >&2
echo "Bypass: add '# hook-bypass: delegation' in the command" >&2
exit 2

# EOF
