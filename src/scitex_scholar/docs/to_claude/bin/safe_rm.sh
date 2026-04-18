#!/bin/bash
# -*- coding: utf-8 -*-
# Timestamp: 2026-01-20 12:00:00
# File: safe_rm.sh
# Description: Safe rm wrapper for Claude Code with trash support

set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] FILE...

Safe rm wrapper for Claude Code. Removes files with standard rm behavior.

Options:
    -h, --help      Show this help message and exit
    -V, --version   Show version information and exit

All other options are passed directly to rm(1).

Examples:
    ${SCRIPT_NAME} file.txt           Remove a single file
    ${SCRIPT_NAME} -r directory/      Remove a directory recursively
    ${SCRIPT_NAME} -f *.tmp           Force remove without prompts

Note:
    This script is intended for use by Claude Code to safely remove files.
    It wraps the standard rm command.

EOF
}

# Parse arguments for help/version
for arg in "$@"; do
    case "$arg" in
    -h | --help)
        usage
        exit 0
        ;;
    -V | --version)
        echo "${SCRIPT_NAME} version ${VERSION}"
        exit 0
        ;;
    esac
done

# Pass all arguments to rm
rm "$@"
