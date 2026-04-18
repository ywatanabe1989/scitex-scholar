#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-04-07 (ywatanabe)"
# File: ~/.claude/to_claude/hooks/pre-tool-use/enforce_background_subagents.sh

# Description: Enforces run_in_background: true for all subagent (Task/Agent) calls
# when running as the Telegram agent. This prevents blocking the Telegram message loop.
#
# Only active when CLAUDE_AGENT_ROLE=telegram.
# Non-Task tools are always allowed.

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Export telegram role so inner "$0" calls activate the hook
    export CLAUDE_AGENT_ROLE=telegram

    # Test 1: Task with run_in_background=true — ALLOW
    result=$(printf '%s' '{"tool_name":"Task","tool_input":{"description":"do something","run_in_background":true},"cwd":"/tmp","session_id":"test","tool_use_id":"t1"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: Task with run_in_background=true — allowed"
    else
        ((fail++))
        echo "  FAIL: Task with run_in_background=true — expected allow (exit 0), got exit $rc"
    fi

    # Test 2: Task without run_in_background — BLOCK
    result=$(printf '%s' '{"tool_name":"Task","tool_input":{"description":"do something"},"cwd":"/tmp","session_id":"test","tool_use_id":"t2"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]] && echo "$result" | grep -q "ERROR"; then
        ((pass++))
        echo "  PASS: Task without run_in_background — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: Task without run_in_background — expected block exit 2, got exit $rc"
    fi

    # Test 3: Task with run_in_background=false — BLOCK
    result=$(printf '%s' '{"tool_name":"Task","tool_input":{"description":"do something","run_in_background":false},"cwd":"/tmp","session_id":"test","tool_use_id":"t3"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: Task with run_in_background=false — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: Task with run_in_background=false — expected block exit 2, got exit $rc"
    fi

    # Test 4: non-Task tool — ALLOW
    result=$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"ls"},"cwd":"/tmp","session_id":"test","tool_use_id":"t4"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: non-Task tool — allowed"
    else
        ((fail++))
        echo "  FAIL: non-Task tool — expected allow (exit 0), got exit $rc"
    fi

    # Test 5: without CLAUDE_AGENT_ROLE=telegram — ALLOW everything
    unset CLAUDE_AGENT_ROLE
    result=$(printf '%s' '{"tool_name":"Task","tool_input":{"description":"do something"},"cwd":"/tmp","session_id":"test","tool_use_id":"t5"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: without CLAUDE_AGENT_ROLE=telegram — allowed silently"
    else
        ((fail++))
        echo "  FAIL: without CLAUDE_AGENT_ROLE=telegram — expected silent allow, got exit $rc"
    fi

    # Test 6: CLAUDE_AGENT_ROLE=other — ALLOW everything
    export CLAUDE_AGENT_ROLE=worker
    result=$(printf '%s' '{"tool_name":"Task","tool_input":{"description":"do something"},"cwd":"/tmp","session_id":"test","tool_use_id":"t6"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: CLAUDE_AGENT_ROLE=worker — allowed silently"
    else
        ((fail++))
        echo "  FAIL: CLAUDE_AGENT_ROLE=worker — expected silent allow, got exit $rc"
    fi

    # Test 7: Agent (not Task) with run_in_background=true — ALLOW
    export CLAUDE_AGENT_ROLE=telegram
    result=$(printf '%s' '{"tool_name":"Agent","tool_input":{"description":"do something","run_in_background":true},"cwd":"/tmp","session_id":"test","tool_use_id":"t7"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 0 ]]; then
        ((pass++))
        echo "  PASS: Agent with run_in_background=true — allowed"
    else
        ((fail++))
        echo "  FAIL: Agent with run_in_background=true — expected allow (exit 0), got exit $rc"
    fi

    # Test 8: Agent without run_in_background — BLOCK
    result=$(printf '%s' '{"tool_name":"Agent","tool_input":{"description":"do something"},"cwd":"/tmp","session_id":"test","tool_use_id":"t8"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]] && echo "$result" | grep -q "ERROR"; then
        ((pass++))
        echo "  PASS: Agent without run_in_background — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: Agent without run_in_background — expected block exit 2, got exit $rc"
    fi

    # Test 9: Agent with run_in_background=false — BLOCK
    result=$(printf '%s' '{"tool_name":"Agent","tool_input":{"description":"do something","run_in_background":false},"cwd":"/tmp","session_id":"test","tool_use_id":"t9"}' | "$0" 2>&1) && rc=$? || rc=$?
    if [[ $rc -eq 2 ]]; then
        ((pass++))
        echo "  PASS: Agent with run_in_background=false — blocked (exit $rc)"
    else
        ((fail++))
        echo "  FAIL: Agent with run_in_background=false — expected block exit 2, got exit $rc"
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

# Only enforce when running as the Telegram agent.
# Other agent roles (or no role set) are not affected.
if [[ "${CLAUDE_AGENT_ROLE:-}" != "telegram" ]]; then
    exit 0
fi

# Read input from stdin
INPUT="$(cat)"

# Parse tool name and run_in_background from JSON input
PARSED="$(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    tool = d.get("tool_name", "")
    ti = d.get("tool_input", {}) or {}
    bg = ti.get("run_in_background", False)
    if bg is None:
        bg = False
    print(f"{tool}\t{bg}")
except Exception:
    print("\tFalse")
' 2>/dev/null)" || true

TOOL_NAME="$(echo "$PARSED" | cut -f1)"
RUN_IN_BG="$(echo "$PARSED" | cut -f2)"

# Only check Task/Agent tool (subagent calls)
[[ "$TOOL_NAME" == "Task" || "$TOOL_NAME" == "Agent" ]] || exit 0

# Allow if run_in_background is true
if [[ "$RUN_IN_BG" == "True" ]]; then
    exit 0
fi

# BLOCK: Task/Agent call without run_in_background: true
echo "ERROR: Telegram agent requires run_in_background: true for all subagent (Task/Agent) calls. This prevents blocking the Telegram message loop. Add run_in_background: true to your Agent call." >&2
exit 2

# EOF
