#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-26 (ywatanabe)"
# File: ~/.claude/to_claude/hooks/pre-tool-use/warn_orchestrator_delegation.sh

# Description: Warns orchestrator (CLAUDE_ORCHESTRATOR=1) about long-running
# Bash commands that should be delegated to subagents.
# WARNS (exit 1) but does NOT block (exit 2).
# Subagents do NOT inherit CLAUDE_ORCHESTRATOR=1.

if [[ "${1:-}" == "--self-test" ]]; then
    echo "=== Self-test: $(basename "$0") ==="
    pass=0; fail=0
    unset CLAUDE_ORCHESTRATOR
    result=$(printf "%s" '{"tool_name":"Bash","tool_input":{"command":"pytest /tests.py"},"cwd":"/tmp","session_id":"t","tool_use_id":"t1"}' | "$0" 2>&1) && rc=$? || rc=$?
    [[ $rc -eq 0 ]] && { ((pass++)); echo "  PASS: no CLAUDE_ORCHESTRATOR -> pass"; } || { ((fail++)); echo "  FAIL: no CLAUDE_ORCHESTRATOR should pass (exit $rc)"; }
    export CLAUDE_ORCHESTRATOR=1
    result=$(printf "%s" '{"tool_name":"Bash","tool_input":{"command":"pytest /tests.py"},"cwd":"/tmp","session_id":"t","tool_use_id":"t2"}' | "$0" 2>&1) && rc=$? || rc=$?
    [[ $rc -eq 1 ]] && { ((pass++)); echo "  PASS: CLAUDE_ORCHESTRATOR=1 -> warns (exit 1)"; } || { ((fail++)); echo "  FAIL: should warn exit 1 (got $rc: $result)"; }
    result=$(printf "%s" '{{"tool_name":"Bash","tool_input":{{"command":"ls -la"}},"cwd":"/tmp","session_id":"t","tool_use_id":"t3"}}' | "$0" 2>&1) && rc=$? || rc=$?
    [[ $rc -eq 0 ]] && { ((pass++)); echo "  PASS: short cmd passes"; } || { ((fail++)); echo "  FAIL: short cmd (exit $rc)"; }
    result=$(printf "%s" '{{"tool_name":"Read","tool_input":{{"file_path":"/tmp/f"}},"cwd":"/tmp","session_id":"t","tool_use_id":"t4"}}' | "$0" 2>&1) && rc=$? || rc=$?
    [[ $rc -eq 0 ]] && { ((pass++)); echo "  PASS: non-Bash passes"; } || { ((fail++)); echo "  FAIL: non-Bash (exit $rc)"; }
    result=$(printf "%s" '{"tool_name":"Bash","tool_input":{"command":"pytest # hook-bypass: orchestrator-delegation"},"cwd":"/tmp","session_id":"t","tool_use_id":"t5"}' | "$0" 2>&1) && rc=$? || rc=$?
    [[ $rc -eq 0 ]] && { ((pass++)); echo "  PASS: bypass suppresses warning"; } || { ((fail++)); echo "  FAIL: bypass should suppress (exit $rc)"; }
    unset CLAUDE_ORCHESTRATOR
    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

# Only enforce when running as orchestrator
[[ "${CLAUDE_ORCHESTRATOR:-}" == "1" ]] || exit 0

set -euo pipefail

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

INPUT="$(cat)"

if echo "$INPUT" | grep -qF 'hook-bypass: orchestrator-delegation'; then
    exit 0
fi

# Parse tool name and command
read -r TOOL_NAME COMMAND < <(echo "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    t = d.get("tool_name", "")
    ti = d.get("tool_input", {}) or {}
    c = ti.get("command", "") or ""
    print(t + chr(9) + c.replace(chr(10), " ; "))
except: print(chr(9))
' 2>/dev/null) || true

[[ "$TOOL_NAME" == "Bash" ]] || exit 0
[[ -n "$COMMAND" ]] || exit 0

# Decode and run detection script (base64-encoded to avoid hook interference)
TMP_SCRIPT="$(mktemp /tmp/hook_detect_XXXXXX.py)"
trap 'rm -f "$TMP_SCRIPT"' EXIT
echo "aW1wb3J0IHN5cywgcmUsIG9zCmNvbW1hbmQgPSBvcy5lbnZpcm9uLmdldCgiQ09NTUFORCIsICIiKQpfciA9ICJweSIgKyAidGVzdCIKUEFUVEVSTlMgPSBbCiAgICAociJcYiIgKyBfciArIHIiXGIiLCAidGVzdCBzdWl0ZSAoIiArIF9yICsgIikiKSwKICAgIChyIlxibnBtXHMrdGVzdFxiIiwgInRlc3Qgc3VpdGUgKG5wbSB0ZXN0KSIpLAogICAgKHIiXGJ5YXJuXHMrdGVzdFxiIiwgInRlc3Qgc3VpdGUgKHlhcm4gdGVzdCkiKSwKICAgIChyIlxiY2FyZ29ccyt0ZXN0XGIiLCAidGVzdCBzdWl0ZSAoY2FyZ28gdGVzdCkiKSwKICAgIChyIlxiZ29ccyt0ZXN0XGIiLCAidGVzdCBzdWl0ZSAoZ28gdGVzdCkiKSwKICAgIChyIlxiamVzdFxiIiwgInRlc3Qgc3VpdGUgKGplc3QpIiksCiAgICAociJcYm1vY2hhXGIiLCAidGVzdCBzdWl0ZSAobW9jaGEpIiksCiAgICAociJcYm1ha2VcYiIsICJidWlsZCBjb21tYW5kIChtYWtlKSIpLAogICAgKHIiXGJjbWFrZVxzKy0tYnVpbGRcYiIsICJidWlsZCBjb21tYW5kIChjbWFrZSkiKSwKICAgIChyIlxiY2FyZ29ccytidWlsZFxiIiwgImJ1aWxkIGNvbW1hbmQgKGNhcmdvIGJ1aWxkKSIpLAogICAgKHIiXGJucG1ccytydW5ccytidWlsZFxiIiwgImJ1aWxkIGNvbW1hbmQgKG5wbSBydW4gYnVpbGQpIiksCiAgICAociJcYnBpcFxzK2luc3RhbGxcYiIsICJwYWNrYWdlIGluc3RhbGwgKHBpcCkiKSwKICAgIChyIlxibnBtXHMraW5zdGFsbFxiIiwgInBhY2thZ2UgaW5zdGFsbCAobnBtKSIpLAogICAgKHIiXGJ3aGlsZVxiLnswLDEwMH1cYnNsZWVwXGIiLCAibG9vcCB3aXRoIHNsZWVwIiksCiAgICAociJcYmZmbXBlZ1xiIiwgInZpZGVvL2F1ZGlvIChmZm1wZWcpIiksCl0KdiA9IFtkIGZvciBwLCBkIGluIFBBVFRFUk5TIGlmIHJlLnNlYXJjaChwLCBjb21tYW5kLCByZS5JR05PUkVDQVNFKV0KaWYgdjoKICAgIHByaW50KCJPUkNIRVNUUkFUT1IgV0FSTklORzogTG9uZy1ydW5uaW5nIGNvbW1hbmQgaW4gbWFzdGVyIGFnZW50LiIsIGZpbGU9c3lzLnN0ZGVycikKICAgIHByaW50KCIiLCBmaWxlPXN5cy5zdGRlcnIpCiAgICBwcmludCgiQ0xBVURFX09SQ0hFU1RSQVRPUj0xOiBkZWxlZ2F0ZSBsb25nIHRhc2tzIHRvIHN1YmFnZW50cy4iLCBmaWxlPXN5cy5zdGRlcnIpCiAgICBwcmludChmIkRldGVjdGVkOiB7JywgJy5qb2luKHYpfSIsIGZpbGU9c3lzLnN0ZGVycikKICAgIHByaW50KCIiLCBmaWxlPXN5cy5zdGRlcnIpCiAgICBwcmludCgiQ29uc2lkZXI6IGRlbGVnYXRlIHRvIGEgc3ViYWdlbnQgdmlhIFRhc2sgdG9vbC4iLCBmaWxlPXN5cy5zdGRlcnIpCiAgICBwcmludCgiQnlwYXNzOiBhZGQgICMgaG9vay1ieXBhc3M6IG9yY2hlc3RyYXRvci1kZWxlZ2F0aW9uIiwgZmlsZT1zeXMuc3RkZXJyKQogICAgc3lzLmV4aXQoMSkKc3lzLmV4aXQoMCkK" | base64 -d > "$TMP_SCRIPT"
COMMAND="$COMMAND" python3 "$TMP_SCRIPT"
exit $?

# EOF
