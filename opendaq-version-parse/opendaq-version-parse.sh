#!/bin/bash

# parse_version.sh - openDAQ version parser and validator
# Compatible with Bash 3.x and POSIX shells

# Regular expression for version parsing
VERSION_REGEX="^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$"

# Display help information
show_help() {
    cat << 'EOF'
NAME
    opendaq-version-parse.sh - openDAQ version parser and validator

SYNOPSIS
    opendaq-version-parse.sh <VERSION|TEXT> [OPTIONS] [PARAMETERS]

DESCRIPTION
    Parse, validate and extract version information from openDAQ version strings.
    Supports multiple version formats including releases, release candidates, and
    development versions with optional 'v' prefix.

OPTIONS
    -h, --help          Show this help message and exit
    --validate          Only validate version (exit code only)
    --extract           Extract version from arbitrary text
    --verbose           Verbose human-readable output
    --format FORMAT     Validate against specific format (see FORMATS section)
    --list-formats      List all supported formats

EXTRACTION PARAMETERS
    --major             Major version number
    --minor             Minor version number  
    --patch             Patch version number
    --hash              Commit hash (string or empty)
    --type              Version type (release|rc|dev|rc-dev)
    --is-rc             Is release candidate version (true|false)
    --is-dev            Is development version (true|false)
    --is-release        Is release version (true|false)
    --is-rc-dev         Is RC development version (true|false)
    --has-v             Has 'v' prefix (true|false)

SUPPORTED FORMATS
    X.YY.Z              Release version
    vX.YY.Z             Release version with 'v' prefix
    X.YY.Z-rc           Release candidate
    vX.YY.Z-rc          Release candidate with 'v' prefix
    X.YY.Z-HASH         Development version
    vX.YY.Z-HASH        Development version with 'v' prefix
    X.YY.Z-rc-HASH      RC with additional commits
    vX.YY.Z-rc-HASH     RC with additional commits and 'v' prefix

EXAMPLES
    opendaq-version-parse.sh "3.14.2"
        Parse release version

    opendaq-version-parse.sh "v3.14.2-rc-abc123f" --major --type
        Extract major version and type

    opendaq-version-parse.sh "Release v3.14.2 is ready" --extract --verbose
        Extract and display version details from text

    opendaq-version-parse.sh "3.14.2" --validate --format "X.YY.Z"
        Validate version against specific format

    opendaq-version-parse.sh --list-formats
        List all supported formats

    opendaq-version-parse.sh --list-formats --verbose
        List formats with detailed descriptions

EXIT STATUS
    0       Success
    1       Error (invalid version, version not found, unknown parameters)

AUTHOR
    openDAQ project

EOF
}

# Get format regex pattern (using template names)
get_format_regex() {
    case "$1" in
        "X.YY.Z") echo "^[0-9]+\.[0-9]+\.[0-9]+$" ;;
        "vX.YY.Z") echo "^v[0-9]+\.[0-9]+\.[0-9]+$" ;;
        "X.YY.Z-rc") echo "^[0-9]+\.[0-9]+\.[0-9]+-rc$" ;;
        "vX.YY.Z-rc") echo "^v[0-9]+\.[0-9]+\.[0-9]+-rc$" ;;
        "X.YY.Z-HASH") echo "^[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]+$" ;;
        "vX.YY.Z-HASH") echo "^v[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]+$" ;;
        "X.YY.Z-rc-HASH") echo "^[0-9]+\.[0-9]+\.[0-9]+-rc-[0-9a-f]+$" ;;
        "vX.YY.Z-rc-HASH") echo "^v[0-9]+\.[0-9]+\.[0-9]+-rc-[0-9a-f]+$" ;;
        *) return 1 ;;
    esac
}

# Get format description
get_format_description() {
    case "$1" in
        "X.YY.Z") echo "Release version" ;;
        "vX.YY.Z") echo "Release version with 'v' prefix" ;;
        "X.YY.Z-rc") echo "Release candidate" ;;
        "vX.YY.Z-rc") echo "Release candidate with 'v' prefix" ;;
        "X.YY.Z-HASH") echo "Development version" ;;
        "vX.YY.Z-HASH") echo "Development version with 'v' prefix" ;;
        "X.YY.Z-rc-HASH") echo "RC with additional commits" ;;
        "vX.YY.Z-rc-HASH") echo "RC with additional commits and 'v' prefix" ;;
        *) return 1 ;;
    esac
}

# Get all supported formats
get_all_formats() {
    echo "X.YY.Z vX.YY.Z X.YY.Z-rc vX.YY.Z-rc X.YY.Z-HASH vX.YY.Z-HASH X.YY.Z-rc-HASH vX.YY.Z-rc-HASH"
}

# List supported formats
list_formats() {
    local verbose_mode="$1"
    
    if [ "$verbose_mode" = "true" ]; then
        echo "Supported version formats:"
        echo
        for format in $(get_all_formats); do
            printf "  %-16s %s\n" "$format" "$(get_format_description "$format")"
        done
    else
        # Simple array output - one per line
        for format in $(get_all_formats); do
            echo "$format"
        done
    fi
}

# Validate version against specific format
validate_format() {
    local version="$1"
    local format="$2"
    
    local regex
    regex=$(get_format_regex "$format")
    if [ $? -ne 0 ]; then
        echo "Unknown format: $format" >&2
        echo "Use --list-formats to see available formats" >&2
        return 1
    fi
    
    # Use grep for regex matching (more portable than [[ =~ ]])
    if echo "$version" | grep -qE "$regex"; then
        return 0
    else
        return 1
    fi
}

# Parse version string into components (using grep for compatibility)
parse_version() {
    local version="$1"
    
    # Use grep to check if version matches pattern
    if echo "$version" | grep -qE "$VERSION_REGEX"; then
        # Extract components using sed (more portable)
        V_PREFIX=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\1/')
        MAJOR=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\2/')
        MINOR=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\3/')
        PATCH=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\4/')
        RC=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\5/')
        HASH=$(echo "$version" | sed -E 's/^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-rc)?(-[0-9a-f]+)?$/\6/')
        
        # Remove leading dash from hash if present
        if [ -n "$HASH" ]; then
            HASH="${HASH#-}"
        fi
        
        return 0
    else
        return 1
    fi
}

# Determine version type
get_version_type() {
    if [ -n "$RC" ] && [ -n "$HASH" ]; then
        echo "rc-dev"
    elif [ -n "$RC" ]; then
        echo "rc"
    elif [ -n "$HASH" ]; then
        echo "dev"
    else
        echo "release"
    fi
}

# Extract version from arbitrary text
extract_version() {
    local text="$1"
    local found_version
    
    # Try multiple patterns in order of complexity
    # First try to find full versions with rc and hash
    found_version=$(echo "$text" | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+-rc-[0-9a-f]+" | head -1)
    if [ -n "$found_version" ]; then
        echo "$found_version"
        return 0
    fi
    
    # Then try versions with just hash (but not rc)
    found_version=$(echo "$text" | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+-[0-9a-f]+" | head -1)
    if [ -n "$found_version" ]; then
        # Make sure this is not a rc-hash version (already checked above)
        if ! echo "$found_version" | grep -q "\-rc\-"; then
            echo "$found_version"
            return 0
        fi
    fi
    
    # Then try rc versions
    found_version=$(echo "$text" | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+-rc" | head -1)
    if [ -n "$found_version" ]; then
        echo "$found_version"
        return 0
    fi
    
    # Finally try simple versions
    found_version=$(echo "$text" | grep -oE "v?[0-9]+\.[0-9]+\.[0-9]+" | head -1)
    if [ -n "$found_version" ]; then
        echo "$found_version"
        return 0
    fi
    
    return 1
}

# Get specific version parameter
get_parameter() {
    case "$1" in
        --major) echo "$MAJOR" ;;
        --minor) echo "$MINOR" ;;
        --patch) echo "$PATCH" ;;
        --hash) echo "${HASH:-}" ;;
        --type) get_version_type ;;
        --is-rc) [ -n "$RC" ] && echo "true" || echo "false" ;;
        --is-dev) [ -n "$HASH" ] && echo "true" || echo "false" ;;
        --is-release) [ -z "$RC" ] && [ -z "$HASH" ] && echo "true" || echo "false" ;;
        --is-rc-dev) [ -n "$RC" ] && [ -n "$HASH" ] && echo "true" || echo "false" ;;
        --has-v) [ -n "$V_PREFIX" ] && echo "true" || echo "false" ;;
        *) echo "Unknown parameter: $1" >&2; return 1 ;;
    esac
}

# Display verbose version information
verbose_output() {
    local version="$1"
    local type
    type=$(get_version_type)
    
    echo "Version: $version"
    echo "Major: $MAJOR"
    echo "Minor: $MINOR"
    echo "Patch: $PATCH"
    echo "Hash: ${HASH:-none}"
    echo "Type: $type"
    echo "RC: $([ -n "$RC" ] && echo "yes" || echo "no")"
    echo "Dev: $([ -n "$HASH" ] && echo "yes" || echo "no")"
    echo "Release: $([ -z "$RC" ] && [ -z "$HASH" ] && echo "yes" || echo "no")"
    echo "RC-dev: $([ -n "$RC" ] && [ -n "$HASH" ] && echo "yes" || echo "no")"
    echo "Has v prefix: $([ -n "$V_PREFIX" ] && echo "yes" || echo "no")"
}

# Main script logic
parse_version_main() {
    local input="$1"
    shift
    
    local validate_only=false
    local extract_mode=false
    local verbose_mode=false
    local list_formats_mode=false
    local format=""
    local parameters=""
    local param_count=0
    
    # Parse flags and parameters
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            --extract)
                extract_mode=true
                shift
                ;;
            --verbose)
                verbose_mode=true
                shift
                ;;
            --list-formats)
                list_formats_mode=true
                shift
                ;;
            --format)
                if [ $# -lt 2 ]; then
                    echo "Error: --format requires a format name" >&2
                    exit 1
                fi
                format="$2"
                shift 2
                ;;
            --major|--minor|--patch|--hash|--type|--is-rc|--is-dev|--is-release|--is-rc-dev|--has-v)
                parameters="$parameters $1"
                param_count=$((param_count + 1))
                shift
                ;;
            *)
                echo "Unknown parameter: $1" >&2
                exit 1
                ;;
        esac
    done
    
    # Handle list formats mode
    if [ "$list_formats_mode" = true ]; then
        list_formats "$verbose_mode"
        exit 0
    fi
    
    # Check if input is provided when needed
    if [ -z "$input" ] && ([ "$extract_mode" = true ] || [ "$validate_only" = true ] || [ $param_count -gt 0 ]); then
        echo "Error: Version or text input required" >&2
        exit 1
    fi
    
    # Handle extraction mode
    if [ "$extract_mode" = true ]; then
        local extracted_version
        extracted_version=$(extract_version "$input")
        if [ $? -eq 0 ]; then
            input="$extracted_version"
        else
            if [ "$validate_only" = true ] && [ "$verbose_mode" = true ]; then
                echo "Version not found in text" >&2
            fi
            exit 1
        fi
    fi
    
    # Handle format-specific validation
    if [ -n "$format" ]; then
        if ! validate_format "$input" "$format"; then
            if [ "$verbose_mode" = true ]; then
                echo "Version '$input' does not match format '$format'" >&2
                echo "Expected format: $(get_format_description "$format")" >&2
            fi
            exit 1
        fi
        if [ "$validate_only" = true ]; then
            if [ "$verbose_mode" = true ]; then
                echo "Version '$input' matches format '$format'"
            fi
            exit 0
        fi
    fi
    
    # Parse version (for general validation and parameter extraction)
    if ! parse_version "$input"; then
        if [ "$validate_only" = true ] && [ "$verbose_mode" = true ]; then
            echo "Invalid version: $input" >&2
            echo "Supported formats:"
            echo "  X.YY.Z              Release version"
            echo "  X.YY.Z-rc           Release candidate"
            echo "  X.YY.Z-HASH         Development version"
            echo "  X.YY.Z-rc-HASH      RC with additional commits"
            echo "  vX.YY.Z             Same formats with 'v' prefix"
        fi
        exit 1
    fi
    
    # Validation only mode (without specific format)
    if [ "$validate_only" = true ]; then
        if [ "$verbose_mode" = true ]; then
            echo "Valid version: $input"
        fi
        exit 0
    fi
    
    # Verbose output without specific parameters
    if [ "$verbose_mode" = true ] && [ $param_count -eq 0 ]; then
        verbose_output "$input"
        exit 0
    fi
    
    # Handle parameter output
    if [ $param_count -eq 0 ]; then
        # No parameters - output version info
        if [ "$verbose_mode" = true ]; then
            verbose_output "$input"
        elif [ "$extract_mode" = true ]; then
            # For extract mode, output the full extracted version
            echo "$input"
        else
            # For normal parsing, output basic version
            echo "$MAJOR.$MINOR.$PATCH"
        fi
    elif [ $param_count -eq 1 ]; then
        # Single parameter - single value
        get_parameter $parameters
    else
        # Multiple parameters - array of values
        for param in $parameters; do
            get_parameter "$param"
        done
    fi
}

# ============================================================================
# PUBLIC API FOR SOURCING
# ============================================================================

# Parse version string - returns components in global variables
opendaq_version_parse() {
    parse_version "$@"
}

# Extract version from arbitrary text
opendaq_version_extract() {
    extract_version "$@"
}

# Get version type (release|rc|dev|rc-dev)
opendaq_version_get_type() {
    get_version_type "$@"
}

# Get specific parameter value
opendaq_version_get_parameter() {
    get_parameter "$@"
}

# Validate version against format
opendaq_version_validate_format() {
    validate_format "$@"
}

# List supported formats
opendaq_version_list_formats() {
    list_formats "$@"
}

# Get format regex pattern
opendaq_version_get_format_regex() {
    get_format_regex "$@"
}

# Get format description
opendaq_version_get_format_description() {
    get_format_description "$@"
}

# Main function (for programmatic use)
opendaq_version_main() {
    parse_version_main "$@"
}

# Special cases for --list-formats and --help without other arguments
if [ $# -eq 1 ]; then
    case "$1" in
        --list-formats)
            list_formats false
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
    esac
fi

if [ $# -eq 2 ] && [ "$1" = "--list-formats" ] && [ "$2" = "--verbose" ]; then
    list_formats true
    exit 0
fi

if [ $# -eq 2 ] && [ "$2" = "--verbose" ] && [ "$1" = "--list-formats" ]; then
    list_formats true
    exit 0
fi

# Check for arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Run main function only if script is executed directly (not sourced)
# Simple and reliable check that works with any path
if [ "${0##*/}" = "opendaq-version-parse.sh" ] || [ "${0##*/}" = "opendaq-version-parse" ]; then
    parse_version_main "$@"
fi
