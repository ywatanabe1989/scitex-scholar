#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: "2026-03-04 22:36:48 (ywatanabe)"
# File: .//home/ywatanabe/.claude/hooks/pre-tool-use/pipe-stage-permissions.sh

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

# https://github.com/robtaylor/claude-config/blob/main/hooks/pipe-stage-permissions.sh

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

    echo "Results: $pass passed, $fail failed"
    [[ $fail -eq 0 ]] && exit 0 || exit 1
fi

set -eo pipefail

# Check if hook is enabled via centralized project-switch/switch.yaml
HELPER_SCRIPT="$(dirname "$THIS_DIR")/project-switch/hook_switch_helper.sh"
if [[ -f "$HELPER_SCRIPT" ]]; then
    # shellcheck source=/dev/null
    source "$HELPER_SCRIPT"
    check_hook_enabled_or_exit "$(basename "$0")"
fi

# pipe-stage-permissions.sh — PreToolUse hook for Claude Code
#
# Fixes prefix-matching limitations in Claude Code's permission system:
#
# 1. Pipes: `foo | tee /tmp/x` doesn't match Bash(tee:*)
# 2. Leading comments: `# comment\njq ...` doesn't match Bash(jq:*)
# 3. Env var prefixes: `CC=gcc make` doesn't match Bash(make:*)
# 4. Project binaries: `build_metal/lu_bench` isn't in global allow list
#
# Additional features:
# - Maintains a local allowlist (approved-patterns.json) for binaries and
#   env var assignments that aren't in the global settings.json.
# - Sensitive env vars (PATH, LD_*, DYLD_*, etc.) are auto-approved if
#   their values are project-local; checked against local allowlist if not.
# - A companion PostToolUse hook (pipe-stage-learn.sh) auto-captures
#   user approvals into the local allowlist.

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
APPROVED_FILE="$HOOK_DIR/approved-patterns.json"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$COMMAND" ]; then
    exit 0 # no command, pass through
fi

# Use cwd from hook input, fall back to PWD
if [ -z "$CWD" ]; then
    CWD="$PWD"
fi

# Strip leading comment lines (# ...) and blank lines.
STRIPPED="$(echo "$COMMAND" | sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d')"
COMMENTS_STRIPPED=false
if [ "$STRIPPED" != "$COMMAND" ]; then
    COMMENTS_STRIPPED=true
fi
COMMAND="$STRIPPED"

if [ -z "$COMMAND" ]; then
    exit 0 # nothing left after stripping comments
fi

# ── Load allow lists ──────────────────────────────────────────────────

# 1. Global: settings.json Bash(prefix:*) patterns
SETTINGS="$HOME/.claude/settings.json"
ALLOWED_PREFIXES=()
if [ -f "$SETTINGS" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && ALLOWED_PREFIXES+=("$line")
    done < <(
        jq -r '.permissions.allow[]? // empty' "$SETTINGS" |
            grep '^Bash(' |
            sed -n 's/^Bash(\(.*\))$/\1/p' |
            sed 's/:\*$//' |
            sed 's/ \*$//' |
            sort -u
    )
fi

# 2. Local: approved-patterns.json — binaries and env_vars globs
APPROVED_BINARIES=()
APPROVED_ENV_VARS=()
if [ -f "$APPROVED_FILE" ]; then
    while IFS= read -r line; do
        [ -n "$line" ] && APPROVED_BINARIES+=("$line")
    done < <(jq -r '.binaries[]? // empty' "$APPROVED_FILE" 2>/dev/null)
    while IFS= read -r line; do
        [ -n "$line" ] && APPROVED_ENV_VARS+=("$line")
    done < <(jq -r '.env_vars[]? // empty' "$APPROVED_FILE" 2>/dev/null)
fi

if [ ${#ALLOWED_PREFIXES[@]} -eq 0 ] && [ ${#APPROVED_BINARIES[@]} -eq 0 ]; then
    exit 0 # nothing to match against
fi

# ── Sensitive env var detection ───────────────────────────────────────

SENSITIVE_VAR_PREFIXES=(
    "PATH=" "LD_" "DYLD_" "PYTHONPATH=" "PYTHONHOME="
    "NODE_PATH=" "GEM_PATH=" "GEM_HOME=" "RUBYLIB="
    "PERL5LIB=" "CLASSPATH=" "GOPATH="
)

is_sensitive_var() {
    local assignment="$1"
    for prefix in "${SENSITIVE_VAR_PREFIXES[@]}"; do
        if [[ "$assignment" == "$prefix"* ]]; then
            return 0
        fi
    done
    return 1
}

# ── Path safety checks ───────────────────────────────────────────────

is_project_local() {
    local path="$1"
    if [ -z "$path" ] || [[ "$path" == *'$'* ]]; then
        return 1
    fi
    if [[ "$path" != /* ]]; then
        path="$CWD/$path"
    fi
    if [ -e "$path" ]; then
        path="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
    else
        while [[ "$path" == *"/.."* ]]; do
            # shellcheck disable=SC2001
            path="$(echo "$path" | sed 's|/[^/][^/]*/\.\./|/|g')"
        done
    fi
    [[ "$path" == "$CWD"/* || "$path" == "$CWD" ]]
}

get_var_value() {
    local assignment="$1"
    local value="${assignment#*=}"
    if [[ "$value" =~ ^\"(.*)\"$ ]]; then
        value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
        value="${BASH_REMATCH[1]}"
    fi
    echo "$value"
}

# Check if a sensitive env var is safe: project-local OR in local allowlist.
is_safe_sensitive_var() {
    local assignment="$1"
    local value
    value="$(get_var_value "$assignment")"

    # Shell variable references can't be verified
    if [[ "$value" == *'$'* ]]; then
        # Still check approved patterns — user may have explicitly approved
        for pattern in "${APPROVED_ENV_VARS[@]}"; do
            # shellcheck disable=SC2053,SC2254
            if [[ "$assignment" == $pattern ]]; then
                return 0
            fi
        done
        return 1
    fi

    # Check each colon-separated path component
    local IFS=':'
    local components
    read -ra components <<<"$value"
    local all_local=true
    for component in "${components[@]}"; do
        [ -z "$component" ] && continue
        if ! is_project_local "$component"; then
            all_local=false
            break
        fi
    done
    if [ "$all_local" = true ]; then
        return 0
    fi

    # Not project-local — check local allowlist (glob matching)
    for pattern in "${APPROVED_ENV_VARS[@]}"; do
        # shellcheck disable=SC2053,SC2254
        if [[ "$assignment" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# ── Binary matching ──────────────────────────────────────────────────

is_project_binary() {
    local cmd="$1"
    local binary="${cmd%% *}"
    if [[ "$binary" != */* ]]; then
        return 1
    fi
    is_project_local "$binary"
}

# Check binary against local allowlist (glob matching)
is_approved_binary() {
    local cmd="$1"
    local binary="${cmd%% *}"
    for pattern in "${APPROVED_BINARIES[@]}"; do
        # shellcheck disable=SC2053,SC2254
        if [[ "$binary" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# ── Core matching function ───────────────────────────────────────────

matches_allowed() {
    local cmd="$1"
    cmd="${cmd#"${cmd%%[! ]*}"}"

    # Strip leading env var assignments
    while [[ "$cmd" =~ ^([A-Za-z_][A-Za-z0-9_]*=) ]]; do
        local assignment="${cmd%%[[:space:]]*}"
        if is_sensitive_var "$assignment"; then
            if ! is_safe_sensitive_var "$assignment"; then
                return 1 # unsafe sensitive var — force prompt
            fi
        fi
        # Strip: VAR="value", VAR='value', or VAR=value
        if [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=\"[^\"]*\"[[:space:]]+(.*) ]]; then
            cmd="${BASH_REMATCH[1]}"
        elif [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=\'[^\']*\'[[:space:]]+(.*) ]]; then
            cmd="${BASH_REMATCH[1]}"
        elif [[ "$cmd" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+(.*) ]]; then
            cmd="${BASH_REMATCH[1]}"
        else
            break
        fi
    done

    # Check global allow list prefixes
    for prefix in "${ALLOWED_PREFIXES[@]}"; do
        if [[ "$cmd" == "$prefix"* ]]; then
            return 0
        fi
    done

    # Check project-local binary
    if is_project_binary "$cmd"; then
        return 0
    fi

    # Check local approved binaries
    if is_approved_binary "$cmd"; then
        return 0
    fi

    return 1
}

# ── Early exit for simple, untransformed commands ────────────────────

has_env_prefix=false
has_project_binary=false
first_line="$(echo "$COMMAND" | head -1 | sed 's/^[[:space:]]*//')"
if [[ "$first_line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
    has_env_prefix=true
fi
first_binary="${first_line%% *}"
if [[ "$first_binary" == */* ]]; then
    if is_project_local "$first_binary" || is_approved_binary "$first_line"; then
        has_project_binary=true
    fi
fi

if [[ "$COMMENTS_STRIPPED" == false && "$has_env_prefix" == false && "$has_project_binary" == false && "$COMMAND" != *"|"* && "$COMMAND" != *"&&"* && "$COMMAND" != *";"* ]]; then
    clean_line="$(echo "$first_line" | sed 's/[0-9]*>&[0-9]*//g' | sed 's/[[:space:]]*$//')"
    if matches_allowed "$clean_line"; then
        exit 0 # simple command, normal permissions handle it
    fi
fi

# ── Split into stages and check each ─────────────────────────────────

STAGES=()
while IFS= read -r seg; do
    [ -n "$seg" ] && STAGES+=("$seg")
done < <(echo "$COMMAND" | sed 's/&&/\n/g; s/;/\n/g; s/|/\n/g')

all_match=true
unmatched_stage=""
for stage in "${STAGES[@]}"; do
    stage="$(echo "$stage" | sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    clean="$(echo "$stage" | sed 's/[0-9]*>&[0-9]*//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    [ -z "$clean" ] && continue
    if ! matches_allowed "$clean"; then
        all_match=false
        unmatched_stage="$clean"
        break
    fi
done

if [ "$all_match" = true ]; then
    jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "All pipeline stages match allowed prefixes, project binaries, or local allowlist"
    }
  }'
    exit 0
fi

# Write pending approval info for the PostToolUse hook to pick up
PENDING_DIR="$HOOK_DIR/.pending"
mkdir -p "$PENDING_DIR" 2>/dev/null || true
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // empty')
if [ -n "$TOOL_USE_ID" ] && [ -n "$unmatched_stage" ]; then
    jq -n \
        --arg stage "$unmatched_stage" \
        --arg cwd "$CWD" \
        '{ stage: $stage, cwd: $cwd }' \
        >"$PENDING_DIR/$TOOL_USE_ID.json" 2>/dev/null || true
fi

# Fall through to normal permission system
exit 0

# EOF
