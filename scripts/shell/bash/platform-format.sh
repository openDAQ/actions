#!/usr/bin/env bash
# platform-format.sh - Platform alias parser and validator
# Supports parsing, validating, and composing and extracting platform aliases
# Compatible with bash 3.2+ and zsh

# Enable error on undefined variables
set -u

# Set pipefail based on shell type
if [ -n "${BASH_VERSION:-}" ]; then
    # Bash: use pipefail if available (bash 3.0+)
    if [ "${BASH_VERSINFO[0]}" -ge 3 ]; then
        set -o pipefail
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh: use pipefail
    setopt pipefail 2>/dev/null || true
fi

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

# Enable verbose output (0=off, 1=on)
# Set via --verbose or -v flag
__DAQ_PLATFORM_VERBOSE=0

# Enable debug output (0=off, 1=on)
# Set via --debug or -d flag
__DAQ_PLATFORM_DEBUG=0

# Enable quiet mode - suppress error messages (0=off, 1=on)
# Set via --quiet or -q flag
__DAQ_PLATFORM_QUIET=0

# Print verbose message to stderr
# Args: message
__daq_platform_verbose() {
    if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ]; then
        echo "[VERBOSE] $*" >&2
    fi
}

# Print debug message to stderr
# Args: message
# Output: "[DEBUG] <message>" to stderr if debug mode is enabled
__daq_platform_debug() {
    if [ "$__DAQ_PLATFORM_DEBUG" -eq 1 ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Print error message to stderr with optional details
# Args:
#   $1 - Error message
#   $@ - Optional additional details (shown only in verbose mode)
# Output: "Error: <message>" to stderr unless quiet mode is enabled
__daq_platform_error() {
    if [ "$__DAQ_PLATFORM_QUIET" -eq 0 ]; then
        echo "Error: $1" >&2
        shift
        if [ "$__DAQ_PLATFORM_VERBOSE" -eq 1 ] && [ $# -gt 0 ]; then
            echo "  Details: $*" >&2
        fi
    fi
}

# Detect current operating system name and version
# Output: "os_name os_version" to stdout ("ubuntu 20.04", "macos 14", "win" (no version))
# Exit code:
#   0 - Successfully detected
#   1 - Unable to detect OS
__daq_platform_detect_os_info() {
    local os_name=""
    local os_version=""
    
    # Detect OS type
    local uname_s
    uname_s=$(uname -s)
    
    __daq_platform_debug "uname -s: $uname_s"
    
    case "$uname_s" in
        Linux)
            # Linux: read /etc/os-release
            if [ -f /etc/os-release ]; then
                # Source the file to get ID and VERSION_ID
                . /etc/os-release
                os_name="$ID"
                os_version="$VERSION_ID"
                __daq_platform_debug "Detected Linux: ID=$ID VERSION_ID=$VERSION_ID"
            else
                __daq_platform_error "Cannot detect Linux distribution: /etc/os-release not found"
                return 1
            fi
            ;;
        Darwin)
            # macOS: use sw_vers
            os_name="macos"
            # Get version like 14.2.1, extract major version (14)
            local full_version
            full_version=$(sw_vers -productVersion 2>/dev/null)
            if [ -z "$full_version" ]; then
                __daq_platform_error "Cannot detect macOS version"
                return 1
            fi
            os_version=$(echo "$full_version" | cut -d. -f1)
            __daq_platform_debug "Detected macOS: version=$full_version (major=$os_version)"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash, MSYS2, Cygwin)
            os_name="win"
            os_version=""
            __daq_platform_debug "Detected Windows environment: $uname_s"
            ;;
        *)
            __daq_platform_error "Unsupported operating system: $uname_s"
            return 1
            ;;
    esac
    
    echo "$os_name" "$os_version"
}

# Detect and normalize current system architecture
# Output: "arm64" or "x86_64" for unix-like OSs, and "32" or "64" for Windows
# Exit code:
#   0 - Successfully detected
#   1 - Unable to detect architecture
__daq_platform_detect_arch() {
    local uname_m
    uname_m=$(uname -m)
    
    __daq_platform_debug "uname -m: $uname_m"
    
    # Check if we're on Windows first
    local uname_s
    uname_s=$(uname -s)
    local is_windows=0
    case "$uname_s" in
        MINGW*|MSYS*|CYGWIN*)
            is_windows=1
            ;;
    esac
    
    # Normalize architecture
    case "$uname_m" in
        x86_64|amd64)
            if [ $is_windows -eq 1 ]; then
                echo "64"
            else
                echo "x86_64"
            fi
            ;;
        aarch64|arm64)
            if [ $is_windows -eq 1 ]; then
                echo "64"
            else
                echo "arm64"
            fi
            ;;
        i686|i386|x86)
            if [ $is_windows -eq 1 ]; then
                echo "32"
            else
                __daq_platform_error "32-bit Linux/macOS is not supported"
                return 1
            fi
            ;;
        *)
            __daq_platform_error "Unsupported architecture: $uname_m"
            return 1
            ;;
    esac
}

# Generate list of all supported platform aliases
# Output: one platform alias per line to stdout in a supported format 
#     {os}{version}-{arch} (unix) or win{arch} (Windows)
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
# Args: platform alias to validate
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
# Args: platform alias (e.g., ubuntu20.04-arm64, win64)
# Output: ubuntu20.04-arm64 → "ubuntu 20.04 arm64" or win64 → "win 64""
# Exit code:
#   0 - Successfully parsed
#   1 - Invalid platform or parsing error
__daq_platform_parse() {
    local platform="$1"
    
    __daq_platform_debug "Parsing platform: $platform"
    
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_error "Invalid platform alias: $platform"
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
            return 1
            ;;
    esac
    
    # Output: name version arch (for Linux/macOS)
    echo "$os_name" "$os_version" "$os_arch"
}

# Validate a platform alias and optionally check its type
# Args:
#   $1 - Platform alias to validate (e.g., ubuntu20.04-arm64)
#   $2 - Optional type check flag:
#        --is-unix    Check if platform is Unix-based (Ubuntu/Debian/macOS)
#        --is-linux   Check if platform is Linux (Ubuntu/Debian)
#        --is-ubuntu  Check if platform is Ubuntu
#        --is-debian  Check if platform is Debian
#        --is-macos   Check if platform is macOS
#        --is-win     Check if platform is Windows
# Exit code:
#   0 - Platform is valid (or type check passed)
#   1 - Platform is invalid (or type check failed)
daq_platform_validate() {
    local platform="$1"
    shift
    
    __daq_platform_debug "Validating platform: $platform"
    
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_verbose "Platform validation failed: $platform"
        return 1
    fi
    
    # If no flags, just validate and exit
    if [ $# -eq 0 ]; then
        __daq_platform_verbose "Platform is valid: $platform"
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
    
    __daq_platform_debug "OS name detected: $os_name"
    
    # Check flags
    local flag="$1"
    local result=0
    case "$flag" in
        --is-unix)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ] || [ "$os_name" = "macos" ]
            result=$?
            __daq_platform_verbose "Check --is-unix for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        --is-linux)
            [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ]
            result=$?
            __daq_platform_verbose "Check --is-linux for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        --is-ubuntu)
            [ "$os_name" = "ubuntu" ]
            result=$?
            __daq_platform_verbose "Check --is-ubuntu for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        --is-debian)
            [ "$os_name" = "debian" ]
            result=$?
            __daq_platform_verbose "Check --is-debian for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        --is-macos)
            [ "$os_name" = "macos" ]
            result=$?
            __daq_platform_verbose "Check --is-macos for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        --is-win)
            [ "$os_name" = "win" ]
            result=$?
            __daq_platform_verbose "Check --is-win for $platform: $([ $result -eq 0 ] && echo 'true' || echo 'false')"
            return $result
            ;;
        *)
            __daq_platform_error "Unknown flag: $flag"
            return 1
            ;;
    esac
}

# Parse/extract platform components from a platform alias
# Args:
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
daq_platform_parse() {
    local platform="$1"
    shift
    
    __daq_platform_debug "Parse command invoked for: $platform"
    
    local parsed_output
    parsed_output=$(__daq_platform_parse "$platform")
    local parse_exit_code=$?
    
    # Check if parsing failed
    if [ $parse_exit_code -ne 0 ]; then
        return $parse_exit_code
    fi
    
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
        return 0
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
                return 1
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
# Args:
#   --os-name <name>      OS name (ubuntu, debian, macos, win) [REQUIRED]
#   --os-version <ver>    OS version (required for ubuntu/debian/macos, not used for win)
#   --os-arch <arch>      Architecture (arm64, x86_64 for Linux/macOS; 32, 64 for Windows) [REQUIRED]
# Output: composed platform alias to stdout
# Exit code:
#   0 - Successfully composed valid platform
#   1 - Missing required arguments or invalid composition
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
                    return 1
                fi
                os_name="$2"
                __daq_platform_debug "Set os-name: $os_name"
                shift 2
                ;;
            --os-version)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    __daq_platform_error "--os-version requires a value"
                    return 1
                fi
                os_version="$2"
                __daq_platform_debug "Set os-version: $os_version"
                shift 2
                ;;
            --os-arch)
                if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
                    __daq_platform_error "--os-arch requires a value"
                    return 1
                fi
                os_arch="$2"
                __daq_platform_debug "Set os-arch: $os_arch"
                shift 2
                ;;
            *)
                __daq_platform_error "Unknown argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate required fields
    if [ -z "$os_name" ]; then
        __daq_platform_error "--os-name is required"
        return 1
    fi
    
    if [ -z "$os_arch" ]; then
        __daq_platform_error "--os-arch is required"
        return 1
    fi
    
    # Compose platform alias
    local platform=""
    if [ "$os_name" = "win" ]; then
        platform="win${os_arch}"
        __daq_platform_verbose "Composing Windows platform: $platform"
    else
        if [ -z "$os_version" ]; then
            __daq_platform_error "--os-version is required for non-Windows platforms"
            return 1
        fi
        platform="${os_name}${os_version}-${os_arch}"
        __daq_platform_verbose "Composing Linux/macOS platform: $platform"
    fi
    
    # Validate composed platform
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_error "Invalid platform composition: $platform"
        return 1
    fi
    
    __daq_platform_verbose "Successfully composed platform: $platform"
    echo "$platform"
}

# List all supported platform aliases
# Output: all supported platform aliases, one per line, to stdout
daq_platform_list() {
    __daq_platform_verbose "Listing all supported platforms"
    __daq_platform_generate_platforms
}

# Detect current platform and return its alias
# In verbose mode, also prints detection details to stderr
# Output: detected platform alias to stdout (e.g., ubuntu20.04-arm64)
# Exit code:
#   0 - Successfully detected a supported platform
#   1 - Detection failed or platform is not supported
daq_platform_detect() {
    __daq_platform_debug "Detect command invoked"
    
    # Detect OS info
    local os_info
    if ! os_info=$(__daq_platform_detect_os_info); then
        return 1
    fi
    
    local os_name os_version
    read -r os_name os_version <<< "$os_info"
    
    __daq_platform_verbose "Detected OS: $os_name"
    if [ -n "$os_version" ]; then
        __daq_platform_verbose "Detected version: $os_version"
    fi
    
    # Detect architecture
    local os_arch
    if ! os_arch=$(__daq_platform_detect_arch); then
        return 1
    fi
    
    __daq_platform_verbose "Detected architecture: $os_arch"
    
    # Compose platform alias
    local platform=""
    if [ "$os_name" = "win" ]; then
        platform="win${os_arch}"
    else
        if [ -z "$os_version" ]; then
            __daq_platform_error "Could not detect OS version for $os_name"
            return 1
        fi
        platform="${os_name}${os_version}-${os_arch}"
    fi
    
    __daq_platform_verbose "Composed platform: $platform"
    
    # Validate that detected platform is supported
    if ! __daq_platform_is_valid "$platform"; then
        __daq_platform_error "Detected platform $platform is not supported" \
            "Supported platforms can be listed with: --list-platforms"
        return 1
    fi
    
    __daq_platform_verbose "Platform is supported: $platform"
    echo "$platform"
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
    set -- "${remaining_args[@]+"${remaining_args[@]}"}"
    
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
            echo "  detect              Detect current platform"
            echo "  validate <platform> [--is-unix|--is-linux|--is-ubuntu|--is-debian|--is-macos|--is-win]"
            echo "  parse <platform> [--os-name] [--os-version] [--os-arch]"
            echo "  extract <platform> [--os-name] [--os-version] [--os-arch]"
            echo "  compose --os-name <n> [--os-version <version>] --os-arch <arch>"
            echo ""
            echo "Options:"
            echo "  --list-platforms    List all supported platforms"
        fi
        return 1
    fi

    __daq_platform_debug "Processing command: $1"

    case "$1" in
        --list-platforms)
            __daq_platform_verbose "Listing all supported platforms"
            daq_platform_list
            return $?
            ;;
        detect)
            shift
            daq_platform_detect "$@"
            return $?
            ;;
        validate)
            shift
            daq_platform_validate "$@"
            return $?
            ;;
        parse)
            shift
            daq_platform_parse "$@"
            return $?
            ;;
        extract)
            shift
            daq_platform_extract "$@"
            return $?
            ;;
        compose)
            shift
            daq_platform_compose "$@"
            return $?
            ;;
        *)
            __daq_platform_error "Unknown command: $1"
            return 1
            ;;
    esac
}

# Flag to track if script was sourced
__DAQ_PLATFORM_SOURCED=0

if [ -n "${BASH_VERSION:-}" ]; then
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    __DAQ_PLATFORM_SCRIPT_PATH="${(%):-%N}"
    if [ "$__DAQ_PLATFORM_SCRIPT_PATH" != "${0}" ]; then
        __DAQ_PLATFORM_SOURCED=1
    fi
fi

# Run main only if not sourced
if [ "$__DAQ_PLATFORM_SOURCED" -eq 0 ]; then
    __daq_platform_main "$@"
    exit $?
fi
