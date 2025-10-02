#!/bin/bash
################################################################################
# Module: platform-format (core layer)
# Version: 1.0.0
# Description: Platform string manipulation tool for openDAQ
#
# Usage:
#   CLI:     platform-format <COMMAND> [OPTIONS]
#   Library: source platform-format.sh && daq_platform_*
#
# Dependencies:
#   - lib/logger.sh (logging functionality)
#
# Exit codes:
#   0 - Success
#   1 - Validation failure or general error
#   2 - Invalid arguments or usage error
################################################################################

set -euo pipefail

################################################################################
# DEPENDENCY LOADING
################################################################################

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging flags (can be overridden by environment or logger integration)
__DAQ_PLATFORM_VERBOSE=${OPENDAQ_VERBOSE:-false}
__DAQ_PLATFORM_DEBUG=${OPENDAQ_DEBUG:-false}

################################################################################
# INTERNAL LOGGING FUNCTIONS
################################################################################

# These are stubs that can be overridden by sourcing lib/logger.sh
# By default, they output to stdout/stderr

__daq_platform_log_verbose() {
    if [ "$__DAQ_PLATFORM_VERBOSE" = "true" ]; then
        echo "[VERBOSE] platform-format: $*" >&2
    fi
}

__daq_platform_log_debug() {
    if [ "$__DAQ_PLATFORM_DEBUG" = "true" ]; then
        echo "[DEBUG] platform-format: $*" >&2
    fi
}

__daq_platform_log_info() {
    echo "[INFO] platform-format: $*" >&2
}

__daq_platform_log_warning() {
    echo "[WARNING] platform-format: $*" >&2
}

__daq_platform_log_error() {
    echo "[ERROR] platform-format: $*" >&2
}

# Optional: Try to integrate with logger.sh if available
if [ -f "$SCRIPT_DIR/../lib/logger.sh" ]; then
    source "$SCRIPT_DIR/../lib/logger.sh" 2>/dev/null || true
    
    # If logger is available, create wrapper functions
    if command -v daq_logger_verbose >/dev/null 2>&1; then
        daq_logger_set_context "platform-format"
        
        __daq_platform_log_verbose() {
            daq_logger_verbose "$@"
        }
        
        __daq_platform_log_debug() {
            daq_logger_debug "$@"
        }
        
        __daq_platform_log_info() {
            daq_logger_info "$@"
        }
        
        __daq_platform_log_warning() {
            daq_logger_warning "$@"
        }
        
        __daq_platform_log_error() {
            daq_logger_error "$@"
        }
    fi
fi

################################################################################
# SCRIPT METADATA
################################################################################

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="platform-format"
readonly SCRIPT_BUILD_DATE="2025-01-15"

################################################################################
# CONSTANTS - Supported Platforms
################################################################################

# OS families
readonly __DAQ_PLATFORM_OS_UBUNTU="ubuntu"
readonly __DAQ_PLATFORM_OS_MACOS="macos"
readonly __DAQ_PLATFORM_OS_WINDOWS="win"

# All supported OS families
readonly __DAQ_PLATFORM_ALL_OS="$__DAQ_PLATFORM_OS_UBUNTU $__DAQ_PLATFORM_OS_MACOS $__DAQ_PLATFORM_OS_WINDOWS"

# Ubuntu versions
readonly __DAQ_PLATFORM_UBUNTU_VERSIONS="20.04 22.04 24.04"
readonly __DAQ_PLATFORM_UBUNTU_SHORT_VERSIONS="20 22 24"

# macOS versions
readonly __DAQ_PLATFORM_MACOS_VERSIONS="13 14 15 16 17 18 26"

# Windows versions
readonly __DAQ_PLATFORM_WINDOWS_VERSIONS="32 64"

# Architectures
readonly __DAQ_PLATFORM_ARCH_ARM64="arm64"
readonly __DAQ_PLATFORM_ARCH_X86_64="x86_64"
readonly __DAQ_PLATFORM_ARCH_X86="x86"  # For win32

# All supported architectures
readonly __DAQ_PLATFORM_ALL_ARCH="$__DAQ_PLATFORM_ARCH_ARM64 $__DAQ_PLATFORM_ARCH_X86_64 $__DAQ_PLATFORM_ARCH_X86"

################################################################################
# CONSTANTS - Format Templates
################################################################################

readonly __DAQ_PLATFORM_FORMAT_UBUNTU="ubuntu<VERSION>-<ARCH>"
readonly __DAQ_PLATFORM_FORMAT_MACOS="macos<VERSION>-<ARCH>"
readonly __DAQ_PLATFORM_FORMAT_WINDOWS="win<VERSION>"

readonly __DAQ_PLATFORM_ALL_FORMATS="$__DAQ_PLATFORM_FORMAT_UBUNTU $__DAQ_PLATFORM_FORMAT_MACOS $__DAQ_PLATFORM_FORMAT_WINDOWS"

################################################################################
# CONSTANTS - Validation Regex
################################################################################

# Main platform string regex patterns
readonly __DAQ_PLATFORM_REGEX_UBUNTU="^ubuntu(20|22|24)(\.04)?-(arm64|x86_64)$"
readonly __DAQ_PLATFORM_REGEX_MACOS="^macos(13|14|15|16|17|18|26)-(arm64|x86_64)$"
readonly __DAQ_PLATFORM_REGEX_WINDOWS="^win(32|64)$"

# Generic pattern for any platform
readonly __DAQ_PLATFORM_REGEX_ANY="(ubuntu(20|22|24)(\.04)?-(arm64|x86_64)|macos(13|14|15|16|17|18|26)-(arm64|x86_64)|win(32|64))"

################################################################################
# HELP SYSTEM - Short Help
################################################################################

__daq_platform_help_short() {
    cat << 'EOF'
platform-format - Platform string manipulation tool for openDAQ

USAGE:
  platform-format <COMMAND> [OPTIONS]
  platform-format <PLATFORM> --detect-os|--detect-arch
  platform-format --help|-h|--version|-v

COMMANDS:
  validate <PLATFORM>       Validate platform string
  parse <PLATFORM>          Parse platform into components
  compose                   Compose platform from components
  extract <TEXT>            Extract platform from text
  normalize <PLATFORM>      Normalize platform string

QUERIES:
  --list-platforms          List all supported platforms
  --list-os                 List all supported OS families
  --list-arch               List all supported architectures
  --list-ubuntu-versions    List supported Ubuntu versions
  --list-macos-versions     List supported macOS versions
  --list-windows-versions   List supported Windows versions

DETECTION:
  <PLATFORM> --detect-os    Detect OS family
  <PLATFORM> --detect-arch  Detect architecture
  <PLATFORM> --detect-type  Detect platform type

GLOBAL OPTIONS:
  --help, -h                Show detailed help
  --version, -v             Show script version
  --verbose                 Enable verbose output
  --debug, -d               Enable debug output

EXAMPLES:
  platform-format validate ubuntu22.04-arm64
  platform-format parse macos14-x86_64 --os --version
  platform-format compose --os ubuntu --version 22.04 --arch arm64
  platform-format ubuntu22.04-arm64 --detect-os

For detailed help on a command:
  platform-format <COMMAND> --help

EOF
}

################################################################################
# HELP SYSTEM - Full Help
################################################################################

__daq_platform_help() {
    cat << 'EOF'
platform-format - Platform string manipulation tool for openDAQ

DESCRIPTION:
  A comprehensive tool for parsing, validating, composing, and extracting
  platform strings. Supports Ubuntu, macOS, and Windows platforms with
  various versions and architectures.

USAGE:
  platform-format <COMMAND> [OPTIONS]
  platform-format <PLATFORM> --detect-os|--detect-arch
  platform-format --help|-h|--version|-v

════════════════════════════════════════════════════════════════════════════
COMMANDS
════════════════════════════════════════════════════════════════════════════

validate <PLATFORM> [OPTIONS]
  Validate platform string against format rules

  OPTIONS:
    --format <TEMPLATE>     Validate against specific format template
    --os <OS>               Validate OS family
    --arch <ARCH>           Validate architecture
    --is-ubuntu             Check if platform is Ubuntu
    --is-macos              Check if platform is macOS
    --is-windows            Check if platform is Windows
    --is-arm64              Check if architecture is ARM64
    --is-x86_64             Check if architecture is x86_64
    --has-arch              Check if platform specifies architecture

  EXAMPLES:
    platform-format validate ubuntu22.04-arm64
    platform-format validate macos14-x86_64 --is-macos
    platform-format validate win64 --is-windows

parse <PLATFORM> [OPTIONS]
  Parse platform string into components

  OPTIONS:
    --os                    Extract OS family
    --version               Extract version
    --arch                  Extract architecture
    --type                  Extract platform type

  OUTPUT RULES:
    No flags:       All components in KEY=VALUE format
    One flag:       Value only (no KEY=)
    Multiple flags: KEY=VALUE for each requested component

  EXAMPLES:
    platform-format parse ubuntu22.04-arm64
    platform-format parse macos14-x86_64 --os
    platform-format parse win64 --os --arch

compose [OPTIONS]
  Compose platform string from components

  OPTIONS:
    --os <OS>               OS family (ubuntu|macos|win) (required)
    --version <VERSION>     Version number (required)
    --arch <ARCH>           Architecture (required for Ubuntu/macOS)
    --format <TEMPLATE>     Use specific format template
    --from-env              Read from OPENDAQ_PLATFORM_COMPOSED_* variables

  EXAMPLES:
    platform-format compose --os ubuntu --version 22.04 --arch arm64
    platform-format compose --os macos --version 14 --arch x86_64
    platform-format compose --os win --version 64

normalize <PLATFORM> [OPTIONS]
  Normalize platform string to canonical format

  OPTIONS:
    --short                 Use short format where applicable
    --long                  Use long format where applicable

  EXAMPLES:
    platform-format normalize ubuntu22-arm64
    # Output: ubuntu22.04-arm64
    
    platform-format normalize ubuntu22.04-arm64 --short
    # Output: ubuntu22-arm64

extract <TEXT> [OPTIONS]
  Extract platform string from text

  OPTIONS:
    --all                   Extract all platforms (default: first only)
    --verbose               Show detailed extraction info

  EXAMPLES:
    platform-format extract "Built for ubuntu22.04-arm64"
    echo "macos14-x86_64.tar.gz" | platform-format extract -

════════════════════════════════════════════════════════════════════════════
QUERY COMMANDS
════════════════════════════════════════════════════════════════════════════

--list-platforms [OPTIONS]
  List all supported platform combinations

  OPTIONS:
    --os <OS>               Filter by OS family
    --arch <ARCH>           Filter by architecture
    --verbose               Show detailed platform information

--list-os [OPTIONS]
  List all supported OS families

  OPTIONS:
    --verbose               Show detailed OS information

--list-arch [OPTIONS]
  List all supported architectures

  OPTIONS:
    --os <OS>               Filter architectures by OS
    --verbose               Show detailed architecture information

--list-ubuntu-versions
  List supported Ubuntu versions

--list-macos-versions
  List supported macOS versions

--list-windows-versions
  List supported Windows versions

════════════════════════════════════════════════════════════════════════════
DETECTION COMMANDS
════════════════════════════════════════════════════════════════════════════

<PLATFORM> --detect-os
  Detect and return OS family

  EXAMPLE:
    platform-format ubuntu22.04-arm64 --detect-os
    # Output: ubuntu

<PLATFORM> --detect-arch
  Detect and return architecture

  EXAMPLE:
    platform-format ubuntu22.04-arm64 --detect-arch
    # Output: arm64

<PLATFORM> --detect-type
  Detect and return platform type

  TYPES:
    ubuntu-arm64    Ubuntu on ARM64
    ubuntu-x86_64   Ubuntu on x86_64
    macos-arm64     macOS on ARM64 (Apple Silicon)
    macos-x86_64    macOS on x86_64 (Intel)
    win32           Windows 32-bit
    win64           Windows 64-bit

  EXAMPLE:
    platform-format ubuntu22.04-arm64 --detect-type
    # Output: ubuntu-arm64

════════════════════════════════════════════════════════════════════════════
SUPPORTED PLATFORMS
════════════════════════════════════════════════════════════════════════════

UBUNTU:
  ubuntu20.04-arm64         Ubuntu 20.04 LTS on ARM64
  ubuntu20.04-x86_64        Ubuntu 20.04 LTS on x86_64
  ubuntu22.04-arm64         Ubuntu 22.04 LTS on ARM64
  ubuntu22.04-x86_64        Ubuntu 22.04 LTS on x86_64
  ubuntu24.04-arm64         Ubuntu 24.04 LTS on ARM64
  ubuntu24.04-x86_64        Ubuntu 24.04 LTS on x86_64

  Short forms (also accepted):
  ubuntu20-arm64, ubuntu22-arm64, ubuntu24-arm64
  ubuntu20-x86_64, ubuntu22-x86_64, ubuntu24-x86_64

MACOS:
  macos13-arm64             macOS 13 (Ventura) on ARM64
  macos13-x86_64            macOS 13 (Ventura) on x86_64
  macos14-arm64             macOS 14 (Sonoma) on ARM64
  macos14-x86_64            macOS 14 (Sonoma) on x86_64
  macos15-arm64             macOS 15 on ARM64
  macos15-x86_64            macOS 15 on x86_64
  macos16-arm64             macOS 16 on ARM64
  macos16-x86_64            macOS 16 on x86_64
  macos17-arm64             macOS 17 on ARM64
  macos17-x86_64            macOS 17 on x86_64
  macos18-arm64             macOS 18 on ARM64
  macos18-x86_64            macOS 18 on x86_64
  macos26-arm64             macOS 26 on ARM64
  macos26-x86_64            macOS 26 on x86_64

WINDOWS:
  win32                     Windows 32-bit
  win64                     Windows 64-bit

════════════════════════════════════════════════════════════════════════════
ENVIRONMENT VARIABLES
════════════════════════════════════════════════════════════════════════════

PARSED (set by parse command, read-only):
  OPENDAQ_PLATFORM_PARSED_OS
  OPENDAQ_PLATFORM_PARSED_VERSION
  OPENDAQ_PLATFORM_PARSED_ARCH
  OPENDAQ_PLATFORM_PARSED_TYPE

COMPOSED (set by user, read by compose --from-env):
  OPENDAQ_PLATFORM_COMPOSED_OS        (required)
  OPENDAQ_PLATFORM_COMPOSED_VERSION   (required)
  OPENDAQ_PLATFORM_COMPOSED_ARCH      (optional, required for Ubuntu/macOS)
  OPENDAQ_PLATFORM_COMPOSED_FORMAT    (optional)

CURRENT (detected system platform):
  OPENDAQ_PLATFORM_CURRENT            (auto-detected current platform)
  OPENDAQ_PLATFORM_CURRENT_OS         (auto-detected current OS)
  OPENDAQ_PLATFORM_CURRENT_VERSION    (auto-detected current version)
  OPENDAQ_PLATFORM_CURRENT_ARCH       (auto-detected current architecture)

════════════════════════════════════════════════════════════════════════════
VALIDATION RULES
════════════════════════════════════════════════════════════════════════════

OS Family:
  Valid:   ubuntu, macos, win
  Invalid: linux, osx, windows, mac

Ubuntu Versions:
  Valid:   20.04, 22.04, 24.04 (or short: 20, 22, 24)
  Invalid: 18.04, 21.04, 23.10

macOS Versions:
  Valid:   13, 14, 15, 16, 17, 18, 26
  Invalid: 10, 11, 12, 19-25

Windows Versions:
  Valid:   32, 64
  Invalid: 86, x86, x64, 10, 11

Architectures:
  Ubuntu:  arm64, x86_64
  macOS:   arm64, x86_64
  Windows: N/A (version implies architecture)

════════════════════════════════════════════════════════════════════════════
EXAMPLES
════════════════════════════════════════════════════════════════════════════

# Parse and extract components
platform-format parse ubuntu22.04-arm64
platform-format parse macos14-x86_64 --os --arch
platform-format parse win64 --arch

# Validate platforms
platform-format validate ubuntu22.04-arm64
platform-format validate macos14-x86_64 --is-macos
platform-format validate win64 --is-windows

# Compose platforms
platform-format compose --os ubuntu --version 22.04 --arch arm64
platform-format compose --os macos --version 14 --arch x86_64
platform-format compose --os win --version 64

# Normalize platforms
platform-format normalize ubuntu22-arm64
platform-format normalize ubuntu22.04-arm64 --short

# Detect components
platform-format ubuntu22.04-arm64 --detect-os
platform-format macos14-x86_64 --detect-arch
platform-format win64 --detect-type

# List available platforms
platform-format --list-platforms
platform-format --list-platforms --os ubuntu
platform-format --list-arch --os macos

# Extract from text
platform-format extract "Package: opendaq-ubuntu22.04-arm64.deb"
echo "macos14-x86_64 and win64 builds" | platform-format extract - --all

VERSION: $SCRIPT_VERSION
BUILD:   $SCRIPT_BUILD_DATE

EOF
}

################################################################################
# HELP SYSTEM - Command-specific Help
################################################################################

__daq_platform_help_validate() {
    cat << 'EOF'
platform-format validate - Validate platform string

USAGE:
  platform-format validate <PLATFORM> [OPTIONS]

DESCRIPTION:
  Validates a platform string against format templates or specific rules.
  Returns exit code 0 if valid, 1 if invalid.

OPTIONS:
  --format <TEMPLATE>     Validate against specific format template
  --os <OS>               Validate OS family
  --arch <ARCH>           Validate architecture
  --is-ubuntu             Check if platform is Ubuntu
  --is-macos              Check if platform is macOS
  --is-windows            Check if platform is Windows
  --is-arm64              Check if architecture is ARM64
  --is-x86_64             Check if architecture is x86_64
  --has-arch              Check if platform specifies architecture
  --verbose               Show detailed validation information

EXAMPLES:
  # Basic validation
  platform-format validate ubuntu22.04-arm64

  # OS checks
  platform-format validate ubuntu22.04-arm64 --is-ubuntu
  platform-format validate macos14-x86_64 --is-macos

  # Architecture checks
  platform-format validate ubuntu22.04-arm64 --is-arm64
  platform-format validate macos14-x86_64 --is-x86_64

EXIT CODES:
  0 - Platform is valid
  1 - Platform is invalid
  2 - Invalid arguments

EOF
}

__daq_platform_help_parse() {
    cat << 'EOF'
platform-format parse - Parse platform string

USAGE:
  platform-format parse <PLATFORM> [OPTIONS]

DESCRIPTION:
  Parses a platform string and extracts its components. Can output all
  components or specific requested components.

OPTIONS:
  --os                    Extract OS family
  --version               Extract version
  --arch                  Extract architecture
  --type                  Extract platform type
  --verbose               Show detailed parsing information

OUTPUT RULES:
  No flags:       All components in KEY=VALUE format
  One flag:       Value only (no KEY=)
  Multiple flags: KEY=VALUE for each requested component

EXAMPLES:
  # Parse all components
  platform-format parse ubuntu22.04-arm64
  # Output:
  # OPENDAQ_PLATFORM_PARSED_OS=ubuntu
  # OPENDAQ_PLATFORM_PARSED_VERSION=22.04
  # OPENDAQ_PLATFORM_PARSED_ARCH=arm64
  # OPENDAQ_PLATFORM_PARSED_TYPE=ubuntu-arm64

  # Extract single component (value only)
  platform-format parse macos14-x86_64 --os
  # Output: macos

  # Extract multiple components (KEY=VALUE)
  platform-format parse win64 --os --arch
  # Output:
  # OPENDAQ_PLATFORM_PARSED_OS=win
  # OPENDAQ_PLATFORM_PARSED_ARCH=x86_64

EXIT CODES:
  0 - Success
  1 - Parse failed
  2 - Invalid arguments

EOF
}

__daq_platform_help_compose() {
    cat << 'EOF'
platform-format compose - Compose platform string

USAGE:
  platform-format compose [OPTIONS]

DESCRIPTION:
  Composes a platform string from individual components. Architecture
  is required for Ubuntu and macOS, but not for Windows.

OPTIONS:
  --os <OS>               OS family (ubuntu|macos|win) (required)
  --version <VERSION>     Version number (required)
  --arch <ARCH>           Architecture (required for Ubuntu/macOS)
  --format <TEMPLATE>     Use specific format template
  --from-env              Read from OPENDAQ_PLATFORM_COMPOSED_* variables
  --verbose               Show detailed composition information

EXAMPLES:
  # Ubuntu platform
  platform-format compose --os ubuntu --version 22.04 --arch arm64
  # Output: ubuntu22.04-arm64

  # macOS platform
  platform-format compose --os macos --version 14 --arch x86_64
  # Output: macos14-x86_64

  # Windows platform
  platform-format compose --os win --version 64
  # Output: win64

  # From environment variables
  export OPENDAQ_PLATFORM_COMPOSED_OS=ubuntu
  export OPENDAQ_PLATFORM_COMPOSED_VERSION=22.04
  export OPENDAQ_PLATFORM_COMPOSED_ARCH=arm64
  platform-format compose --from-env
  # Output: ubuntu22.04-arm64

EXIT CODES:
  0 - Success
  1 - Composition failed
  2 - Invalid arguments

EOF
}

__daq_platform_help_normalize() {
    cat << 'EOF'
platform-format normalize - Normalize platform string

USAGE:
  platform-format normalize <PLATFORM> [OPTIONS]

DESCRIPTION:
  Normalizes a platform string to its canonical format. Can convert
  between short and long forms for Ubuntu versions.

OPTIONS:
  --short                 Use short format where applicable
  --long                  Use long format where applicable (default)
  --verbose               Show detailed normalization information

EXAMPLES:
  # Normalize short Ubuntu version to long
  platform-format normalize ubuntu22-arm64
  # Output: ubuntu22.04-arm64

  # Normalize to short format
  platform-format normalize ubuntu22.04-arm64 --short
  # Output: ubuntu22-arm64

  # Already normalized
  platform-format normalize macos14-x86_64
  # Output: macos14-x86_64

EXIT CODES:
  0 - Success
  1 - Normalization failed
  2 - Invalid arguments

EOF
}

__daq_platform_help_extract() {
    cat << 'EOF'
platform-format extract - Extract platform from text

USAGE:
  platform-format extract <TEXT> [OPTIONS]
  platform-format extract - [OPTIONS]    (read from stdin)

DESCRIPTION:
  Extracts platform strings from text. Can extract the first platform
  or all platforms found in the text.

OPTIONS:
  --all                   Extract all platforms (default: first only)
  --verbose               Show detailed extraction information

EXAMPLES:
  # Extract from string
  platform-format extract "Built for ubuntu22.04-arm64"
  # Output: ubuntu22.04-arm64

  # Extract all platforms
  platform-format extract "Supports macos14-arm64 and win64" --all
  # Output:
  # macos14-arm64
  # win64

  # Extract from stdin
  echo "opendaq-ubuntu22.04-x86_64.tar.gz" | platform-format extract -
  # Output: ubuntu22.04-x86_64

EXIT CODES:
  0 - Platform(s) found and extracted
  1 - No platforms found
  2 - Invalid arguments

EOF
}

################################################################################
# HELP SYSTEM - Error Functions
################################################################################

__daq_platform_error_usage() {
    local message="$1"
    
    echo "ERROR: $message" >&2
    echo "" >&2
    echo "Try 'platform-format --help' for more information." >&2
    
    return 2
}

__daq_platform_error_missing_env() {
    local missing_vars="$1"
    
    cat >&2 << EOF
ERROR: Missing required environment variables for compose --from-env

Required variables:
  OPENDAQ_PLATFORM_COMPOSED_OS
  OPENDAQ_PLATFORM_COMPOSED_VERSION

Missing: $missing_vars

Optional variables:
  OPENDAQ_PLATFORM_COMPOSED_ARCH      (required for Ubuntu/macOS)
  OPENDAQ_PLATFORM_COMPOSED_FORMAT    (default: auto-detect)

EOF
    
    return 1
}

################################################################################
# PRIVATE FUNCTIONS - Component Validation
################################################################################

# Check if OS is valid
# Args: $1 - OS string
# Returns: 0 if valid, 1 if invalid
__daq_platform_is_valid_os() {
    local os="$1"
    
    case "$os" in
        ubuntu|macos|win)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if Ubuntu version is valid
# Args: $1 - version string
# Returns: 0 if valid, 1 if invalid
__daq_platform_is_valid_ubuntu_version() {
    local version="$1"
    
    case "$version" in
        20|20.04|22|22.04|24|24.04)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if macOS version is valid
# Args: $1 - version string
# Returns: 0 if valid, 1 if invalid
__daq_platform_is_valid_macos_version() {
    local version="$1"
    
    case "$version" in
        13|14|15|16|17|18|26)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if Windows version is valid
# Args: $1 - version string
# Returns: 0 if valid, 1 if invalid
__daq_platform_is_valid_windows_version() {
    local version="$1"
    
    case "$version" in
        32|64)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if architecture is valid for OS
# Args: $1 - OS
#       $2 - architecture
# Returns: 0 if valid, 1 if invalid
__daq_platform_is_valid_arch_for_os() {
    local os="$1"
    local arch="$2"
    
    case "$os" in
        ubuntu|macos)
            case "$arch" in
                arm64|x86_64)
                    return 0
                    ;;
                *)
                    return 1
                    ;;
            esac
            ;;
        win)
            # Windows doesn't use separate arch field
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - Normalization
################################################################################

# Normalize Ubuntu version
# Args: $1 - version string
#       $2 - format (short|long)
# Returns: normalized version
__daq_platform_normalize_ubuntu_version() {
    local version="$1"
    local format="${2:-long}"
    
    case "$version" in
        20|20.04)
            if [ "$format" = "short" ]; then
                echo "20"
            else
                echo "20.04"
            fi
            ;;
        22|22.04)
            if [ "$format" = "short" ]; then
                echo "22"
            else
                echo "22.04"
            fi
            ;;
        24|24.04)
            if [ "$format" = "short" ]; then
                echo "24"
            else
                echo "24.04"
            fi
            ;;
        *)
            echo "$version"
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - Platform Parsing
################################################################################

# Parse platform string into components
# Args: $1 - platform string
# Sets global variables: __PARSED_OS, __PARSED_VERSION, __PARSED_ARCH
# Returns: 0 on success, 1 on failure
__daq_platform_parse_components() {
    local platform="$1"
    
    __daq_platform_log_debug "Parsing platform: $platform"
    
    # Initialize variables
    __PARSED_OS=""
    __PARSED_VERSION=""
    __PARSED_ARCH=""
    
    # Try Ubuntu pattern
    if echo "$platform" | grep -Eq "$__DAQ_PLATFORM_REGEX_UBUNTU"; then
        __PARSED_OS="ubuntu"
        
        # Extract version
        __PARSED_VERSION=$(echo "$platform" | sed -E 's/^ubuntu([0-9]+)-.*/\1/')
        
        # Extract architecture
        if echo "$platform" | grep -q "arm64"; then
            __PARSED_ARCH="arm64"
        elif echo "$platform" | grep -q "x86_64"; then
            __PARSED_ARCH="x86_64"
        fi
        
        __daq_platform_log_debug "Parsed macOS: os=$__PARSED_OS, version=$__PARSED_VERSION, arch=$__PARSED_ARCH"
        return 0
    fi
    
    # Try Windows pattern
    if echo "$platform" | grep -Eq "$__DAQ_PLATFORM_REGEX_WINDOWS"; then
        __PARSED_OS="win"
        
        # Extract version
        __PARSED_VERSION=$(echo "$platform" | sed -E 's/^win([0-9]+)$/\1/')
        
        # Windows architecture is implied by version
        if [ "$__PARSED_VERSION" = "32" ]; then
            __PARSED_ARCH="x86"
        elif [ "$__PARSED_VERSION" = "64" ]; then
            __PARSED_ARCH="x86_64"
        fi
        
        __daq_platform_log_debug "Parsed Windows: os=$__PARSED_OS, version=$__PARSED_VERSION, arch=$__PARSED_ARCH"
        return 0
    fi

    if echo "$platform" | grep -Eq "$__DAQ_PLATFORM_REGEX_MACOS"; then
        __PARSED_OS="macos"
        __PARSED_VERSION=$(echo "$platform" | sed -E 's/^macos([0-9]+)-.*/\1/')
        # Extract architecture
        if echo "$platform" | grep -q "arm64"; then
            __PARSED_ARCH="arm64"
        elif echo "$platform" | grep -q "x86_64"; then
            __PARSED_ARCH="x86_64"
        fi

        __daq_platform_log_debug "Parsed MacOS: os=$__PARSED_OS, version=$__PARSED_VERSION, arch=$__PARSED_ARCH"
        return 0
    fi
    
    __daq_platform_log_error "Platform string does not match expected format: $platform"
    return 1
}

# Extract platform string from text
# Args: $1 - text to search
#       $2 - extract all flag (optional, "all" to extract all)
# Returns: found platform string(s) or empty
__daq_platform_extract_from_text() {
    local text="$1"
    local extract_all="${2:-}"
    
    __daq_platform_log_debug "Extracting platform from text: ${text:0:100}..."
    
    # Try to find platform patterns in text
    local platforms
    
    if [ "$extract_all" = "all" ]; then
        # Extract all platforms
        platforms=$(echo "$text" | grep -oE "(ubuntu(20|22|24)(\.04)?-(arm64|x86_64)|macos(13|14|15|16|17|18|26)-(arm64|x86_64)|win(32|64))")
    else
        # Extract first platform only
        platforms=$(echo "$text" | grep -oE "(ubuntu(20|22|24)(\.04)?-(arm64|x86_64)|macos(13|14|15|16|17|18|26)-(arm64|x86_64)|win(32|64))" | head -n 1)
    fi
    
    if [ -n "$platforms" ]; then
        __daq_platform_log_debug "Extracted platform(s): $platforms"
        echo "$platforms"
        return 0
    else
        __daq_platform_log_debug "No platform found in text"
        return 1
    fi
}

################################################################################
# PRIVATE FUNCTIONS - Type Detection
################################################################################

# Detect platform type from parsed components
# Args: $1 - OS
#       $2 - version
#       $3 - arch
# Returns: platform type string
__daq_platform_detect_type() {
    local os="$1"
    local version="$2"
    local arch="$3"
    
    __daq_platform_log_debug "Type detection: os='$os', version='$version', arch='$arch'"
    
    case "$os" in
        ubuntu)
            echo "ubuntu-$arch"
            ;;
        macos)
            echo "macos-$arch"
            ;;
        win)
            if [ "$version" = "32" ]; then
                echo "win32"
            else
                echo "win64"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - Platform Composition
################################################################################

# Compose platform string from components
# Args: $1 - OS
#       $2 - version
#       $3 - architecture (optional for Windows)
# Returns: composed platform string
__daq_platform_compose_string() {
    local os="$1"
    local version="$2"
    local arch="${3:-}"
    
    __daq_platform_log_debug "Composing platform: os=$os, version=$version, arch=$arch"
    
    # Validate OS
    if ! __daq_platform_is_valid_os "$os"; then
        __daq_platform_log_error "Invalid OS: $os"
        return 1
    fi
    
    case "$os" in
        ubuntu)
            # Validate version
            if ! __daq_platform_is_valid_ubuntu_version "$version"; then
                __daq_platform_log_error "Invalid Ubuntu version: $version"
                return 1
            fi
            
            # Architecture required
            if [ -z "$arch" ]; then
                __daq_platform_log_error "Architecture required for Ubuntu platform"
                return 1
            fi
            
            if ! __daq_platform_is_valid_arch_for_os "$os" "$arch"; then
                __daq_platform_log_error "Invalid architecture for Ubuntu: $arch"
                return 1
            fi
            
            # Normalize version to include .04
            local normalized_version
            normalized_version=$(__daq_platform_normalize_ubuntu_version "$version" "long")
            
            echo "ubuntu${normalized_version}-${arch}"
            ;;
            
        macos)
            # Validate version
            if ! __daq_platform_is_valid_macos_version "$version"; then
                __daq_platform_log_error "Invalid macOS version: $version"
                return 1
            fi
            
            # Architecture required
            if [ -z "$arch" ]; then
                __daq_platform_log_error "Architecture required for macOS platform"
                return 1
            fi
            
            if ! __daq_platform_is_valid_arch_for_os "$os" "$arch"; then
                __daq_platform_log_error "Invalid architecture for macOS: $arch"
                return 1
            fi
            
            echo "macos${version}-${arch}"
            ;;
            
        win)
            # Validate version
            if ! __daq_platform_is_valid_windows_version "$version"; then
                __daq_platform_log_error "Invalid Windows version: $version"
                return 1
            fi
            
            echo "win${version}"
            ;;
            
        *)
            __daq_platform_log_error "Unknown OS: $os"
            return 1
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - System Detection
################################################################################

# Detect current system platform
# Returns: detected platform string
__daq_platform_detect_current() {
    local os=""
    local version=""
    local arch=""
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        # Linux system
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            os="ubuntu"
            # Extract major.minor version
            version=$(echo "$VERSION_ID" | cut -d. -f1,2)
        fi
    elif [ "$(uname)" = "Darwin" ]; then
        # macOS system
        os="macos"
        # Get macOS version
        version=$(sw_vers -productVersion | cut -d. -f1)
    elif [ "$OS" = "Windows_NT" ]; then
        # Windows system
        os="win"
        # Detect 32 or 64 bit
        if [ "$PROCESSOR_ARCHITECTURE" = "AMD64" ] || [ "$PROCESSOR_ARCHITEW6432" = "AMD64" ]; then
            version="64"
        else
            version="32"
        fi
    fi
    
    # Detect architecture
    local machine
    machine=$(uname -m)
    case "$machine" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        i686|i386)
            arch="x86"
            ;;
    esac
    
    # Compose platform string
    if [ -n "$os" ] && [ -n "$version" ]; then
        if [ "$os" = "win" ]; then
            echo "win${version}"
        elif [ -n "$arch" ]; then
            if [ "$os" = "ubuntu" ]; then
                echo "ubuntu${version}-${arch}"
            elif [ "$os" = "macos" ]; then
                echo "macos${version}-${arch}"
            fi
        fi
    fi
}

################################################################################
# PUBLIC API - Platform Queries
################################################################################

# List all supported platforms
# Args: $1 - verbose flag (optional)
#       $2 - OS filter (optional)
#       $3 - arch filter (optional)
daq_platform_list() {
    local verbose=false
    local os_filter=""
    local arch_filter=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            verbose|--verbose)
                verbose=true
                shift
                ;;
            --os)
                os_filter="$2"
                shift 2
                ;;
            --arch)
                arch_filter="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    __daq_platform_log_debug "Listing platforms: verbose=$verbose, os_filter='$os_filter', arch_filter='$arch_filter'"
    
    # Ubuntu platforms
    if [ -z "$os_filter" ] || [ "$os_filter" = "ubuntu" ]; then
        for version in $__DAQ_PLATFORM_UBUNTU_VERSIONS; do
            for arch in arm64 x86_64; do
                if [ -n "$arch_filter" ] && [ "$arch_filter" != "$arch" ]; then
                    continue
                fi
                
                if [ "$verbose" = "true" ]; then
                    printf "%-25s Ubuntu %s LTS on %s\n" "ubuntu${version}-${arch}" "$version" "$arch"
                else
                    echo "ubuntu${version}-${arch}"
                fi
            done
        done
    fi
    
    # macOS platforms
    if [ -z "$os_filter" ] || [ "$os_filter" = "macos" ]; then
        for version in $__DAQ_PLATFORM_MACOS_VERSIONS; do
            for arch in arm64 x86_64; do
                if [ -n "$arch_filter" ] && [ "$arch_filter" != "$arch" ]; then
                    continue
                fi
                
                if [ "$verbose" = "true" ]; then
                    local desc="macOS $version"
                    case "$version" in
                        13) desc="macOS 13 (Ventura)" ;;
                        14) desc="macOS 14 (Sonoma)" ;;
                        15) desc="macOS 15 (Sequoia)" ;;
                    esac
                    printf "%-25s %s on %s\n" "macos${version}-${arch}" "$desc" "$arch"
                else
                    echo "macos${version}-${arch}"
                fi
            done
        done
    fi
    
    # Windows platforms
    if [ -z "$os_filter" ] || [ "$os_filter" = "win" ]; then
        for version in $__DAQ_PLATFORM_WINDOWS_VERSIONS; do
            local arch_match=false
            if [ "$version" = "32" ]; then
                if [ -z "$arch_filter" ] || [ "$arch_filter" = "x86" ]; then
                    arch_match=true
                fi
            elif [ "$version" = "64" ]; then
                if [ -z "$arch_filter" ] || [ "$arch_filter" = "x86_64" ]; then
                    arch_match=true
                fi
            fi
            
            if [ "$arch_match" = "true" ]; then
                if [ "$verbose" = "true" ]; then
                    printf "%-25s Windows %s-bit\n" "win${version}" "$version"
                else
                    echo "win${version}"
                fi
            fi
        done
    fi
}

# List all supported OS families
daq_platform_list_os() {
    local verbose=false
    
    if [ "${1:-}" = "verbose" ] || [ "${1:-}" = "--verbose" ]; then
        verbose=true
    fi
    
    for os in $__DAQ_PLATFORM_ALL_OS; do
        if [ "$verbose" = "true" ]; then
            case "$os" in
                ubuntu)
                    printf "%-10s Ubuntu Linux\n" "$os"
                    ;;
                macos)
                    printf "%-10s Apple macOS\n" "$os"
                    ;;
                win)
                    printf "%-10s Microsoft Windows\n" "$os"
                    ;;
            esac
        else
            echo "$os"
        fi
    done
}

# List all supported architectures
daq_platform_list_arch() {
    local verbose=false
    local os_filter=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            verbose|--verbose)
                verbose=true
                shift
                ;;
            --os)
                os_filter="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    local arches=""
    
    case "$os_filter" in
        ubuntu|macos)
            arches="arm64 x86_64"
            ;;
        win)
            arches="x86 x86_64"
            ;;
        *)
            arches="$__DAQ_PLATFORM_ALL_ARCH"
            ;;
    esac
    
    for arch in $arches; do
        if [ "$verbose" = "true" ]; then
            case "$arch" in
                arm64)
                    printf "%-10s ARM 64-bit (Apple Silicon, ARM servers)\n" "$arch"
                    ;;
                x86_64)
                    printf "%-10s Intel/AMD 64-bit (x86-64)\n" "$arch"
                    ;;
                x86)
                    printf "%-10s Intel/AMD 32-bit (x86)\n" "$arch"
                    ;;
            esac
        else
            echo "$arch"
        fi
    done
}

# List Ubuntu versions
daq_platform_list_ubuntu_versions() {
    echo "$__DAQ_PLATFORM_UBUNTU_VERSIONS"
}

# List macOS versions
daq_platform_list_macos_versions() {
    echo "$__DAQ_PLATFORM_MACOS_VERSIONS"
}

# List Windows versions
daq_platform_list_windows_versions() {
    echo "$__DAQ_PLATFORM_WINDOWS_VERSIONS"
}

################################################################################
# PUBLIC API - Detection
################################################################################

# Detect OS from platform string
# Args: $1 - platform string
# Returns: OS family
daq_platform_detect_os() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    # Parse the platform
    if ! __daq_platform_parse_components "$platform"; then
        return 1
    fi
    
    echo "$__PARSED_OS"
}

# Detect architecture from platform string
# Args: $1 - platform string
# Returns: architecture
daq_platform_detect_arch() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    # Parse the platform
    if ! __daq_platform_parse_components "$platform"; then
        return 1
    fi
    
    echo "$__PARSED_ARCH"
}

# Detect platform type
# Args: $1 - platform string
# Returns: type string
daq_platform_detect_type() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    # Parse the platform
    if ! __daq_platform_parse_components "$platform"; then
        return 1
    fi
    
    # Detect and return type
    __daq_platform_detect_type "$__PARSED_OS" "$__PARSED_VERSION" "$__PARSED_ARCH"
}

################################################################################
# PUBLIC API - Validation
################################################################################

# Validate platform string
# Args: $1 - platform string
# Returns: 0 if valid, 1 if invalid
daq_platform_validate() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    __daq_platform_log_debug "Validating platform: $platform"
    
    # Parse the platform (basic validation)
    if ! __daq_platform_parse_components "$platform"; then
        __daq_platform_log_error "Platform validation failed: invalid format"
        return 1
    fi
    
    __daq_platform_log_verbose "Platform is valid: $platform"
    return 0
}

################################################################################
# PUBLIC API - Parse
################################################################################

# Parse platform string and set environment variables
# Args: $1 - platform string
# Sets: OPENDAQ_PLATFORM_PARSED_* environment variables
# Returns: 0 on success, 1 on failure
daq_platform_parse() {
    local platform="$1"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    # Parse components
    if ! __daq_platform_parse_components "$platform"; then
        return 1
    fi
    
    # Detect type
    local detected_type
    detected_type=$(__daq_platform_detect_type "$__PARSED_OS" "$__PARSED_VERSION" "$__PARSED_ARCH")
    
    # Set environment variables
    export OPENDAQ_PLATFORM_PARSED_OS="$__PARSED_OS"
    export OPENDAQ_PLATFORM_PARSED_VERSION="$__PARSED_VERSION"
    export OPENDAQ_PLATFORM_PARSED_ARCH="$__PARSED_ARCH"
    export OPENDAQ_PLATFORM_PARSED_TYPE="$detected_type"
    
    __daq_platform_log_verbose "Parsed platform: $platform -> os=$__PARSED_OS, version=$__PARSED_VERSION, arch=$__PARSED_ARCH, type=$detected_type"
    
    return 0
}

# Get specific parameter from last parsed platform
# Args: $1 - parameter name (os|version|arch|type)
# Returns: parameter value
daq_platform_get_parameter() {
    local param="$1"
    
    case "$param" in
        os)
            echo "${OPENDAQ_PLATFORM_PARSED_OS:-}"
            ;;
        version)
            echo "${OPENDAQ_PLATFORM_PARSED_VERSION:-}"
            ;;
        arch)
            echo "${OPENDAQ_PLATFORM_PARSED_ARCH:-}"
            ;;
        type)
            echo "${OPENDAQ_PLATFORM_PARSED_TYPE:-}"
            ;;
        *)
            __daq_platform_log_error "Unknown parameter: $param"
            return 1
            ;;
    esac
}

################################################################################
# PUBLIC API - Extract
################################################################################

# Extract platform from text
# Args: $1 - text to search
#       $2 - extract all flag (optional)
# Returns: extracted platform string(s) or empty
daq_platform_extract() {
    local text="$1"
    local extract_all="${2:-}"
    
    if [ -z "$text" ]; then
        __daq_platform_log_error "Text is required"
        return 1
    fi
    
    __daq_platform_extract_from_text "$text" "$extract_all"
}

################################################################################
# PUBLIC API - Compose
################################################################################

# Compose platform string from components
# Args: Various options (see help)
# Returns: composed platform string
daq_platform_compose() {
    local os=""
    local version=""
    local arch=""
    local use_env=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --os)
                os="$2"
                shift 2
                ;;
            --version)
                version="$2"
                shift 2
                ;;
            --arch)
                arch="$2"
                shift 2
                ;;
            --from-env)
                use_env=true
                shift
                ;;
            --verbose)
                shift
                ;;
            *)
                __daq_platform_log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # If using environment variables
    if [ "$use_env" = "true" ]; then
        os="${OPENDAQ_PLATFORM_COMPOSED_OS:-}"
        version="${OPENDAQ_PLATFORM_COMPOSED_VERSION:-}"
        arch="${OPENDAQ_PLATFORM_COMPOSED_ARCH:-}"
    fi
    
    # Validate required components
    if [ -z "$os" ] || [ -z "$version" ]; then
        __daq_platform_log_error "OS and version are required"
        return 1
    fi
    
    # Compose platform string
    __daq_platform_compose_string "$os" "$version" "$arch"
}

################################################################################
# PUBLIC API - Normalize
################################################################################

# Normalize platform string
# Args: $1 - platform string
#       $2 - format (optional: short|long)
# Returns: normalized platform string
daq_platform_normalize() {
    local platform="$1"
    local format="${2:-long}"
    
    if [ -z "$platform" ]; then
        __daq_platform_log_error "Platform string is required"
        return 1
    fi
    
    # Parse the platform
    if ! __daq_platform_parse_components "$platform"; then
        return 1
    fi
    
    # Normalize based on OS
    case "$__PARSED_OS" in
        ubuntu)
            local normalized_version
            normalized_version=$(__daq_platform_normalize_ubuntu_version "$__PARSED_VERSION" "$format")
            echo "ubuntu${normalized_version}-${__PARSED_ARCH}"
            ;;
        macos)
            echo "macos${__PARSED_VERSION}-${__PARSED_ARCH}"
            ;;
        win)
            echo "win${__PARSED_VERSION}"
            ;;
        *)
            echo "$platform"
            ;;
    esac
}

################################################################################
# PUBLIC API - Current Platform
################################################################################

# Get current system platform
# Returns: current platform string
daq_platform_current() {
    if [ -z "${OPENDAQ_PLATFORM_CURRENT:-}" ]; then
        export OPENDAQ_PLATFORM_CURRENT=$(__daq_platform_detect_current)
    fi
    echo "$OPENDAQ_PLATFORM_CURRENT"
}

################################################################################
# CLI INTERFACE
################################################################################

# Main CLI entry point
# Only execute if script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then

    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        __daq_platform_help_short
        exit 0
    fi

    # Parse global flags first
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                __daq_platform_help
                exit 0
                ;;
            --version|-v)
                echo "platform-format v$SCRIPT_VERSION (build: $SCRIPT_BUILD_DATE)"
                exit 0
                ;;
            --verbose)
                __DAQ_PLATFORM_VERBOSE=true
                export OPENDAQ_VERBOSE=true
                shift
                ;;
            --debug|-d)
                __DAQ_PLATFORM_DEBUG=true
                export OPENDAQ_DEBUG=true
                shift
                ;;
            *)
                # Not a global flag, break to process commands
                break
                ;;
        esac
    done

    # Check again after processing global flags
    if [ $# -eq 0 ]; then
        __daq_platform_help_short
        exit 0
    fi

    # Get command or platform string
    COMMAND="$1"
    shift

    ################################################################################
    # CLI COMMAND: Query Commands
    ################################################################################

    case "$COMMAND" in
        --list-platforms)
            # Parse options
            VERBOSE_FLAG=""
            OS_FILTER=""
            ARCH_FILTER=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        VERBOSE_FLAG="verbose"
                        shift
                        ;;
                    --os)
                        OS_FILTER="$2"
                        shift 2
                        ;;
                    --arch)
                        ARCH_FILTER="$2"
                        shift 2
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for --list-platforms: $1"
                        exit 2
                        ;;
                esac
            done
            daq_platform_list $VERBOSE_FLAG --os "$OS_FILTER" --arch "$ARCH_FILTER"
            exit 0
            ;;

        --list-os)
            # Parse options
            VERBOSE_FLAG=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        VERBOSE_FLAG="verbose"
                        shift
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for --list-os: $1"
                        exit 2
                        ;;
                esac
            done
            daq_platform_list_os $VERBOSE_FLAG
            exit 0
            ;;

        --list-arch)
            # Parse options
            VERBOSE_FLAG=""
            OS_FILTER=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        VERBOSE_FLAG="verbose"
                        shift
                        ;;
                    --os)
                        OS_FILTER="$2"
                        shift 2
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for --list-arch: $1"
                        exit 2
                        ;;
                esac
            done
            daq_platform_list_arch $VERBOSE_FLAG --os "$OS_FILTER"
            exit 0
            ;;

        --list-ubuntu-versions)
            daq_platform_list_ubuntu_versions
            exit 0
            ;;

        --list-macos-versions)
            daq_platform_list_macos_versions
            exit 0
            ;;

        --list-windows-versions)
            daq_platform_list_windows_versions
            exit 0
            ;;

    ################################################################################
    # CLI COMMAND: validate
    ################################################################################

        validate)
            if [ $# -eq 0 ]; then
                __daq_platform_help_validate
                exit 2
            fi

            PLATFORM="$1"
            shift

            # Check for help
            if [ "$PLATFORM" = "--help" ] || [ "$PLATFORM" = "-h" ]; then
                __daq_platform_help_validate
                exit 0
            fi

            # Parse validation options
            while [ $# -gt 0 ]; do
                case "$1" in
                    --is-ubuntu)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ "$__PARSED_OS" = "ubuntu" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --is-macos)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ "$__PARSED_OS" = "macos" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --is-windows)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ "$__PARSED_OS" = "win" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --is-arm64)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ "$__PARSED_ARCH" = "arm64" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --is-x86_64)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ "$__PARSED_ARCH" = "x86_64" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --has-arch)
                        if ! __daq_platform_parse_components "$PLATFORM"; then
                            exit 1
                        fi
                        if [ -n "$__PARSED_ARCH" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for validate: $1"
                        exit 2
                        ;;
                esac
            done

            # Basic validation
            daq_platform_validate "$PLATFORM"
            exit $?
            ;;

    ################################################################################
    # CLI COMMAND: parse
    ################################################################################

        parse)
            if [ $# -eq 0 ]; then
                __daq_platform_help_parse
                exit 2
            fi

            PLATFORM="$1"
            shift

            # Check for help
            if [ "$PLATFORM" = "--help" ] || [ "$PLATFORM" = "-h" ]; then
                __daq_platform_help_parse
                exit 0
            fi

            # Parse the platform first
            if ! daq_platform_parse "$PLATFORM"; then
                exit 1
            fi

            # Collect requested components
            REQUESTED_COMPONENTS=()
            while [ $# -gt 0 ]; do
                case "$1" in
                    --os)
                        REQUESTED_COMPONENTS+=("os")
                        shift
                        ;;
                    --version)
                        REQUESTED_COMPONENTS+=("version")
                        shift
                        ;;
                    --arch)
                        REQUESTED_COMPONENTS+=("arch")
                        shift
                        ;;
                    --type)
                        REQUESTED_COMPONENTS+=("type")
                        shift
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for parse: $1"
                        exit 2
                        ;;
                esac
            done

            # Output based on number of requested components
            COMPONENT_COUNT=${#REQUESTED_COMPONENTS[@]}

            if [ $COMPONENT_COUNT -eq 0 ]; then
                # Output all components in KEY=VALUE format
                echo "OPENDAQ_PLATFORM_PARSED_OS=$OPENDAQ_PLATFORM_PARSED_OS"
                echo "OPENDAQ_PLATFORM_PARSED_VERSION=$OPENDAQ_PLATFORM_PARSED_VERSION"
                echo "OPENDAQ_PLATFORM_PARSED_ARCH=$OPENDAQ_PLATFORM_PARSED_ARCH"
                echo "OPENDAQ_PLATFORM_PARSED_TYPE=$OPENDAQ_PLATFORM_PARSED_TYPE"
            elif [ $COMPONENT_COUNT -eq 1 ]; then
                # Output single value only (no KEY=)
                PARAM="${REQUESTED_COMPONENTS[0]}"
                daq_platform_get_parameter "$PARAM"
            else
                # Output multiple KEY=VALUE pairs
                for PARAM in "${REQUESTED_COMPONENTS[@]}"; do
                    VALUE=$(daq_platform_get_parameter "$PARAM")
                    PARAM_UPPER=$(echo "$PARAM" | tr '[:lower:]' '[:upper:]')
                    echo "OPENDAQ_PLATFORM_PARSED_${PARAM_UPPER}=$VALUE"
                done
            fi
            exit 0
            ;;

    ################################################################################
    # CLI COMMAND: compose
    ################################################################################

        compose)
            # Check for help
            if [ $# -gt 0 ] && { [ "$1" = "--help" ] || [ "$1" = "-h" ]; }; then
                __daq_platform_help_compose
                exit 0
            fi

            # Call compose function with all arguments
            COMPOSED=$(daq_platform_compose "$@")
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "$COMPOSED"
                exit 0
            else
                exit $EXIT_CODE
            fi
            ;;

    ################################################################################
    # CLI COMMAND: normalize
    ################################################################################

        normalize)
            if [ $# -eq 0 ]; then
                __daq_platform_help_normalize
                exit 2
            fi

            PLATFORM="$1"
            shift

            # Check for help
            if [ "$PLATFORM" = "--help" ] || [ "$PLATFORM" = "-h" ]; then
                __daq_platform_help_normalize
                exit 0
            fi

            # Parse normalization options
            FORMAT="long"
            while [ $# -gt 0 ]; do
                case "$1" in
                    --short)
                        FORMAT="short"
                        shift
                        ;;
                    --long)
                        FORMAT="long"
                        shift
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for normalize: $1"
                        exit 2
                        ;;
                esac
            done

            # Normalize the platform
            NORMALIZED=$(daq_platform_normalize "$PLATFORM" "$FORMAT")
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "$NORMALIZED"
                exit 0
            else
                exit $EXIT_CODE
            fi
            ;;

    ################################################################################
    # CLI COMMAND: extract
    ################################################################################

        extract)
            if [ $# -eq 0 ]; then
                __daq_platform_help_extract
                exit 2
            fi

            TEXT="$1"
            shift

            # Check for help
            if [ "$TEXT" = "--help" ] || [ "$TEXT" = "-h" ]; then
                __daq_platform_help_extract
                exit 0
            fi

            # Read from stdin if TEXT is "-"
            if [ "$TEXT" = "-" ]; then
                TEXT=$(cat)
            fi

            # Parse extraction options
            EXTRACT_ALL=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --all)
                        EXTRACT_ALL="all"
                        shift
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for extract: $1"
                        exit 2
                        ;;
                esac
            done

            # Extract platform
            EXTRACTED=$(daq_platform_extract "$TEXT" "$EXTRACT_ALL")
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "$EXTRACTED"
                exit 0
            else
                __daq_platform_log_error "No platform found in text"
                exit 1
            fi
            ;;

    ################################################################################
    # CLI COMMAND: Detection (platform string with flags)
    ################################################################################

        *)
            # Check if COMMAND looks like a platform string
            # Simple check using case patterns
            IS_PLATFORM=false
            case "$COMMAND" in
                ubuntu*-arm64|ubuntu*-x86_64)
                    IS_PLATFORM=true
                    ;;
                macos*-arm64|macos*-x86_64)
                    IS_PLATFORM=true
                    ;;
                win32|win64)
                    IS_PLATFORM=true
                    ;;
            esac
            
            if [ "$IS_PLATFORM" = "true" ]; then
                PLATFORM="$COMMAND"
                
                # Parse detection flags
                if [ $# -eq 0 ]; then
                    __daq_platform_error_usage "Platform string provided but no action specified"
                    exit 2
                fi

                case "$1" in
                    --detect-os)
                        DETECTED=$(daq_platform_detect_os "$PLATFORM")
                        EXIT_CODE=$?
                        if [ $EXIT_CODE -eq 0 ]; then
                            echo "$DETECTED"
                            exit 0
                        else
                            exit $EXIT_CODE
                        fi
                        ;;
                    --detect-arch)
                        DETECTED=$(daq_platform_detect_arch "$PLATFORM")
                        EXIT_CODE=$?
                        if [ $EXIT_CODE -eq 0 ]; then
                            echo "$DETECTED"
                            exit 0
                        else
                            exit $EXIT_CODE
                        fi
                        ;;
                    --detect-type)
                        DETECTED=$(daq_platform_detect_type "$PLATFORM")
                        EXIT_CODE=$?
                        if [ $EXIT_CODE -eq 0 ]; then
                            echo "$DETECTED"
                            exit 0
                        else
                            exit $EXIT_CODE
                        fi
                        ;;
                    *)
                        __daq_platform_error_usage "Unknown option for platform detection: $1"
                        exit 2
                        ;;
                esac
            else
                __daq_platform_error_usage "Unknown command: $COMMAND"
                exit 2
            fi
            ;;
    esac

fi

################################################################################
# END OF SCRIPT
################################################################################
