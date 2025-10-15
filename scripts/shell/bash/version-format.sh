#!/usr/bin/env bash
# version-format.sh - OpenDAQ Version Format Utilities
# Supports version formatting, parsing, validation and extraction
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

# Supported version formats
readonly OPENDAQ_VERSION_FORMATS=(
    "X.YY.Z"
    "vX.YY.Z"
    "X.YY.Z-rc"
    "vX.YY.Z-rc"
    "X.YY.Z-HASH"
    "vX.YY.Z-HASH"
    "X.YY.Z-rc-HASH"
    "vX.YY.Z-rc-HASH"
    "X.YY.Z-<suffix>"
    "vX.YY.Z-<suffix>"
    "X.YY.Z-<suffix>-HASH"
    "vX.YY.Z-<suffix>-HASH"
)

# Verbose flag
__DAQ_VERSION_VERBOSE=0

# Match result variables (initialized to avoid unset variable errors)
__MATCH_PREFIX=""
__MATCH_MAJOR=""
__MATCH_MINOR=""
__MATCH_PATCH=""
__MATCH_SUFFIX=""
__MATCH_HASH=""

# Regex pattern for version matching
# Groups: (v?)(major).(minor).(patch)(-suffix)?(-hash)?
readonly __DAQ_VERSION_REGEX='^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-(.+))?$'

# Log message if verbose mode is enabled
# Args: message
__daq_version_log() {
    if [ "${__DAQ_VERSION_VERBOSE}" -eq 1 ]; then
        echo "[version-format] $*" >&2
    fi
}

# Print error message to stderr
# Args: message
__daq_version_error() {
    echo "[version-format] ERROR: $*" >&2
}

# Print usage information
__daq_version_usage() {
    cat <<'EOF'
Usage: version-format.sh <action> [options]

Actions:
  compose   Build a version string from components
  parse     Parse version string into components
  validate  Validate version string format
  extract   Extract version from text

Compose options:
  --major X              Major version number (required)
  --minor YY             Minor version number (required)
  --patch Z              Patch version number (required)
  --suffix rc            Release candidate suffix (optional)
  --hash HASH            Git hash suffix (7-40 hex chars, optional)
  --exclude-prefix       Exclude 'v' prefix (default: include)
  --format FORMAT        Use specific format (validates arguments)

Note: --suffix and --hash are mutually exclusive

Parse options:
  VERSION                Version string to parse (required)
  --major                Output only major version
  --minor                Output only minor version
  --patch                Output only patch version
  --suffix               Output only suffix (rc or empty)
  --hash                 Output only hash
  --prefix               Output only prefix (v or empty)

Validate options:
  VERSION                Version string to validate (required)
  --format FORMAT        Validate against specific format
  --is-release           Check if release format (X.YY.Z or vX.YY.Z)
  --is-rc                Check if RC format (contains -rc)
  --is-dev               Check if dev format (contains -HASH)

Extract options:
  TEXT                   Text to extract version from (required)

Global options:
  --verbose              Enable verbose output

Supported formats:
  X.YY.Z          Release without prefix
  vX.YY.Z         Release with prefix (default)
  X.YY.Z-rc       Release candidate without prefix
  vX.YY.Z-rc      Release candidate with prefix
  X.YY.Z-HASH     Development version without prefix
  vX.YY.Z-HASH    Development version with prefix

Examples:
  version-format.sh compose --major 1 --minor 2 --patch 3
  version-format.sh compose --major 1 --minor 2 --patch 3 --suffix rc
  version-format.sh compose --major 1 --minor 2 --patch 3 --hash a1b2c3d
  version-format.sh parse v1.2.3-rc --major
  version-format.sh validate v1.2.3-rc --is-rc
  version-format.sh extract 'opendaq-v1.2.3-linux.tar.gz'
EOF
}

# Validate hash format (hex only, 7-40 characters)
# Args: hash
# Returns: 0 if valid, 1 otherwise
__daq_version_validate_hash() {
    local hash="${1:-}"
    
    if [ -z "$hash" ]; then
        return 0  # Empty hash is valid (optional)
    fi
    
    # Check length (7-40 characters)
    local len=${#hash}
    if [ "$len" -lt 7 ] || [ "$len" -gt 40 ]; then
        __daq_version_error "Invalid hash format: '$hash' (must be 7-40 hex characters)"
        return 1
    fi
    
    # Check if all characters are lowercase hex
    if echo "$hash" | grep -qE '^[0-9a-f]+$'; then
        return 0
    fi
    
    __daq_version_error "Invalid hash format: '$hash' (must be 7-40 hex characters)"
    return 1
}

# Match version string against regex and extract components
# Args: version_string
# Returns: 0 if matches, 1 otherwise
# Sets global variables: __MATCH_PREFIX, __MATCH_MAJOR, __MATCH_MINOR, __MATCH_PATCH, __MATCH_SUFFIX, __MATCH_HASH
__daq_version_match() {
    local version="$1"
    
    # Clear previous matches
    __MATCH_PREFIX=""
    __MATCH_MAJOR=""
    __MATCH_MINOR=""
    __MATCH_PATCH=""
    __MATCH_SUFFIX=""
    __MATCH_HASH=""
    
    # Use grep for compatibility with bash 3.2
    if ! echo "$version" | grep -qE "$__DAQ_VERSION_REGEX"; then
        return 1
    fi
    
    # Extract prefix (v or empty)
    if echo "$version" | grep -qE '^v'; then
        __MATCH_PREFIX="v"
        version="${version#v}"
    fi
    
    # Extract major.minor.patch
    __MATCH_MAJOR=$(echo "$version" | sed 's/^\([0-9]*\)\..*/\1/')
    __MATCH_MINOR=$(echo "$version" | sed 's/^[0-9]*\.\([0-9]*\)\..*/\1/')
    __MATCH_PATCH=$(echo "$version" | sed 's/^[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/')
    
    # Extract suffix and hash if present
    local remainder
    remainder=$(echo "$version" | sed 's/^[0-9]*\.[0-9]*\.[0-9]*//')
    
    if [ -n "$remainder" ]; then
        # Remove leading dash
        remainder="${remainder#-}"

        if [ "$remainder" = "rc" ]; then
            __MATCH_SUFFIX="rc"
        elif echo "$remainder" | grep -qE '^[0-9a-fA-F]+$'; then
            local len=${#remainder}
            if [ "$len" -ge 7 ] && [ "$len" -le 40 ]; then
                if echo "$remainder" | grep -qE '^[0-9a-f]+$'; then
                    __MATCH_HASH="$remainder"
                else
                    __daq_version_error "Invalid hash format in version: '$remainder' (contains uppercase)"
                    return 1
                fi
            else
                if [ "$len" -lt 7 ]; then
                    __daq_version_error "Invalid version format: '$remainder' (too short for hash, min 7 chars)"
                else
                    __daq_version_error "Invalid hash format in version: '$remainder' (too long, max 40 chars)"
                fi
                return 1
            fi
        else
            __daq_version_error "Invalid version suffix: '$remainder' (only 'rc' or valid hash allowed)"
            return 1
        fi
    fi    
    
    __daq_version_log "Matched version: prefix='$__MATCH_PREFIX' major='$__MATCH_MAJOR' minor='$__MATCH_MINOR' patch='$__MATCH_PATCH' suffix='$__MATCH_SUFFIX' hash='$__MATCH_HASH'"
    return 0
}

# Determine format name from components
# Args: prefix, suffix, hash
# Returns: format name
__daq_version_get_format() {
    local prefix="$1"
    local suffix="$2"
    local hash="$3"
    
    local fmt=""
    
    # Build format string
    if [ -n "$prefix" ]; then
        fmt="vX.YY.Z"
    else
        fmt="X.YY.Z"
    fi
    
    if [ "$suffix" = "rc" ]; then
        fmt="${fmt}-rc"
    elif [ -n "$hash" ]; then
        fmt="${fmt}-HASH"
    fi
    
    echo "$fmt"
}

# Validate format name
# Args: format_name
# Returns: 0 if valid, 1 otherwise
__daq_version_validate_format_name() {
    local format="$1"
    
    for valid_format in "${OPENDAQ_VERSION_FORMATS[@]}"; do
        if [ "$format" = "$valid_format" ]; then
            return 0
        fi
    done
    
    return 1
}

# Check if format matches version components
# Args: format_name, prefix, suffix, hash
# Returns: 0 if matches, 1 otherwise
__daq_version_format_matches() {
    local format="$1"
    local prefix="$2"
    local suffix="$3"
    local hash="$4"
    
    case "$format" in
        "X.YY.Z")
            [ -z "$prefix" ] && [ -z "$suffix" ] && [ -z "$hash" ]
            ;;
        "vX.YY.Z")
            [ "$prefix" = "v" ] && [ -z "$suffix" ] && [ -z "$hash" ]
            ;;
        "X.YY.Z-rc")
            [ -z "$prefix" ] && [ "$suffix" = "rc" ] && [ -z "$hash" ]
            ;;
        "vX.YY.Z-rc")
            [ "$prefix" = "v" ] && [ "$suffix" = "rc" ] && [ -z "$hash" ]
            ;;
        "X.YY.Z-HASH")
            [ -z "$prefix" ] && [ -z "$suffix" ] && [ -n "$hash" ]
            ;;
        "vX.YY.Z-HASH")
            [ "$prefix" = "v" ] && [ -z "$suffix" ] && [ -n "$hash" ]
            ;;
        *)
            return 1
            ;;
    esac
}

# Compose version string from components
# Args: --major X --minor YY --patch Z [--suffix SUFFIX] [--hash HASH] [--exclude-prefix] [--format FORMAT]
# Returns: version string
daq_version_compose() {
    local major=""
    local minor=""
    local patch=""
    local suffix=""
    local hash=""
    local exclude_prefix=0
    local format=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --major)
                major="$2"
                shift 2
                ;;
            --minor)
                minor="$2"
                shift 2
                ;;
            --patch)
                patch="$2"
                shift 2
                ;;
            --suffix)
                suffix="$2"
                shift 2
                ;;
            --hash)
                hash="$2"
                shift 2
                ;;
            --exclude-prefix)
                exclude_prefix=1
                shift
                ;;
            --format)
                format="$2"
                shift 2
                ;;
            *)
                __daq_version_error "Unknown argument: $1"
                return 1
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$major" ] || [ -z "$minor" ] || [ -z "$patch" ]; then
        __daq_version_error "Missing required arguments: --major, --minor, --patch"
        return 1
    fi
    
    # Validate hash format if provided
    if [ -n "$suffix" ] && [ "$suffix" != "rc" ]; then
        __daq_version_error "Invalid suffix: '$suffix' (only 'rc' is allowed)"
        return 1
    fi
    
    if [ -n "$suffix" ] && [ -n "$hash" ]; then
        __daq_version_error "Cannot use both --suffix and --hash (mutually exclusive)"
        return 1
    fi

    if ! __daq_version_validate_hash "$hash"; then
        return 1
    fi
    
    __daq_version_log "Composing version: major=$major minor=$minor patch=$patch suffix='$suffix' hash='$hash' exclude_prefix=$exclude_prefix format='$format'"
    
    # Validate and adjust based on format if specified
    if [ -n "$format" ]; then
        if ! __daq_version_validate_format_name "$format"; then
            __daq_version_error "Invalid format: $format"
            return 1
        fi
        
        # Adjust parameters based on format requirements
        case "$format" in
            "X.YY.Z")
                exclude_prefix=1
                suffix=""
                hash=""
                ;;
            "vX.YY.Z")
                exclude_prefix=0
                suffix=""
                hash=""
                ;;
            "X.YY.Z-rc")
                exclude_prefix=1
                suffix="rc"
                hash=""
                ;;
            "vX.YY.Z-rc")
                exclude_prefix=0
                suffix="rc"
                hash=""
                ;;
            "X.YY.Z-HASH")
                exclude_prefix=1
                suffix=""
                if [ -z "$hash" ]; then
                    __daq_version_error "Format $format requires --hash"
                    return 1
                fi
                ;;
            "vX.YY.Z-HASH")
                exclude_prefix=0
                suffix=""
                if [ -z "$hash" ]; then
                    __daq_version_error "Format $format requires --hash"
                    return 1
                fi
                ;;
        esac
    fi
    
    # Build version string
    local version=""
    
    if [ "$exclude_prefix" -eq 0 ]; then
        version="v"
    fi
    
    version="${version}${major}.${minor}.${patch}"
    
    if [ "$suffix" = "rc" ]; then
        version="${version}-rc"
    elif [ -n "$hash" ]; then
        version="${version}-${hash}"
    fi
    
    __daq_version_log "Composed version: $version"
    echo "$version"
}

# Parse version string into components
# Args: VERSION [--major|--minor|--patch|--suffix|--hash|--prefix]
# Returns: component value or all components
daq_version_parse() {
    if [ $# -eq 0 ]; then
        __daq_version_error "Missing version argument"
        return 1
    fi
    
    local version="$1"
    shift
    
    local component=""
    if [ $# -gt 0 ]; then
        component="$1"
    fi
    
    __daq_version_log "Parsing version: $version component='$component'"
    
    # Match version
    if ! __daq_version_match "$version"; then
        __daq_version_error "Invalid version format: $version"
        return 1
    fi
    
    # Return requested component or all
    case "$component" in
        --major)
            echo "$__MATCH_MAJOR"
            ;;
        --minor)
            echo "$__MATCH_MINOR"
            ;;
        --patch)
            echo "$__MATCH_PATCH"
            ;;
        --suffix)
            echo "$__MATCH_SUFFIX"
            ;;
        --hash)
            echo "$__MATCH_HASH"
            ;;
        --prefix)
            echo "$__MATCH_PREFIX"
            ;;
        "")
            # Return all components as array
            echo "$__MATCH_MAJOR $__MATCH_MINOR $__MATCH_PATCH $__MATCH_SUFFIX $__MATCH_HASH $__MATCH_PREFIX"
            ;;
        *)
            __daq_version_error "Unknown component: $component"
            return 1
            ;;
    esac
}

# Validate version string
# Args: VERSION [--format FORMAT|--is-release|--is-rc|--is-dev]
# Returns: 0 if valid, 1 otherwise
daq_version_validate() {
    if [ $# -eq 0 ]; then
        __daq_version_error "Missing version argument"
        return 1
    fi
    
    local version="$1"
    shift
    
    local check_format=""
    local check_type=""
    
    if [ $# -gt 0 ]; then
        case "$1" in
            --format)
                check_format="$2"
                ;;
            --is-release)
                check_type="release"
                ;;
            --is-rc)
                check_type="rc"
                ;;
            --is-dev)
                check_type="dev"
                ;;
            *)
                __daq_version_error "Unknown validation option: $1"
                return 1
                ;;
        esac
    fi
    
    __daq_version_log "Validating version: $version format='$check_format' type='$check_type'"
    
    # Match version
    if ! __daq_version_match "$version"; then
        __daq_version_log "Version does not match regex"
        return 1
    fi
    
    # Check specific format
    if [ -n "$check_format" ]; then
        if ! __daq_version_validate_format_name "$check_format"; then
            __daq_version_error "Invalid format name: $check_format"
            return 1
        fi
        
        if __daq_version_format_matches "$check_format" "$__MATCH_PREFIX" "$__MATCH_SUFFIX" "$__MATCH_HASH"; then
            __daq_version_log "Version matches format: $check_format"
            return 0
        else
            __daq_version_log "Version does not match format: $check_format"
            return 1
        fi
    fi
    
    # Check type
    if [ -n "$check_type" ]; then
        case "$check_type" in
            release)
                if [ -z "$__MATCH_SUFFIX" ] && [ -z "$__MATCH_HASH" ]; then
                    __daq_version_log "Version is a release"
                    return 0
                fi
                __daq_version_log "Version is not a release"
                return 1
                ;;
            rc)
                if [ "$__MATCH_SUFFIX" = "rc" ]; then
                    __daq_version_log "Version is an RC"
                    return 0
                fi
                __daq_version_log "Version is not an RC"
                return 1
                ;;
            dev)
                if [ -n "$__MATCH_HASH" ] && [ -z "$__MATCH_SUFFIX" ]; then
                    __daq_version_log "Version is a dev version"
                    return 0
                fi
                __daq_version_log "Version is not a dev version"
                return 1
                ;;
        esac
    fi
    
    # General validation passed
    __daq_version_log "Version is valid"
    return 0
}

# Extract version from text
# Args: TEXT
# Returns: extracted version or empty
daq_version_extract() {
    if [ $# -eq 0 ]; then
        __daq_version_error "Missing text argument"
        return 1
    fi
    
    local text="$1"
    
    __daq_version_log "Extracting version from: $text"
    
    # Try to find version pattern in text
    # Try patterns in order from most specific to least specific
    # Validation of hash length happens in __daq_version_match
    local patterns=(
        'v?[0-9]+\.[0-9]+\.[0-9]+-[a-f0-9]+'
        'v?[0-9]+\.[0-9]+\.[0-9]+-rc'
        'v?[0-9]+\.[0-9]+\.[0-9]+'
    )
    
    local extracted=""
    for pattern in "${patterns[@]}"; do
        extracted=$(echo "$text" | grep -oE "$pattern" | head -n 1) || true
        if [ -n "$extracted" ]; then
            # Validate extracted version (including hash length check)
            if __daq_version_match "$extracted"; then
                __daq_version_log "Extracted version: $extracted"
                echo "$extracted"
                return 0
            fi
        fi
    done
    
    __daq_version_log "No version found in text"
    return 1
}

# Main CLI function
__daq_version_main() {
    if [ $# -eq 0 ]; then
        __daq_version_usage
        return 1
    fi
    
    # Check for verbose flag and collect other arguments
    local args=()
    local i=0
    
    for arg in "$@"; do
        if [ "$arg" = "--verbose" ]; then
            __DAQ_VERSION_VERBOSE=1
        else
            args[$i]="$arg"
            i=$((i + 1))
        fi
    done
    
    if [ ${#args[@]} -eq 0 ]; then
        __daq_version_usage
        return 1
    fi
    
    local action="${args[0]}"
    
    # Prepare arguments for the action (skip first element)
    # Use shift approach for compatibility
    set -- "${args[@]}"
    shift
    
    case "$action" in
        compose)
            daq_version_compose "$@"
            ;;
        parse)
            daq_version_parse "$@"
            ;;
        validate)
            daq_version_validate "$@"
            ;;
        extract)
            daq_version_extract "$@"
            ;;
        help|--help|-h)
            __daq_version_usage
            ;;
        *)
            __daq_version_error "Unknown action: $action"
            __daq_version_usage
            return 1
            ;;
    esac
}

# Flag to track if script was sourced (0=executed, 1=sourced)
__DAQ_VERSION_SOURCED=0

if [ -n "${BASH_VERSION:-}" ]; then
    # Bash: Compare script path with invocation path
    # BASH_SOURCE[0] = script path, $0 = invocation path
    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
        __DAQ_VERSION_SOURCED=1
    fi
elif [ -n "${ZSH_VERSION:-}" ]; then
    # Zsh: Use prompt expansion to get script name
    if [[ "${ZSH_EVAL_CONTEXT:-}" == *:file ]]; then
        __DAQ_VERSION_SOURCED=1
    fi
fi

# Run main only if not sourced
if [ "$__DAQ_VERSION_SOURCED" -eq 0 ]; then
    __daq_version_main "$@"
fi
