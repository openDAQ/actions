#!/usr/bin/env bash
#
# platform-format.sh - Platform alias parser and validator
# 
# A lightweight shell script for parsing, validating, and composing platform
# aliases in the format {os}{version}-{arch} (Linux/macOS) or win{arch} (Windows).
#
# Compatible with bash 3.2+ and zsh
#
# =============================================================================
# USAGE AS CLI TOOL
# =============================================================================
#
# Synopsis:
#   platform-format.sh [OPTIONS] <command> [arguments]
#
# Global Options (can be placed anywhere in command line):
#   --verbose, -v       Enable verbose output
#   --debug, -d         Enable debug output
#   --quiet, -q         Suppress error messages
#
# Commands:
#   validate <platform> [flags]
#     Validate a platform alias and optionally check its type
#     Flags: --is-unix, --is-linux, --is-ubuntu, --is-debian, --is-macos, --is-win
#     Exit code: 0 if valid/true, 1 if invalid/false
#
#   parse|extract <platform> [flags]
#     Parse platform into components
#     Flags: --os-name, --os-version, --os-arch
#     Output: Space-separated components to stdout
#
#   compose --os-name <n> [--os-version <v>] --os-arch <a>
#     Compose platform alias from components
#     Output: Platform alias to stdout
#
#   --list-platforms
#     List all supported platforms
#     Output: One platform per line to stdout
#
# =============================================================================
# USAGE AS LIBRARY
# =============================================================================
#
# Source the script to use functions in your own scripts:
#
#   source platform-format.sh
#   
#   # Use public functions (prefix: daq_platform_*)
#   daq_platform_validate "ubuntu20.04-arm64" --is-linux
#   result=$(daq_platform_parse "macos14-arm64" --os-version)
#   platform=$(daq_platform_compose --os-name debian --os-version 11 --os-arch arm64)
#   daq_platform_list
#
# =============================================================================
# EXAMPLES
# =============================================================================
#
# Validate platforms:
#   ./platform-format.sh validate ubuntu20.04-arm64
#   ./platform-format.sh validate ubuntu20.04-arm64 --is-linux
#
# Parse platform components:
#   ./platform-format.sh parse ubuntu20.04-arm64
#   # Output: ubuntu 20.04 arm64
#   
#   ./platform-format.sh parse win64 --os-name
#   # Output: win
#
# Compose platforms:
#   ./platform-format.sh compose --os-name ubuntu --os-version 20.04 --os-arch arm64
#   # Output: ubuntu20.04-arm64
#
# With global flags:
#   ./platform-format.sh --verbose validate ubuntu20.04-arm64
#   ./platform-format.sh --debug parse macos14-arm64
#
# =============================================================================

# Compatible with bash 3.2+ and zsh
set -u
if [ -n "${BASH_VERSION:-}" ]; then
    set -o pipefail
fi

# =============================================================================
# Configuration: Supported Platforms
# =============================================================================
# These arrays define all supported platform versions and architectures.
# Add new versions here to extend platform support.

# Supported Ubuntu versions
__DAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")

# Supported Debian versions
__DAQ_PLATFORM_DEBIAN_VERSIONS=("8" "9" "10" "11" "12")

# Supported macOS versions
__DAQ_PLATFORM_MACOS_VERSIONS=("13" "14" "15" "16" "17" "18" "26")

# Supported Windows architectures (32-bit, 64-bit)
__DAQ_PLATFORM_WIN_ARCHS=("32" "64")

# Supported Linux/macOS architectures
__DAQ_PLATFORM_LINUX_ARCHS=("arm64" "x86_64")

# =============================================================================
# Global Runtime Flags
# =============================================================================
# These flags control output behavior and can be set via command-line options
# or when sourcing the script as a library.

# Enable verbose output (0=off, 1=on)
# Set via --verbose or -v flag
__DAQ_PLATFORM_VERBOSE=0

# Enable debug output (0=off, 1=on)
# Set via --debug or -d flag
__DAQ_PLATFORM_DEBUG=0

# Enable quiet mode - suppress error messages (0=off, 1=on)
# Set via --quiet or -q flag
__DAQ_PLATFORM_QUIET=0

# Helper functions for output
# ==========================

# Print verbose message to stderr
# Arguments:
#   $@ - Message to print
# Output:
#   Prints "[VERBOSE] <message>" to stderr if verbose mode is enabled
# Exit code: 0
__daq_platform_verbose() {
    if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ]; then
        echo "[VERBOSE] $*" >&2
    fi
}

# Print debug message to stderr
# Arguments:
#   $@ - Message to print
# Output:
#   Prints "[DEBUG] <message>" to stderr if debug mode is enabled
# Exit code: 0
__daq_platform_debug() {
    if [ "$__DAQ_PLATFORM_DEBUG" -eq 1 ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Print error message to stderr with optional details
# Arguments:
#   $1 - Error message
#   $@ - Optional additional details (shown only in verbose mode)
# Output:
#   Prints "Error: <message>" to stderr unless quiet mode is enabled
#   In verbose mode, also prints "  Details: <details>" if provided
# Exit code: 0
__daq_platform_error() {
    if [ "$__DAQ_PLATFORM_QUIET" -eq 0 ]; then
        echo "Error: $1" >&2
        shift
        if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ] && [ $# -gt 0 ]; then
            echo "  Details: $*" >&2
        fi
    fi
}

# Platform Management Functions
# ==============================

# Generate list of all supported platform aliases
# Arguments: None
# Output:
#   Prints one platform alias per line to stdout
#   Format: {os}{version}-{arch} (Linux/macOS) or win{arch} (Windows)
#   Example output:
#     ubuntu20.04-arm64
#     ubuntu20.04-x86_64
#     debian11-arm64
#     macos14-arm64
#     win64
# Exit code: 0
__daq_platform_generate_platforms() {
    local platforms=()
    
    __daq_platform_debug "Generating list of supported platforms"
    
    # Ubuntu
    for ver in "${__DAQ_PLATFORM_UBUNTU_VERSIONS[@]}"; do
        for arch in "${__DAQ_PLATFORM_LINUX_ARCHS[@]}"; do
            platforms+=("ubuntu${ver}-${arch}")
        done
    done
    
    # Debian
    for ver in "${__DAQ_PLATFORM_DEBIAN_VERSIONS[@]}"; do
        for arch in "${__DAQ_PLATFORM_LINUX_ARCHS[@]}"; do
            platforms+=("debian${ver}-${arch}")
        done
    done
    
    # macOS
    for ver in "${__DAQ_PLATFORM_MACOS_VERSIONS[@]}"; do
        for arch in "${__DAQ_PLATFORM_LINUX_ARCHS[@]}"; do
            platforms+=("macos${ver}-${arch}")
        done
    done
    
    # Windows
    for arch in "${__DAQ_PLATFORM_WIN_ARCHS[@]}"; do
        platforms+=("win${arch}")
    done
    
    __daq_platform_debug "Generated ${#platforms[@]} platforms"
    printf '%s\n' "${platforms[@]}"
}

# Check if a platform alias is valid
# Arguments:
#   $1 - Platform alias to validate
# Output: None
# Exit code:
#   0 - Platform is valid
#   1 - Platform is invalid
__daq_platform_is_valid() {
    local platform="$1"
    local valid_platforms
    
    __daq_platform_debug "Checking if platform is valid: $platform"
    valid_platforms=$(__daq_platform_generate_platforms)
    
    if echo "$valid_platforms" | grep -qx "$platform"; then
        __daq_platform_debug "Platform is valid: $platform"
        return 0
    else
        __daq_platform_debug "Platform is NOT valid: $platform"
        return 1
    fi
}

# Parse platform alias into its components (internal implementation)
# Arguments:
#   $1 - Platform alias (e.g., ubuntu20.04-arm64, win64)
# Output:
#   For Linux/macOS: Prints "os_name os_version os_arch" to stdout
#   For Windows: Prints "os_name os_arch" to stdout (no version)
#   Example:
#     ubuntu20.04-arm64 → "ubuntu 20.04 arm64"
#     win64 → "win 64"
# Exit code:
#   0 - Successfully parsed
#   1 - Invalid platform or parsing error
__daq_platform_parse() {
    local platform="$1"
    
    __daq_platform_debug "Parsing platform: $platform"
    
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_error "Invalid platform alias: $platform"
        exit 1
    fi
    
    local os_name=""
    local os_version=""
    local os_arch=""
    
    # Determine platform type and extract components
    case "$platform" in
        win32|win64)
            # Windows: extract arch
            os_name="win"
            os_arch=$(echo "$platform" | sed 's/^win//')
            __daq_platform_verbose "Parsed Windows platform: name=$os_name arch=$os_arch"
            # Output: name arch (no version for Windows)
            echo "$os_name" "$os_arch"
            return 0
            ;;
        ubuntu*)
            # Ubuntu: extract version and arch
            os_name="ubuntu"
            os_version=$(echo "$platform" | sed 's/^ubuntu\([0-9.]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            __daq_platform_verbose "Parsed Ubuntu platform: name=$os_name version=$os_version arch=$os_arch"
            ;;
        debian*)
            # Debian: extract version and arch
            os_name="debian"
            os_version=$(echo "$platform" | sed 's/^debian\([0-9]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            __daq_platform_verbose "Parsed Debian platform: name=$os_name version=$os_version arch=$os_arch"
            ;;
        macos*)
            # macOS: extract version and arch
            os_name="macos"
            os_version=$(echo "$platform" | sed 's/^macos\([0-9]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            __daq_platform_verbose "Parsed macOS platform: name=$os_name version=$os_version arch=$os_arch"
            ;;
        *)
            __daq_platform_error "Cannot parse platform: $platform"
            exit 1
            ;;
    esac
    
    # Output: name version arch (for Linux/macOS)
    echo "$os_name" "$os_version" "$os_arch"
}

# Public API Functions
# ====================

# Validate a platform alias and optionally check its type
# Arguments:
#   $1 - Platform alias to validate (e.g., ubuntu20.04-arm64)
#   $2 - Optional type check flag:
#        --is-unix    Check if platform is Unix-based (Ubuntu/Debian/macOS)
#        --is-linux   Check if platform is Linux (Ubuntu/Debian)
#        --is-ubuntu  Check if platform is Ubuntu
#        --is-debian  Check if platform is Debian
#        --is-macos   Check if platform is macOS
#        --is-win     Check if platform is Windows
# Output: None (uses exit codes only)
# Exit code:
#   0 - Platform is valid (or type check passed)
#   1 - Platform is invalid (or type check failed)
# Examples:
#   daq_platform_validate ubuntu20.04-arm64              # Returns 0
#   daq_platform_validate ubuntu20.04-arm64 --is-linux  # Returns 0
#   daq_platform_validate ubuntu20.04-arm64 --is-macos  # Returns 1
daq_platform_validate() {
    local platform="$1"
    shift
    
    __daq_platform_debug "Validating platform: $platform"
    
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_verbose "Platform validation failed: $platform"
        exit 1
    fi
    
    # If no flags, just validate and exit
    if [ $# -eq 0 ]; then
        __daq_platform_verbose "Platform is valid: $platform"
        exit 0
    fi
    
    # Determine OS name from platform using case
    local os_name=""
    case "$platform" in
        win*)
            os_name="win"
            ;;
        ubuntu*)
            os_name="ubuntu"
            ;;
        debian*)
            os_name="debian"
            ;;
        macos*)
            os_name="macos"
            ;;
    esac
    
    __daq_platform_debug "OS name detected: $os_name"
    
    # Check flags
    local flag="$1"
    local result=0
    case "$flag" in
        --is-unix)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ] || [ "$os_name" = "macos" ]
            result=$?
            __daq_platform_verbose "Check --is-unix for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        --is-linux)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ]
            result=$?
            __daq_platform_verbose "Check --is-linux for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        --is-ubuntu)
            [ "$os_name" = "ubuntu" ]
            result=$?
            __daq_platform_verbose "Check --is-ubuntu for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        --is-debian)
            [ "$os_name" = "debian" ]
            result=$?
            __daq_platform_verbose "Check --is-debian for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        --is-macos)
            [ "$os_name" = "macos" ]
            result=$?
            __daq_platform_verbose "Check --is-macos for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        --is-win)
            [ "$os_name" = "win" ]
            result=$?
            __daq_platform_verbose "Check --is-win for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            exit $result
            ;;
        *)
            __daq_platform_error "Unknown flag: $flag"
            exit 1
            ;;
    esac
}

# Parse/extract platform components from a platform alias
# Arguments:
#   $1 - Platform alias (e.g., ubuntu20.04-arm64, win64)
#   $2+ - Optional component flags:
#         --os-name     Extract only OS name
#         --os-version  Extract only OS version
#         --os-arch     Extract only OS architecture
#         (multiple flags can be combined)
# Output:
#   Without flags: Prints all components separated by spaces
#     For Linux/macOS: "os_name os_version os_arch"
#     For Windows: "os_name os_arch" (no version)
#   With flags: Prints only requested components separated by spaces
# Exit code:
#   0 - Successfully parsed
#   1 - Invalid platform or error
# Examples:
#   daq_platform_parse ubuntu20.04-arm64
#     Output: ubuntu 20.04 arm64
#   daq_platform_parse ubuntu20.04-arm64 --os-name
#     Output: ubuntu
#   daq_platform_parse win64 --os-name --os-arch
#     Output: win 64
daq_platform_parse() {
    local platform="$1"
    shift
    
    __daq_platform_debug "Parse command invoked for: $platform"
    
    local parsed_output
    parsed_output=$(__daq_platform_parse "$platform")
    
    # Determine if this is Windows (2 components) or Linux/macOS (3 components)
    local os_name os_version os_arch
    local component_count
    component_count=$(echo "$parsed_output" | wc -w | tr -d ' ')
    
    if [ "$component_count" -eq 2 ]; then
        # Windows: name arch
        read -r os_name os_arch <<< "$parsed_output"
        os_version=""
        __daq_platform_debug "Windows platform detected: 2 components"
    else
        # Linux/macOS: name version arch
        read -r os_name os_version os_arch <<< "$parsed_output"
        __daq_platform_debug "Linux/macOS platform detected: 3 components"
    fi
    
    # If no flags, output all components
    if [ $# -eq 0 ]; then
        __daq_platform_verbose "Outputting all components"
        echo "$parsed_output"
        exit 0
    fi
    
    # Output specific components
    local output=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --os-name)
                output+=("$os_name")
                __daq_platform_debug "Adding os-name to output: $os_name"
                ;;
            --os-version)
                if [ -n "$os_version" ]; then
                    output+=("$os_version")
                    __daq_platform_debug "Adding os-version to output: $os_version"
                fi
                ;;
            --os-arch)
                output+=("$os_arch")
                __daq_platform_debug "Adding os-arch to output: $os_arch"
                ;;
            *)
                __daq_platform_error "Unknown flag: $1"
                exit 1
                ;;
        esac
        shift
    done
    
    # Only output if we have components
    if [ ${#output[@]} -gt 0 ]; then
        printf '%s\n' "${output[*]}"
    fi
}

# Alias for daq_platform_parse
# See daq_platform_parse documentation for details
daq_platform_extract() {
    __daq_platform_debug "Extract command (alias for parse)"
    daq_platform_parse "$@"
}

# Compose a platform alias from individual components
# Arguments:
#   --os-name <name>      OS name (ubuntu, debian, macos, win) [REQUIRED]
#   --os-version <ver>    OS version (required for ubuntu/debian/macos, not used for win)
#   --os-arch <arch>      Architecture (arm64, x86_64 for Linux/macOS; 32, 64 for Windows) [REQUIRED]
# Output:
#   Prints composed platform alias to stdout
#   Format: {os}{version}-{arch} for Linux/macOS, win{arch} for Windows
# Exit code:
#   0 - Successfully composed valid platform
#   1 - Missing required arguments or invalid composition
# Examples:
#   daq_platform_compose --os-name ubuntu --os-version 20.04 --os-arch arm64
#     Output: ubuntu20.04-arm64
#   daq_platform_compose --os-name win --os-arch 64
#     Output: win64
daq_platform_compose() {
    local os_name=""
    local os_version=""
    local os_arch=""
    
    __daq_platform_debug "Compose command invoked"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --os-name)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    __daq_platform_error "--os-name requires a value"
                    exit 1
                fi
                os_name="$2"
                __daq_platform_debug "Set os-name: $os_name"
                shift 2
                ;;
            --os-version)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    __daq_platform_error "--os-version requires a value"
                    exit 1
                fi
                os_version="$2"
                __daq_platform_debug "Set os-version: $os_version"
                shift 2
                ;;
            --os-arch)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    __daq_platform_error "--os-arch requires a value"
                    exit 1
                fi
                os_arch="$2"
                __daq_platform_debug "Set os-arch: $os_arch"
                shift 2
                ;;
            *)
                __daq_platform_error "Unknown argument: $1"
                exit 1
                ;;
        esac
    done
    
    # Validate required fields
    if [ -z "$os_name" ]; then
        __daq_platform_error "--os-name is required"
        exit 1
    fi
    
    if [ -z "$os_arch" ]; then
        __daq_platform_error "--os-arch is required"
        exit 1
    fi
    
    # Compose platform alias
    local platform=""
    if [ "$os_name" = "win" ]; then
        platform="win${os_arch}"
        __daq_platform_verbose "Composing Windows platform: $platform"
    else
        if [ -z "$os_version" ]; then
            __daq_platform_error "--os-version is required for non-Windows platforms"
            exit 1
        fi
        platform="${os_name}${os_version}-${os_arch}"
        __daq_platform_verbose "Composing Linux/macOS platform: $platform"
    fi
    
    # Validate composed platform
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_error "Invalid platform composition: $platform"
        exit 1
    fi
    
    __daq_platform_verbose "Successfully composed platform: $platform"
    echo "$platform"
}

# List all supported platform aliases
# Arguments: None
# Output:
#   Prints all supported platform aliases, one per line, to stdout
# Exit code: 0
# Example:
#   daq_platform_list
#     Output:
#       ubuntu20.04-arm64
#       ubuntu20.04-x86_64
#       debian11-arm64
#       ...
daq_platform_list() {
    __daq_platform_verbose "Listing all supported platforms"
    __daq_platform_generate_platforms
}

# Main CLI entry point
# Processes command-line arguments in two passes:
#   1. Extract and process global flags (--verbose, --debug, --quiet)
#   2. Route to appropriate command handler with remaining arguments
# 
# Arguments:
#   Global flags (can appear anywhere):
#     --verbose, -v   Enable verbose output
#     --debug, -d     Enable debug output
#     --quiet, -q     Suppress error messages
#   
#   Commands:
#     validate <platform> [--is-*]
#     parse <platform> [--os-name] [--os-version] [--os-arch]
#     extract <platform> [--os-name] [--os-version] [--os-arch]
#     compose --os-name <n> [--os-version <v>] --os-arch <a>
#     --list-platforms
# 
# Output:
#   Usage information if no arguments provided
#   Otherwise delegates to appropriate command function
# 
# Exit code:
#   0 - Success
#   1 - Error (invalid command, missing arguments, etc.)
# 
# Examples:
#   __daq_platform_main validate ubuntu20.04-arm64
#   __daq_platform_main --verbose parse macos14-arm64
#   __daq_platform_main --debug compose --os-name debian --os-version 11 --os-arch arm64
__daq_platform_main() {
    # FIRST PASS: Extract global flags
    local remaining_args=()
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --verbose|-v)
                __DAQ_PLATFORM_VERBOSE=1
                shift
                ;;
            --debug|-d)
                __DAQ_PLATFORM_DEBUG=1
                shift
                ;;
            --quiet|-q)
                __DAQ_PLATFORM_QUIET=1
                shift
                ;;
            *)
                # Not a global flag - save for second pass
                remaining_args+=("$1")
                shift
                ;;
        esac
    done
    
    __daq_platform_debug "Global flags parsed: verbose=$__DAQ_PLATFORM_VERBOSE debug=$__DAQ_PLATFORM_DEBUG quiet=$__DAQ_PLATFORM_QUIET"
    
    # SECOND PASS: Process commands with remaining arguments
    set -- "${remaining_args[@]}"
    
    if [ $# -eq 0 ]; then
        if [ "$__DAQ_PLATFORM_QUIET" -eq 0 ]; then
            echo "Usage: $0 [OPTIONS] <command> [arguments]"
            echo ""
            echo "Global Options:"
            echo "  --verbose, -v       Enable verbose output"
            echo "  --debug, -d         Enable debug output"
            echo "  --quiet, -q         Suppress error messages"
            echo ""
            echo "Commands:"
            echo "  validate <platform> [--is-unix|--is-linux|--is-ubuntu|--is-debian|--is-macos|--is-win]"
            echo "  parse <platform> [--os-name] [--os-version] [--os-arch]"
            echo "  extract <platform> [--os-name] [--os-version] [--os-arch]"
            echo "  compose --os-name <n> [--os-version <version>] --os-arch <arch>"
            echo ""
            echo "Options:"
            echo "  --list-platforms    List all supported platforms"
        fi
        exit 1
    fi

    __daq_platform_debug "Processing command: $1"

    case "$1" in
        --list-platforms)
            __daq_platform_verbose "Listing all supported platforms"
            daq_platform_list
            ;;
        validate)
            shift
            daq_platform_validate "$@"
            ;;
        parse)
            shift
            daq_platform_parse "$@"
            ;;
        extract)
            shift
            daq_platform_extract "$@"
            ;;
        compose)
            shift
            daq_platform_compose "$@"
            ;;
        *)
            __daq_platform_error "Unknown command: $1"
            exit 1
            ;;
    esac
}

# =============================================================================
# Script Execution Control
# =============================================================================
# Detect if script is being sourced or executed directly.
# If sourced, only define functions without running main().
# If executed, run main() with command-line arguments.

# Flag to track if script was sourced (0=executed, 1=sourced)
__DAQ_PLATFORM_SOURCED=0

if [ -n "${BASH_VERSION:-}" ]; then
    # Bash: Compare script path with invocation path
    # BASH_SOURCE[0] = script path, $0 = invocation path
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh: Use prompt expansion to get script name
    # %N expands to script/function name
    __DAQ_PLATFORM_SCRIPT_PATH="${(%):-%N}"
    if [ "$__DAQ_PLATFORM_SCRIPT_PATH" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
fi

# Run main only if not sourced
# This allows the script to be used both as:
#   1. CLI tool: ./platform-format.sh validate ubuntu20.04-arm64
#   2. Library: source platform-format.sh && daq_platform_validate ubuntu20.04-arm64
if [ "$__DAQ_PLATFORM_SOURCED" -eq 0 ]; then
    __daq_platform_main "$@"
fi
