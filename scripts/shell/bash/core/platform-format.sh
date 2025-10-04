#!/usr/bin/env bash
#
# platform-format.sh - Platform alias parser and validator
# Compatible with bash 3.2+ and zsh
#
# Usage:
#   ./platform-format.sh validate <platform> [flags]
#   ./platform-format.sh parse|extract <platform> [flags]
#   ./platform-format.sh compose --os-name <n> --os-version <ver> --os-arch <arch>
#   ./platform-format.sh --list-platforms
#
# Can also be sourced to use functions directly:
#   source platform-format.sh
#   daq_platform_validate ubuntu20.04-arm64 --is-linux

# Compatible with bash 3.2+ and zsh
set -u

if [[ -n "${BASH_VERSION:-}" ]]; then    
    # Enable pipefail for Bash 4+ (not available in Bash 3.2)
    if [[ "${BASH_VERSINFO:-0}" -ge 4 ]]; then
        set -o pipefail
    fi
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    setopt PIPE_FAIL 2>/dev/null || true  # Zsh equivalent of pipefail
fi

# Supported platforms
__DAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
__DAQ_PLATFORM_DEBIAN_VERSIONS=("8" "9" "10" "11" "12")
__DAQ_PLATFORM_MACOS_VERSIONS=("13" "14" "15" "16" "17" "18" "26")
__DAQ_PLATFORM_WIN_ARCHS=("32" "64")
__DAQ_PLATFORM_LINUX_ARCHS=("arm64" "x86_64")

# Generate list of all supported platforms
__daq_platform_generate_platforms() {
    local platforms=()
    
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
    
    printf '%s\n' "${platforms[@]}"
}

# Check if platform is valid
__daq_platform_is_valid() {
    local platform="$1"
    local valid_platforms
    valid_platforms=$(__daq_platform_generate_platforms)
    
    if echo "$valid_platforms" | grep -qx "$platform"; then
        return 0
    else
        return 1
    fi
}

# Parse platform alias into components
__daq_platform_parse() {
    local platform="$1"
    
    if ! __daq_platform_is_valid "$platform"; then
        echo "Error: Invalid platform alias: $platform" >&2
        return 1
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
            # Output: name arch (no version for Windows)
            echo "$os_name" "$os_arch"
            return 0
            ;;
        ubuntu*)
            # Ubuntu: extract version and arch
            os_name="ubuntu"
            os_version=$(echo "$platform" | sed 's/^ubuntu\([0-9.]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            ;;
        debian*)
            # Debian: extract version and arch
            os_name="debian"
            os_version=$(echo "$platform" | sed 's/^debian\([0-9]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            ;;
        macos*)
            # macOS: extract version and arch
            os_name="macos"
            os_version=$(echo "$platform" | sed 's/^macos\([0-9]*\)-.*/\1/')
            os_arch=$(echo "$platform" | sed 's/.*-//')
            ;;
        *)
            echo "Error: Cannot parse platform: $platform" >&2
            return 1
            ;;
    esac
    
    # Output: name version arch (for Linux/macOS)
    echo "$os_name" "$os_version" "$os_arch"
}

# Public: Validate platform
daq_platform_validate() {
    local platform="$1"
    shift
    
    if ! __daq_platform_is_valid "$platform"; then
        return 1
    fi
    
    # If no flags, just validate and return
    if [ $# -eq 0 ]; then
        return 0
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
    
    # Check flags
    local flag="$1"
    case "$flag" in
        --is-unix)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ] || [ "$os_name" = "macos" ]
            return $?
            ;;
        --is-linux)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ]
            return $?
            ;;
        --is-ubuntu)
            [ "$os_name" = "ubuntu" ]
            return $?
            ;;
        --is-debian)
            [ "$os_name" = "debian" ]
            return $?
            ;;
        --is-macos)
            [ "$os_name" = "macos" ]
            return $?
            ;;
        --is-win)
            [ "$os_name" = "win" ]
            return $?
            ;;
        *)
            echo "Error: Unknown flag: $flag" >&2
            return 1
            ;;
    esac
}

# Public: Parse/Extract platform components
daq_platform_parse() {
    local platform="$1"
    shift
    
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
    else
        # Linux/macOS: name version arch
        read -r os_name os_version os_arch <<< "$parsed_output"
    fi
    
    # If no flags, output all components
    if [ $# -eq 0 ]; then
        echo "$parsed_output"
        return 0
    fi
    
    # Output specific components
    local output=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --os-name)
                output+=("$os_name")
                ;;
            --os-version)
                if [ -n "$os_version" ]; then
                    output+=("$os_version")
                fi
                ;;
            --os-arch)
                output+=("$os_arch")
                ;;
            *)
                echo "Error: Unknown flag: $1" >&2
                return 1
                ;;
        esac
        shift
    done
    
    if [ ${#output[@]} -gt 0 ]; then
        echo "${output[@]}"
    fi
}

# Public: Alias for parse
daq_platform_extract() {
    daq_platform_parse "$@"
}

# Public: Compose platform from components
daq_platform_compose() {
    local os_name=""
    local os_version=""
    local os_arch=""
    
    while [ $# -gt 0 ]; do
        case "$1" in
            --os-name)
                os_name="$2"
                shift 2
                ;;
            --os-version)
                os_version="$2"
                shift 2
                ;;
            --os-arch)
                os_arch="$2"
                shift 2
                ;;
            *)
                echo "Error: Unknown argument: $1" >&2
                return 1
                ;;
        esac
    done
    
    # Validate required fields
    if [ -z "$os_name" ]; then
        echo "Error: --os-name is required" >&2
        return 1
    fi
    
    if [ -z "$os_arch" ]; then
        echo "Error: --os-arch is required" >&2
        return 1
    fi
    
    # Compose platform alias
    local platform=""
    if [ "$os_name" = "win" ]; then
        platform="win${os_arch}"
    else
        if [ -z "$os_version" ]; then
            echo "Error: --os-version is required for non-Windows platforms" >&2
            return 1
        fi
        platform="${os_name}${os_version}-${os_arch}"
    fi
    
    # Validate composed platform
    if ! __daq_platform_is_valid "$platform"; then
        echo "Error: Invalid platform composition: $platform" >&2
        return 1
    fi
    
    echo "$platform"
}

# Public: List all platforms
daq_platform_list() {
    __daq_platform_generate_platforms
}

# Main CLI entry point
__daq_platform_main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  validate <platform> [--is-unix|--is-linux|--is-ubuntu|--is-debian|--is-macos|--is-win]"
        echo "  parse <platform> [--os-name] [--os-version] [--os-arch]"
        echo "  extract <platform> [--os-name] [--os-version] [--os-arch]"
        echo "  compose --os-name <n> [--os-version <version>] --os-arch <arch>"
        echo ""
        echo "Options:"
        echo "  --list-platforms    List all supported platforms"
        return 1
    fi

    case "$1" in
        --list-platforms)
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
            echo "Error: Unknown command: $1" >&2
            return 1
            ;;
    esac
    
    return 0
}

# Detect if script is being sourced
__DAQ_PLATFORM_SOURCED=0
if [ -n "${BASH_VERSION:-}" ]; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
fi

# Run main only if not sourced
if [ "$__DAQ_PLATFORM_SOURCED" -eq 0 ]; then
    __daq_platform_main "$@"
    exit $?
fi
