#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-26 (ywatanabe)"
# File: .claude/to_claude/hooks/post-tool-use/auto_compact.sh

# Description: Counts PostToolUse invocations and sends /compact every 30
# invocations to work around Claude Code's unreliable auto-compact.
# Refs: Anthropic issues #31828, #34925, #38483

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --self-test: verify hook works with sample input
if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0
    fail=0

    # Test 1: counter file creation and increment
    TEST_COUNTER="/tmp/cld-compact-counter-selftest-$$"
    rm -f "$TEST_COUNTER"
    echo '{"tool_name":"Bash"}' | COMPACT_COUNTER_FILE="$TEST_COUNTER" "$0" >/dev/null 2>&1 && rc=$? || rc=$?
    if [[ $rc -eq 0 ]] && [[ -f "$TEST_COUNTER" ]]; then
        count=$(cat "$TEST_COUNTER")
        if [[ "$count" == "1" ]]; then
            ((pass++))
            echo "  PASS: counter incremented to 1 (exit $rc)"
        else
            ((fail++))
            echo "  FAIL: counter is '$count', expected '1'"
        fi
    else
        ((fail++))
        echo "  FAIL: counter file not created (exit $rc)"
    fi
    rm -f "$TEST_COUNTER"

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

# Consume stdin (required by hook protocol)
cat >/dev/null

# --- Counter logic ---
COMPACT_THRESHOLD=30

# Use env override (for testing) or session-based counter file
if [[ -n "${COMPACT_COUNTER_FILE:-}" ]]; then
    COUNTER_FILE="$COMPACT_COUNTER_FILE"
else
    # Use CLAUDE_SESSION_ID if available, fall back to parent PID
    SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
    COUNTER_FILE="/tmp/cld-compact-counter-${SESSION_ID}"
fi

# Read current count
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
    # Sanitize: ensure it's a number
    if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
        COUNT=0
    fi
else
    COUNT=0
fi

# Increment
COUNT=$((COUNT + 1))

# Pre-compact notification (3 steps before compact)
NOTIFY_THRESHOLD=$((COMPACT_THRESHOLD - 3))
if [[ $COUNT -eq $NOTIFY_THRESHOLD ]]; then
    # Notify via scitex notification (non-blocking)
    (scitex notification send \
        --message "Compact in 3 steps (count: $COUNT/$COMPACT_THRESHOLD). Save important context to memory/issues now." \
        --title "Pre-Compact Warning" \
        --level warning 2>/dev/null || true) &
    disown 2>/dev/null || true
fi

# Check if threshold reached
if [[ $COUNT -ge $COMPACT_THRESHOLD ]]; then
    # Reset counter
    echo 0 >"$COUNTER_FILE"

    # Send /compact if running in screen
    if [[ -n "${STY:-}" ]]; then
        screen -X stuff "/compact$(printf '\r')" 2>/dev/null || true
        # Wait then send continue
        (sleep 3 && screen -X stuff "continue$(printf '\r')" 2>/dev/null || true) &
        disown 2>/dev/null || true
    fi
else
    echo "$COUNT" >"$COUNTER_FILE"
fi

# Never block
exit 0

# EOF
