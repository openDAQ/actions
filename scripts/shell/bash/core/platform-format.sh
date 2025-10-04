#!/usr/bin/env bash
#
# platform-format.sh - Platform alias parser and validator
# Compatible with bash 3.2+ and zsh
#
# Usage:
#   ./platform-format.sh [OPTIONS] <command> [arguments]
#
# Global Options (can be placed anywhere in command line):
#   --verbose, -v       Enable verbose output
#   --debug, -d         Enable debug output
#   --quiet, -q         Suppress error messages
#
# Commands:
#   validate <platform> [flags]
#   parse|extract <platform> [flags]
#   compose --os-name <n> --os-version <ver> --os-arch <arch>
#   --list-platforms
#
# Examples:
#   ./platform-format.sh --verbose validate ubuntu20.04-arm64 --is-linux
#   ./platform-format.sh validate --debug ubuntu20.04-arm64
#   ./platform-format.sh --quiet parse invalid-platform
#
# Can also be sourced to use functions directly:
#   source platform-format.sh
#   daq_platform_validate ubuntu20.04-arm64 --is-linux

# Compatible with bash 3.2+ and zsh
set -eu
if [ -n "${BASH_VERSION:-}" ]; then
    set -o pipefail
fi

# Supported platforms
__DAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
__DAQ_PLATFORM_DEBIAN_VERSIONS=("8" "9" "10" "11" "12")
__DAQ_PLATFORM_MACOS_VERSIONS=("13" "14" "15" "16" "17" "18" "26")
__DAQ_PLATFORM_WIN_ARCHS=("32" "64")
__DAQ_PLATFORM_LINUX_ARCHS=("arm64" "x86_64")

# Global flags
__DAQ_PLATFORM_VERBOSE=0
__DAQ_PLATFORM_DEBUG=0
__DAQ_PLATFORM_QUIET=0

# Helper functions for output
__daq_platform_verbose() {
    if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ]; then
        echo "[VERBOSE] $*" >&2
    fi
}

__daq_platform_debug() {
    if [ "$__DAQ_PLATFORM_DEBUG" -eq 1 ]; then
        echo "[DEBUG] $*" >&2
    fi
}

__daq_platform_error() {
    if [ "$__DAQ_PLATFORM_QUIET" -eq 0 ]; then
        echo "Error: $1" >&2
        shift
        if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ] && [ $# -gt 0 ]; then
            echo "  Details: $*" >&2
        fi
    fi
}

# Generate list of all supported platforms
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

# Check if platform is valid
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

# Parse platform alias into components
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

# Public: Validate platform
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

# Public: Parse/Extract platform components
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

# Public: Alias for parse
daq_platform_extract() {
    __daq_platform_debug "Extract command (alias for parse)"
    daq_platform_parse "$@"
}

# Public: Compose platform from components
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

# Public: List all platforms
daq_platform_list() {
    __daq_platform_verbose "Listing all supported platforms"
    __daq_platform_generate_platforms
}

# Main CLI entry point
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

# Detect if script is being sourced
__DAQ_PLATFORM_SOURCED=0
if [ -n "${BASH_VERSION:-}" ]; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Use zsh-specific variable, suppress any output
    __DAQ_PLATFORM_SCRIPT_PATH="${(%):-%N}"
    if [ "$__DAQ_PLATFORM_SCRIPT_PATH" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
fi

# Run main only if not sourced
if [ "$__DAQ_PLATFORM_SOURCED" -eq 0 ]; then
    __daq_platform_main "$@"
fi
