#!/usr/bin/env bash

# beauty-slurm: Core library bootstrap script
# Handles workspace path resolution, global flag parsing, configuration loading, 
# and automatic fallback to SLURM mocks if live binaries are unavailable.

# Resolve the absolute path of the directory containing this script
# Works across standard macOS (zsh/bash) and Linux
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$CORE_DIR")"

# Expose base directories
export BEAUTY_SLURM_CORE_DIR="$CORE_DIR"
export BEAUTY_SLURM_BASE_DIR="$BASE_DIR"

# Source the styling engine
if [ -f "$CORE_DIR/colors.sh" ]; then
    source "$CORE_DIR/colors.sh"
else
    echo "Error: lib/colors.sh not found." >&2
    exit 1
fi

# Load user profile overrides if present
if [ -f "$HOME/.beauty-slurm.cfg" ]; then
    source "$HOME/.beauty-slurm.cfg"
fi

# Parse global options common across all commands
# E.g. --color, --mock, --help
parse_global_flags() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --color=always)
                export FORCE_COLOR="always"
                init_colors
                shift
                ;;
            --color=never)
                export FORCE_COLOR="never"
                init_colors
                shift
                ;;
            --color=auto)
                export FORCE_COLOR="auto"
                init_colors
                shift
                ;;
            --mock)
                export BEAUTY_SLURM_MOCK=1
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    # Restore non-global arguments
    if [ "${#args[@]}" -gt 0 ]; then
        set -- "${args[@]}"
    else
        set --
    fi
}

# Check if a command exists on the PATH
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Bootstrap Slurm Command Routing
# Injects the mock layer into the PATH if BEAUTY_SLURM_MOCK is set
# or if actual SLURM commands cannot be found in the current environment.
bootstrap_slurm_environment() {
    local mock_required=0
    
    if [ "${BEAUTY_SLURM_MOCK:-0}" -eq 1 ]; then
        mock_required=1
    elif ! cmd_exists squeue || ! cmd_exists sinfo; then
        mock_required=1
    fi
    
    if [ "$mock_required" -eq 1 ]; then
        export BEAUTY_SLURM_MOCK=1
        local mock_path="$BASE_DIR/mock"
        if [ -d "$mock_path" ]; then
            # Prepend mock path to ensure mocks take priority over actual commands
            export PATH="$mock_path:$PATH"
        else
            error "SLURM binaries not found, and Mocking Layer ($mock_path) is missing!"
            exit 1
        fi
    fi
}
