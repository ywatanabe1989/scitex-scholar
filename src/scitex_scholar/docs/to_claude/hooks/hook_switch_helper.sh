#!/bin/bash
# Timestamp: "2026-01-04 (ywatanabe)"
# File: hook_switch_helper.sh
# Description: Helper functions for hooks to check if they're enabled via centralized switch.yaml

# Check if a hook is enabled via switch.yaml
# Usage: is_hook_enabled "script_name.sh" [switch_file_path]
# Returns: 0 if enabled (or no switch.yaml exists), 1 if disabled
is_hook_enabled() {
    local hook_name="$1"
    local switch_file="${2}"

    # Extract just the script name from full path
    hook_name="$(basename "$hook_name")"

    # If no switch file specified, try centralized location
    if [[ -z "$switch_file" ]]; then
        # Try project-switch/switch.yaml (centralized)
        local hooks_dir
        hooks_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        switch_file="$hooks_dir/project-switch/switch.yaml"
    fi

    # If switch.yaml doesn't exist, assume enabled (default behavior)
    [[ ! -f "$switch_file" ]] && return 0

    # Check if hook is explicitly listed in 'off:' section
    if grep -A 100 "^off:" "$switch_file" | grep -q "^  $hook_name$"; then
        return 1 # Disabled
    fi

    # Check if hook is explicitly listed in 'on:' section
    if grep -A 100 "^on:" "$switch_file" | grep -q "^  $hook_name$"; then
        return 0 # Enabled
    fi

    # If not listed anywhere, assume enabled (default behavior)
    return 0
}

# Exit hook with message if disabled
# Usage: check_hook_enabled_or_exit "script_name.sh" [switch_file_path]
# If no switch_file_path provided, uses centralized project-switch/switch.yaml
check_hook_enabled_or_exit() {
    local hook_name="$1"
    local switch_file="${2}"

    if ! is_hook_enabled "$hook_name" "$switch_file"; then
        # Silent exit - hook is disabled
        exit 0
    fi
}

# EOF
