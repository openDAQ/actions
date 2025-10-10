#!/usr/bin/env bash
# Path conversion utilities for cross-platform support (Windows/Cygwin/Git Bash)

# Detect if running on Windows
__daq_tests_is_windows() {
    case "$(uname -s)" in
        CYGWIN*|MINGW*|MSYS*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if cygpath is available
__daq_tests_has_cygpath() {
    command -v cygpath >/dev/null 2>&1
}

# Convert Windows path to Unix path
# Usage: __daq_tests_to_unix_path "C:\Users\..."
__daq_tests_to_unix_path() {
    local path="$1"
    
    if [[ -z "${path}" ]]; then
        echo ""
        return 0
    fi
    
    # If not on Windows, return as-is
    if ! __daq_tests_is_windows; then
        echo "${path}"
        return 0
    fi
    
    # If cygpath is available, use it
    if __daq_tests_has_cygpath; then
        cygpath -u "${path}" 2>/dev/null || echo "${path}"
        return 0
    fi
    
    # Fallback: manual conversion for Git Bash
    # Convert C:\path\to\file to /c/path/to/file
    local converted="${path}"
    
    # Replace all backslashes with forward slashes using tr
    converted=$(echo "${converted}" | tr '\\' '/')
    
    # Convert drive letter (C: -> /c)
    if [[ "${converted}" =~ ^([A-Za-z]): ]]; then
        local drive="${BASH_REMATCH[1]}"
        drive="${drive,,}"  # lowercase
        converted="/${drive}${converted#*:}"
    fi
    
    echo "${converted}"
}

# Convert Unix path to Windows path (if needed)
# Usage: __daq_tests_to_windows_path "/c/Users/..."
__daq_tests_to_windows_path() {
    local path="$1"
    
    if [[ -z "${path}" ]]; then
        echo ""
        return 0
    fi
    
    # If not on Windows, return as-is
    if ! __daq_tests_is_windows; then
        echo "${path}"
        return 0
    fi
    
    # If cygpath is available, use it
    if __daq_tests_has_cygpath; then
        cygpath -w "${path}" 2>/dev/null || echo "${path}"
        return 0
    fi
    
    # Fallback: manual conversion for Git Bash
    # Convert /c/path/to/file to C:\path\to\file
    local converted="${path}"
    
    # Convert drive path (/c/ -> C:\)
    if [[ "${converted}" =~ ^/([a-z])/ ]]; then
        local drive="${BASH_REMATCH[1]}"
        drive="${drive^^}"  # uppercase
        converted="${drive}:${converted#/[a-z]}"
    fi
    
    # Replace forward slashes with backslashes using tr
    converted=$(echo "${converted}" | tr '/' '\\')
    
    echo "${converted}"
}

# Normalize path to Unix format (for internal use)
# This ensures all internal paths are in Unix format
__daq_tests_normalize_path() {
    local path="$1"
    
    if [[ -z "${path}" ]]; then
        echo ""
        return 0
    fi
    
    # Convert to Unix path
    local normalized
    normalized=$(__daq_tests_to_unix_path "${path}")
    
    # Expand to absolute path if relative
    if [[ "${normalized}" != /* ]]; then
        normalized="$(cd "${normalized}" 2>/dev/null && pwd)" || normalized="${path}"
    fi
    
    echo "${normalized}"
}

# Get platform name for display
__daq_tests_get_platform() {
    if __daq_tests_is_windows; then
        if __daq_tests_has_cygpath; then
            echo "Windows (Cygwin)"
        else
            echo "Windows (Git Bash)"
        fi
    else
        case "$(uname -s)" in
            Linux*)
                echo "Linux"
                ;;
            Darwin*)
                echo "macOS"
                ;;
            *)
                echo "Unix"
                ;;
        esac
    fi
}

# Initialize paths - convert to Unix format if on Windows
__daq_tests_paths_init() {
    # Convert OPENDAQ_TESTS_SCRIPTS_DIR if set
    if [[ -n "${OPENDAQ_TESTS_SCRIPTS_DIR:-}" ]]; then
        OPENDAQ_TESTS_SCRIPTS_DIR=$(__daq_tests_normalize_path "${OPENDAQ_TESTS_SCRIPTS_DIR}")
        export OPENDAQ_TESTS_SCRIPTS_DIR
    fi
    
    # Convert OPENDAQ_TESTS_SUITES_DIR if set
    if [[ -n "${OPENDAQ_TESTS_SUITES_DIR:-}" ]]; then
        OPENDAQ_TESTS_SUITES_DIR=$(__daq_tests_normalize_path "${OPENDAQ_TESTS_SUITES_DIR}")
        export OPENDAQ_TESTS_SUITES_DIR
    fi
    
    # Log platform info in verbose mode
    if [[ "${OPENDAQ_TESTS_VERBOSE:-0}" -eq 1 ]]; then
        __daq_tests_log_verbose "Platform: $(__daq_tests_get_platform)"
        if __daq_tests_is_windows; then
            if __daq_tests_has_cygpath; then
                __daq_tests_log_verbose "Path conversion: cygpath available"
            else
                __daq_tests_log_verbose "Path conversion: fallback mode"
            fi
        fi
    fi
}
