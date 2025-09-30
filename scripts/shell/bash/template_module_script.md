#!/bin/bash
################################################################################
# Module: <module-name> (<layer> layer)
# Version: 1.0.0
# Description: <Brief description>
#
# Usage:
#   CLI:     <module-name> <COMMAND> [OPTIONS]
#   Library: source <module-name>.sh && <prefix>_*
#
# Dependencies: <list or "none">
# Exit codes: 0=success, 1=error, 2=usage error
################################################################################

set -euo pipefail

################################################################################
# DEPENDENCY LOADING
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

__<PREFIX>_VERBOSE=${OPENDAQ_VERBOSE:-false}
__<PREFIX>_DEBUG=${OPENDAQ_DEBUG:-false}

################################################################################
# INTERNAL LOGGING FUNCTIONS
################################################################################
# Standalone stubs - can be overridden by lib/logger.sh if available
# Pattern: __<prefix>_log_<level>
# Usage: __<prefix>_log_debug "Processing: $value"

__<prefix>_log_verbose() {
    [ "$__<PREFIX>_VERBOSE" = "true" ] && echo "[VERBOSE] <module-name>: $*" >&2
}

__<prefix>_log_debug() {
    [ "$__<PREFIX>_DEBUG" = "true" ] && echo "[DEBUG] <module-name>: $*" >&2
}

__<prefix>_log_info() {
    echo "[INFO] <module-name>: $*" >&2
}

__<prefix>_log_warning() {
    echo "[WARNING] <module-name>: $*" >&2
}

__<prefix>_log_error() {
    echo "[ERROR] <module-name>: $*" >&2
}

# Optional logger integration
if [ -f "$SCRIPT_DIR/../lib/logger.sh" ]; then
    source "$SCRIPT_DIR/../lib/logger.sh" 2>/dev/null || true
    if command -v daq_logger_verbose >/dev/null 2>&1; then
        daq_logger_set_context "<module-name>"
        __<prefix>_log_verbose() { daq_logger_verbose "$@"; }
        __<prefix>_log_debug() { daq_logger_debug "$@"; }
        __<prefix>_log_info() { daq_logger_info "$@"; }
        __<prefix>_log_warning() { daq_logger_warning "$@"; }
        __<prefix>_log_error() { daq_logger_error "$@"; }
    fi
fi

################################################################################
# SCRIPT METADATA
################################################################################

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="<module-name>"
readonly SCRIPT_BUILD_DATE="$(date +%Y-%m-%d)"

################################################################################
# CONSTANTS - Configuration
################################################################################
# Pattern: <PREFIX>_CONFIG_<n> for public, __<PREFIX>_<n> for private

readonly <PREFIX>_CONFIG_DEFAULT_<SETTING>="<value>"
readonly __<PREFIX>_ALL_<ITEMS>="<item1> <item2> <item3>"

################################################################################
# CONSTANTS - Validation Regex
################################################################################
# Use POSIX ERE format (grep -E compatible)

readonly __<PREFIX>_REGEX_<ITEM>="^<pattern>$"
readonly __<PREFIX>_VALID_<COMPONENT>_REGEX="^<pattern>$"

################################################################################
# HELP SYSTEM
################################################################################
# Formatting guidelines:
# - Short help: Max 30 lines, basic usage only
# - Full help: Complete docs with section separators (═══)
# - Command help: Specific to one command
# - Use heredoc with 'EOF' (quoted to prevent expansion)

__<prefix>_help_short() {
    cat << 'EOF'
<module-name> - <Brief description>

USAGE:
  <module-name> <COMMAND> [OPTIONS]

COMMANDS:
  <command>                 <Description>

GLOBAL OPTIONS:
  --help, -h                Show detailed help
  --version, -v             Show version
  --verbose                 Verbose output
  --debug, -d               Debug output

EXAMPLES:
  <module-name> <command> <args>

EOF
}

__<prefix>_help() {
    cat << 'EOF'
<module-name> - <Description>

USAGE:
  <module-name> <COMMAND> [OPTIONS]

═══════════════════════════════════════════════════════════════════════════
COMMANDS
═══════════════════════════════════════════════════════════════════════════

<command> <ARGS>
  <Description>

  OPTIONS:
    --option <VALUE>        <Description>

VERSION: $SCRIPT_VERSION
BUILD:   $SCRIPT_BUILD_DATE

EOF
}

__<prefix>_help_<command>() {
    cat << 'EOF'
<module-name> <command> - <Description>

USAGE:
  <module-name> <command> <ARGS> [OPTIONS]

OPTIONS:
  --option <VALUE>          <Description>

EXAMPLES:
  <module-name> <command> <example>

EOF
}

__<prefix>_error_usage() {
    echo "ERROR: $1" >&2
    echo "Try '<module-name> --help' for more information." >&2
    return 2
}

################################################################################
# PRIVATE FUNCTIONS - Validation
################################################################################
# Naming: __<prefix>_is_valid_<item>
# Comment format:
# # Brief description
# # Args: $1 - description
# # Returns: 0 if valid, 1 if invalid

# Validate component
# Args: $1 - component value
# Returns: 0 if valid, 1 if invalid
__<prefix>_is_valid_<component>() {
    # Implementation here
}

################################################################################
# PRIVATE FUNCTIONS - Parsing
################################################################################
# Naming: __<prefix>_parse_<item>
# Comment format:
# # Brief description
# # Args: $1 - input string
# # Sets: __PARSED_<VAR1>, __PARSED_<VAR2>
# # Returns: 0 on success, 1 on failure

# Parse item into components
# Args: $1 - item string
# Sets: __PARSED_<COMP1>, __PARSED_<COMP2>
# Returns: 0 on success, 1 on failure
__<prefix>_parse_<item>() {
    # Implementation here
}

################################################################################
# PRIVATE FUNCTIONS - Detection
################################################################################
# Naming: __<prefix>_detect_<property>
# Comment format:
# # Brief description
# # Args: $1 - input
# # Returns: detected value

# Detect property from components
# Args: $1 - component1
#       $2 - component2
# Returns: detected property value
__<prefix>_detect_<property>() {
    # Implementation here
}

################################################################################
# PRIVATE FUNCTIONS - Processing
################################################################################
# Naming: __<prefix>_process_<data>, __<prefix>_transform_<item>
# Comment format:
# # Brief description
# # Args: $1 - data to process
# # Returns: processed result

# Process data
# Args: $1 - data to process
# Returns: processed result
__<prefix>_process_<data>() {
    # Implementation here
}

################################################################################
# PUBLIC API - Query Functions
################################################################################
# Naming: <prefix>_<item>_default, <prefix>_<item>_list
# Comment format:
# # Brief description
# # Args: $1... - options
# # Returns: result

# Get default setting
# Returns: default value
<prefix>_<item>_default() {
    # Implementation here
}

# List available items
# Args: $1... - options (verbose, filters)
# Returns: list of items
<prefix>_<item>_list() {
    # Implementation here
}

################################################################################
# PUBLIC API - Detection Functions
################################################################################
# Naming: <prefix>_detect_<property>
# Comment format:
# # Brief description
# # Args: $1 - input to analyze
# # Returns: detected property

# Detect property
# Args: $1 - input to analyze
# Returns: detected property
<prefix>_detect_<property>() {
    # Implementation here
}

################################################################################
# PUBLIC API - Validation Functions
################################################################################
# Naming: <prefix>_validate, <prefix>_validate_<criteria>
# Comment format:
# # Brief description
# # Args: $1 - input, $2 - constraint (optional)
# # Returns: 0 if valid, 1 if invalid

# Validate input
# Args: $1 - input to validate
#       $2 - constraint (optional)
# Returns: 0 if valid, 1 if invalid
<prefix>_validate() {
    # Implementation here
}

# Validate against specific criteria
# Args: $1 - input to validate
#       $2 - criteria (required)
# Returns: 0 if valid, 1 if invalid
<prefix>_validate_<criteria>() {
    # Implementation here
}

################################################################################
# PUBLIC API - Parse Functions
################################################################################
# Naming: <prefix>_parse, <prefix>_get_parameter
# Comment format:
# # Brief description
# # Args: $1 - input
# # Sets: <PREFIX>_PARSED_* environment variables
# # Returns: 0 on success, 1 on failure

# Parse input
# Args: $1 - input to parse
# Sets: <PREFIX>_PARSED_* environment variables
# Returns: 0 on success, 1 on failure
<prefix>_parse() {
    # Implementation here
}

# Get parameter from parsed input
# Args: $1 - parameter name
# Returns: parameter value
<prefix>_get_parameter() {
    # Implementation here
}

################################################################################
# PUBLIC API - Main Operations
################################################################################
# Naming: <prefix>_<action>, <prefix>_compose, <prefix>_process
# Comment format:
# # Brief description
# # Args: Various --option flags
# # Returns: result

# Process/compose/build main operation
# Args: Various --option flags
# Returns: result
<prefix>_<action>() {
    # Implementation here
}

################################################################################
# CLI INTERFACE
################################################################################

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then

    # No arguments - show short help
    [ $# -eq 0 ] && { __<prefix>_help_short; exit 0; }

    # Parse global flags
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h) __<prefix>_help; exit 0 ;;
            --version|-v) echo "<module-name> v$SCRIPT_VERSION"; exit 0 ;;
            --verbose) __<PREFIX>_VERBOSE=true; export OPENDAQ_VERBOSE=true; shift ;;
            --debug|-d) __<PREFIX>_DEBUG=true; export OPENDAQ_DEBUG=true; shift ;;
            *) break ;;
        esac
    done

    [ $# -eq 0 ] && { __<prefix>_help_short; exit 0; }

    COMMAND="$1"
    shift

    ############################################################################
    # CLI COMMANDS
    ############################################################################

    case "$COMMAND" in
        --list-<items>)
            # Implementation here
            ;;

        --default-<item>)
            # Implementation here
            ;;

        <command>)
            # Implementation here
            ;;

        *)
            __<prefix>_error_usage "Unknown command: $COMMAND"
            exit 2
            ;;
    esac

fi

################################################################################
# END OF SCRIPT
################################################################################
