#!/usr/bin/env bash
# =============================================================================
# cmn-fs.sh - Common FS utilities for path manipulation
# Namespace: daq_fs
# Compatible with bash 3.2+ and zsh
# =============================================================================

# Set strict mode for undefined variables
set -u

# Determine script directory
__DAQ_FS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script dir $__DAQ_FS_SCRIPT_DIR"

# -----------------------------------------------------------------------------
# API private
# -----------------------------------------------------------------------------

# Detect if script is being sourced or executed
# Works in both bash and zsh
__daq_fs_sourced() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        # zsh
        [ "${ZSH_EVAL_CONTEXT:-}" = "toplevel" ] && return 1
        return 0
    else
        # bash
        [ "${BASH_SOURCE[0]}" != "${0}" ] && return 0
        return 1
    fi
}

# Shows brief help message
__daq_fs_help_show() {
    cat << 'EOF'
Usage: cmn-os.sh <action> [arguments...]

Actions:
  --unix <path>              Convert path to Unix format
  --join <part1> [part2...]  Join path components

Examples:
  cmn-os.sh --unix "C:\Users\path\to\file\"
  cmn-os.sh --join "/home/user" "Documents" "file.txt"
  cmn-os.sh --unix "D:\Projects\myapp"
EOF
}

# -----------------------------------------------------------------------------
# API public
# -----------------------------------------------------------------------------

# Converts path to Unix format and removes trailing separator if present
# Usage: daq_fs_path_unix <path>
# Returns: Normalized Unix path without trailing slash
daq_fs_path_unix() {
    local path="$1"
    
    # Convert Windows path to Unix (replace backslashes with forward slashes)
    # Using sed for maximum compatibility
    path=$(echo "$path" | sed 's/\\/\//g')
    
    # Normalize Windows drive letter (C: -> /c, C:/ -> /c)
    # Match pattern: letter followed by colon at the start
    if echo "$path" | grep -q '^[a-zA-Z]:'; then
        local drive=$(echo "$path" | sed 's/^\([a-zA-Z]\):.*/\1/')
        local rest=$(echo "$path" | sed 's/^[a-zA-Z]://')
        # Convert drive letter to lowercase
        drive=$(echo "$drive" | tr '[:upper:]' '[:lower:]')
        path="/${drive}${rest}"
    fi
    
    # Replace multiple consecutive slashes with single slash
    path=$(echo "$path" | sed 's#/\{2,\}#/#g')
    
    # Remove trailing slash if present (but keep root "/")
    if [ "$path" != "/" ]; then
        # Remove trailing slash using parameter expansion
        while [ "${path%/}" != "$path" ]; do
            path="${path%/}"
        done
    fi
    
    echo "$path"
}

# Joins path components into Unix-style path
# Usage: daq_fs_path_join <part1> <part2> [part3...]
# Returns: Joined Unix path
daq_fs_path_join() {
    if [ $# -eq 0 ]; then
        echo ""
        return
    fi
    
    local result=""
    local first=1
    local part
    
    for part in "$@"; do
        # Normalize each part
        part=$(daq_fs_path_unix "$part")
        
        # Skip empty parts
        [ -z "$part" ] && continue
        
        if [ $first -eq 1 ]; then
            result="$part"
            first=0
        else
            # Remove leading slashes from part
            while [ "${part#/}" != "$part" ]; do
                part="${part#/}"
            done
            
            # Skip if part became empty after removing slashes
            [ -z "$part" ] && continue
            
            # Append part with separator
            result="${result}/${part}"
        fi
    done
    
    echo "$result"
}

# -----------------------------------------------------------------------------
# CLI interface
# -----------------------------------------------------------------------------

__daq_fs_main() {
    if [ $# -eq 0 ]; then
        __daq_fs_help_show
        return 1
    fi

    action="$1"
    shift

    case "$action" in
        --help)
            __daq_fs_help_show
            ;;
        --unix)
            daq_fs_path_unix "$1"
            ;;
        --join)
            daq_fs_path_join "$@"
            ;;
        *)
            echo "Error: Unknown action '$action'" >&2
            return 1
            ;;
    esac
}

if ! __daq_fs_sourced; then
    __daq_fs_main "$@"
    exit $?
fi
