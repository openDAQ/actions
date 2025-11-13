#!/bin/bash
# packaging-format.sh - OpenDAQ packaging format detection utility
# This script detects package file extensions based on CPack generators or OS names.
# Compatible with bash 3.2+ and zsh

# Enable error on undefined variables
set -u

# These can be overridden by the user to customize package extensions per OS
: "${OPENDAQ_PACKAGING_WIN:=exe}"
: "${OPENDAQ_PACKAGING_LINUX:=deb}"
: "${OPENDAQ_PACKAGING_MACOS:=tar.gz}"

__DAQ_PACKAGING_VERBOSE=0
__DAQ_PACKAGING_SOURCED=0

# Log message if verbose mode is enabled
# Arguments:
#   $1 - Message to log
__daq_packaging_log() {
    if [[ "${__DAQ_PACKAGING_VERBOSE}" -eq 1 ]]; then
        echo "[INFO] $*" >&2
    fi
}

# Log error message
# Arguments:
#   $1 - Error message
__daq_packaging_error() {
    echo "[ERROR] $*" >&2
}

# Normalize OS name from GitHub runner names to simplified form
# Arguments:
#   $1 - OS name (e.g., "windows-latest", "ubuntu-latest", "macos-latest",
#                 or values from ${{ runner.os }}: "Windows", "Linux", "macOS")
# Returns:
#   Normalized OS name: "windows", "linux", or "macos"
__daq_packaging_normalize_os_name() {
    local os_name="$1"
    
    # Convert to lowercase for case-insensitive matching
    os_name=$(echo "${os_name}" | tr '[:upper:]' '[:lower:]')
    
    __daq_packaging_log "Normalizing OS name: ${os_name}"
    
    # Match common patterns
    if [[ "${os_name}" =~ ^windows.*$ ]] || [[ "${os_name}" =~ ^win.*$ ]]; then
        echo "windows"
    elif [[ "${os_name}" =~ ^ubuntu.*$ ]] || [[ "${os_name}" =~ ^linux.*$ ]] || [[ "${os_name}" =~ ^debian.*$ ]]; then
        echo "linux"
    elif [[ "${os_name}" =~ ^macos.*$ ]] || [[ "${os_name}" =~ ^mac.*$ ]] || [[ "${os_name}" =~ ^osx.*$ ]]; then
        echo "macos"
    else
        __daq_packaging_error "Unknown OS name: ${os_name}"
        return 1
    fi
}

# Main function for CLI mode
__daq_packaging_main() {
    local command=""
    local cpack_generator=""
    local os_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            detect)
                command="detect"
                shift
                ;;
            --cpack-generator)
                cpack_generator="${2-}"
                if [[ -z "$cpack_generator" ]] || [[ "$cpack_generator" == --* ]]; then
                    __daq_packaging_error "Missing value for --cpack-generator"
                    return 1
                fi
                
                shift 2
                ;;
            --os-name)
                os_name="${2-}"
                if [[ -z "$os_name" ]] || [[ "$os_name" == --* ]]; then
                    __daq_packaging_error "Missing value for --os-name"
                    return 1
                fi
                shift 2
                ;;
            --verbose)
                __DAQ_PACKAGING_VERBOSE=1
                shift
                ;;
            -h|--help)
                __daq_packaging_show_help
                return 0
                ;;
            *)
                __daq_packaging_error "Unknown argument: $1"
                __daq_packaging_show_help
                return 1
                ;;
        esac
    done
    
    # Validate command
    if [[ "${command}" != "detect" ]]; then
        __daq_packaging_error "Command 'detect' is required"
        __daq_packaging_show_help
        return 1
    fi
    
    # Execute detection based on provided parameters
    if [[ -n "${cpack_generator}" ]]; then
        __daq_packaging_log "Detecting format from CPack generator: ${cpack_generator}"
        daq_packaging_detect_from_cpack "${cpack_generator}"
    elif [[ -n "${os_name}" ]]; then
        __daq_packaging_log "Detecting format from OS name: ${os_name}"
        daq_packaging_detect_from_os "${os_name}"
    else
        __daq_packaging_error "Either --cpack-generator or --os-name must be specified"
        return 1
    fi
}

# Show help message
__daq_packaging_show_help() {
    cat << EOF
Usage: $0 detect [OPTIONS]

Detect package file extension based on CPack generator or OS name.

Options:
    --cpack-generator <GENERATOR>  Detect extension from CPack generator
                                   (NSIS, ZIP, TGZ, DEB)
    --os-name <OS_NAME>           Detect extension from OS name
                                   Supports: GitHub runner names (windows-latest, ubuntu-latest, macos-latest)
                                            or ${{ runner.os }} values (Windows, Linux, macOS)
    --verbose                      Enable verbose output
    -h, --help                    Show this help message

Environment Variables:
    OPENDAQ_PACKAGING_WIN         Package extension for Windows (default: exe)
    OPENDAQ_PACKAGING_LINUX       Package extension for Linux (default: deb)
    OPENDAQ_PACKAGING_MACOS       Package extension for macOS (default: tar.gz)

Examples:
    $0 detect --cpack-generator NSIS
    $0 detect --os-name windows-latest --verbose
    $0 detect --os-name ubuntu-latest
    $0 detect --os-name Linux              # from \${{ runner.os }}

    # Use as library
    source $0
    daq_packaging_detect_from_os "macos-latest"
EOF
}

# Detect package extension from CPack generator name
# Arguments:
#   $1 - CPack generator name (NSIS, ZIP, TGZ, DEB)
# Outputs:
#   Package file extension
daq_packaging_detect_from_cpack() {
    local generator="$1"
    
    if [[ -z "${generator}" ]]; then
        __daq_packaging_error "CPack generator name is required"
        return 1
    fi
    
    # Convert to uppercase for consistent matching
    generator=$(echo "${generator}" | tr '[:lower:]' '[:upper:]')
    
    __daq_packaging_log "CPack generator: ${generator}"
    
    case "${generator}" in
        NSIS)
            __daq_packaging_log "Detected extension: exe"
            echo "exe"
            ;;
        ZIP)
            __daq_packaging_log "Detected extension: zip"
            echo "zip"
            ;;
        TGZ)
            __daq_packaging_log "Detected extension: tar.gz"
            echo "tar.gz"
            ;;
        DEB)
            __daq_packaging_log "Detected extension: deb"
            echo "deb"
            ;;
        *)
            __daq_packaging_error "Unsupported CPack generator: ${generator}"
            __daq_packaging_error "Supported generators: NSIS, ZIP, TGZ, DEB"
            return 1
            ;;
    esac
}

# Detect package extension from OS name
# Arguments:
#   $1 - OS name (GitHub runner names like "windows-latest", "ubuntu-latest", "macos-latest"
#                 or ${{ runner.os }} values like "Windows", "Linux", "macOS")
# Outputs:
#   Package file extension
daq_packaging_detect_from_os() {
    local os_name="$1"
    
    if [[ -z "${os_name}" ]]; then
        __daq_packaging_error "OS name is required"
        return 1
    fi
    
    # Normalize OS name (handle GitHub runner names)
    local normalized_os
    normalized_os=$(__daq_packaging_normalize_os_name "${os_name}")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    __daq_packaging_log "Normalized OS: ${normalized_os}"
    
    case "${normalized_os}" in
        windows)
            __daq_packaging_log "Using Windows packaging format: ${OPENDAQ_PACKAGING_WIN}"
            echo "${OPENDAQ_PACKAGING_WIN}"
            ;;
        linux)
            __daq_packaging_log "Using Linux packaging format: ${OPENDAQ_PACKAGING_LINUX}"
            echo "${OPENDAQ_PACKAGING_LINUX}"
            ;;
        macos)
            __daq_packaging_log "Using macOS packaging format: ${OPENDAQ_PACKAGING_MACOS}"
            echo "${OPENDAQ_PACKAGING_MACOS}"
            ;;
        *)
            __daq_packaging_error "Unsupported OS: ${normalized_os}"
            return 1
            ;;
    esac
}

# Flag to track if script was sourced (0=executed, 1=sourced)
__DAQ_PACKAGING_SOURCED=0

if [ -n "${BASH_VERSION:-}" ]; then
    # Bash: Compare script path with invocation path
    # BASH_SOURCE[0] = script path, $0 = invocation path
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_PACKAGING_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh: Use prompt expansion to get script name
    if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
        __DAQ_PACKAGING_SOURCED=1
    fi
fi

# Run CLI mode if not sourced
if [[ "${__DAQ_PACKAGING_SOURCED}" -eq 0 ]]; then
    __daq_packaging_main "$@"
    exit $?
fi
