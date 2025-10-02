#!/bin/bash
################################################################################
# Module: version-format (core layer)
# Version: 1.0.0
# Description: Version string manipulation tool for openDAQ
#
# Usage:
#   CLI:     version-format <COMMAND> [OPTIONS]
#   Library: source version-format.sh && daq_version_*
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
# INTERNAL LOGGING FUNCTIONS
################################################################################

# Logging flags (can be overridden by environment or logger integration)
__DAQ_VERSION_VERBOSE=${OPENDAQ_VERBOSE:-false}
__DAQ_VERSION_DEBUG=${OPENDAQ_DEBUG:-false}

# Logging functions output to stdout/stderr

__daq_version_log_verbose() {
    if [ "$__DAQ_VERSION_VERBOSE" = "true" ]; then
        echo "[VERBOSE] version-format: $*" >&2
    fi
}

__daq_version_log_debug() {
    if [ "$__DAQ_VERSION_DEBUG" = "true" ]; then
        echo "[DEBUG] version-format: $*" >&2
    fi
}

__daq_version_log_info() {
    echo "[INFO] version-format: $*" >&2
}

__daq_version_log_warning() {
    echo "[WARNING] version-format: $*" >&2
}

__daq_version_log_error() {
    echo "[ERROR] version-format: $*" >&2
}

################################################################################
# SCRIPT METADATA
################################################################################

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="version-format"
readonly SCRIPT_BUILD_DATE="2025-01-15"

################################################################################
# CONSTANTS - Configuration
################################################################################

readonly OPENDAQ_VERSION_CONFIG_DEFAULT_PREFIX="v"
readonly OPENDAQ_VERSION_CONFIG_DEFAULT_SUFFIX="rc"
readonly OPENDAQ_VERSION_CONFIG_DEFAULT_FORMAT="vX.YY.Z"

################################################################################
# CONSTANTS - Format Templates
################################################################################

readonly __DAQ_VERSION_ALL_FORMATS="X.YY.Z vX.YY.Z X.YY.Z-rc vX.YY.Z-rc X.YY.Z-HASH vX.YY.Z-HASH X.YY.Z-rc-HASH vX.YY.Z-rc-HASH X.YY.Z-<suffix> vX.YY.Z-<suffix> X.YY.Z-<suffix>-HASH vX.YY.Z-<suffix>-HASH"

################################################################################
# CONSTANTS - Version Types
################################################################################

readonly __DAQ_VERSION_ALL_TYPES="release rc dev rc-dev custom custom-dev"

################################################################################
# CONSTANTS - Validation Regex
################################################################################

# Main version string regex
# This regex is designed to properly distinguish between suffix and hash:
# - Suffix can contain letters, numbers, and hyphens but is more flexible
# - Hash must be only lowercase hexadecimal (0-9a-f)
# The key is that hash group comes last and is more restrictive
readonly __DAQ_VERSION_REGEX="^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9-]+)?(-[0-9a-f]+)?$"

# Component validation regex
readonly __DAQ_VERSION_VALID_PREFIX_REGEX="^[^0-9.]+$"
readonly __DAQ_VERSION_VALID_SUFFIX_REGEX="^[a-zA-Z0-9-]+$"
readonly __DAQ_VERSION_VALID_HASH_REGEX="^[0-9a-f]+$"
readonly __DAQ_VERSION_VALID_NUMBER_REGEX="^[0-9]+$"

################################################################################
# HELP SYSTEM - Short Help
################################################################################

readonly __DAQ_VERSION_EXAMPLE_MAJOR=1
readonly __DAQ_VERSION_EXAMPLE_MINOR=40
readonly __DAQ_VERSION_EXAMPLE_PATCH=9
readonly __DAQ_VERSION_EXAMPLE_HASH="a1b2c3f4"

readonly __DAQ_VERSION_EXAMPLE_X_YY_Z="${__DAQ_VERSION_EXAMPLE_MAJOR}.${__DAQ_VERSION_EXAMPLE_MINOR}.${__DAQ_VERSION_EXAMPLE_PATCH}"
readonly __DAQ_VERSION_EXAMPLE_X_YY_Z_RC="$__DAQ_VERSION_EXAMPLE_X_YY_Z-rc"
readonly __DAQ_VERSION_EXAMPLE_X_YY_Z_HASH="$__DAQ_VERSION_EXAMPLE_X_YY_Z-$__DAQ_VERSION_EXAMPLE_HASH"
readonly __DAQ_VERSION_EXAMPLE_X_YY_Z_RC_HASH="$__DAQ_VERSION_EXAMPLE_X_YY_Z_RC-$__DAQ_VERSION_EXAMPLE_HASH"

readonly __DAQ_VERSION_EXAMPLE_vX_YY_Z="v$__DAQ_VERSION_EXAMPLE_X_YY_Z_RC"
readonly __DAQ_VERSION_EXAMPLE_vX_YY_Z_RC="v$__DAQ_VERSION_EXAMPLE_X_YY_Z"
readonly __DAQ_VERSION_EXAMPLE_vX_YY_Z_HASH="v$__DAQ_VERSION_EXAMPLE_X_YY_Z_HASH"
readonly __DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH="v$__DAQ_VERSION_EXAMPLE_X_YY_Z_RC_HASH"

__daq_version_help_short() {
    cat << EOF
version-format - Version string manipulation tool for openDAQ

USAGE:
  version-format <COMMAND> [OPTIONS]
  version-format <VERSION> --detect-type|--detect-format
  version-format --help|-h|--version|-v

COMMANDS:
  validate <VERSION>        Validate version string
  parse <VERSION>           Parse version into components
  compose                   Compose version from components
  extract <TEXT>            Extract version from text

QUERIES:
  --list-formats            List all supported format templates
  --list-types              List all supported version types
  --default-format          Show default format template
  --default-prefix          Show default prefix
  --default-suffix          Show default suffix

DETECTION:
  <VERSION> --detect-type   Detect version type
  <VERSION> --detect-format Detect version format template

GLOBAL OPTIONS:
  --help, -h                Show detailed help
  --version, -v             Show script version
  --verbose                 Enable verbose output
  --debug, -d               Enable debug output

EXAMPLES:
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}
  version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH} --major --type
  version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --suffix rc
  version-format ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --detect-type

For detailed help on a command:
  version-format <COMMAND> --help

EOF
}

################################################################################
# HELP SYSTEM - Full Help
################################################################################

__daq_version_help() {
    cat << EOF
version-format - Version string manipulation tool for openDAQ

DESCRIPTION:
  A comprehensive tool for parsing, validating, composing, and extracting
  version strings. Supports multiple version formats including releases,
  release candidates, development versions, and custom suffixes.

USAGE:
  version-format <COMMAND> [OPTIONS]
  version-format <VERSION> --detect-type|--detect-format
  version-format --help|-h|--version|-v

═══════════════════════════════════════════════════════════════════════════
COMMANDS
═══════════════════════════════════════════════════════════════════════════

validate <VERSION> [OPTIONS]
  Validate version string against format or type rules

  OPTIONS:
    --format <TEMPLATE>     Validate against specific format template
    --type <TYPE>           Validate against version type
    --is-release            Check if version is a release
    --is-rc                 Check if version is RC (suffix="rc", no hash)
    --is-dev                Check if version is dev (no suffix, has hash)
    --is-rc-dev             Check if version is RC dev (suffix="rc", has hash)
    --is-custom             Check if version has custom suffix, no hash
    --is-custom-dev         Check if version has custom suffix and hash
    --has-prefix            Check if version has prefix
    --has-suffix            Check if version has suffix
    --has-hash              Check if version has hash

  EXAMPLES:
    version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --format vX.YY.Z
    version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --is-rc
    version-format validate ${__DAQ_VERSION_EXAMPLE_X_YY_Z_HASH} --has-hash

parse <VERSION> [OPTIONS]
  Parse version string into components

  OPTIONS:
    --major                 Extract major version
    --minor                 Extract minor version
    --patch                 Extract patch version
    --prefix                Extract prefix (empty if none)
    --suffix                Extract suffix (empty if none)
    --hash                  Extract hash (empty if none)
    --type                  Extract version type
    --format                Extract format template

  OUTPUT RULES:
    No flags:       All components in KEY=VALUE format
    One flag:       Value only (no KEY=)
    Multiple flags: KEY=VALUE for each requested component

  EXAMPLES:
    version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}
    version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --major
    version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --major --type

compose [OPTIONS]
  Compose version string from components

  OPTIONS:
    --major <N>             Major version (required)
    --minor <N>             Minor version (required)
    --patch <N>             Patch version (required)
    --prefix <VALUE>        Set prefix (default: v)
    --prefix-exclude        Exclude prefix
    --no-prefix             Same as --prefix-exclude
    --suffix <VALUE>        Set suffix (default: none)
    --suffix-exclude        Exclude suffix
    --no-suffix             Same as --suffix-exclude
    --hash <HASH>           Set hash
    --format <TEMPLATE>     Use specific format template
    --type <TYPE>           Use format for specific type
    --from-env              Read from OPENDAQ_VERSION_COMPOSED_* variables

  FORMAT PRIORITY:
    1. --format <TEMPLATE>  (highest)
    2. --type <TYPE>
    3. Auto-detect from flags
    4. Default format       (lowest)

  EXAMPLES:
    version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH}
                           --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH}
    version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --suffix rc
    version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --format X.YY.Z-HASH --hash ${OPENDAQ_VERSION_PARSED_HASH}
    version-format compose --from-env

extract <TEXT> [OPTIONS]
  Extract version string from text

  OPTIONS:
    --verbose               Show detailed extraction info

  EXAMPLES:
    version-format extract "Release ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} is ready"
    echo "opendaq-${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC}" | version-format extract -

═══════════════════════════════════════════════════════════════════════════
QUERY COMMANDS
═══════════════════════════════════════════════════════════════════════════

--list-formats [OPTIONS]
  List all supported format templates

  OPTIONS:
    --prefix-only           Show only formats with prefix
    --prefix-exclude        Show only formats without prefix
    --verbose               Show detailed format information

--list-types [OPTIONS]
  List all supported version types

  OPTIONS:
    --verbose               Show detailed type information

--default-format
  Show default format template (vX.YY.Z)

--default-prefix
  Show default prefix (v)

--default-suffix
  Show default suffix (rc)

═══════════════════════════════════════════════════════════════════════════
DETECTION COMMANDS
═══════════════════════════════════════════════════════════════════════════

<VERSION> --detect-type
  Detect and return version type

  TYPES:
    release      No suffix, no hash
    rc           suffix="rc", no hash
    dev          No suffix, has hash
    rc-dev       suffix="rc", has hash
    custom       suffix!="rc", no hash
    custom-dev   suffix!="rc", has hash

  EXAMPLE:
    version-format ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --detect-type
    # Output: rc

<VERSION> --detect-format
  Detect and return format template

  EXAMPLE:
    version-format ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH} --detect-format
    # Output: vX.YY.Z-rc-HASH

═══════════════════════════════════════════════════════════════════════════
SUPPORTED FORMATS
═══════════════════════════════════════════════════════════════════════════

  X.YY.Z                    Release without prefix
  vX.YY.Z                   Release with prefix (default)
  X.YY.Z-rc                 Release candidate without prefix
  vX.YY.Z-rc                Release candidate with prefix
  X.YY.Z-HASH               Development version without prefix
  vX.YY.Z-HASH              Development version with prefix
  X.YY.Z-rc-HASH            RC with commits, no prefix
  vX.YY.Z-rc-HASH           RC with commits, with prefix
  X.YY.Z-<suffix>           Custom suffix without prefix
  vX.YY.Z-<suffix>          Custom suffix with prefix
  X.YY.Z-<suffix>-HASH      Custom suffix with hash, no prefix
  vX.YY.Z-<suffix>-HASH     Custom suffix with hash, with prefix

═══════════════════════════════════════════════════════════════════════════
ENVIRONMENT VARIABLES
═══════════════════════════════════════════════════════════════════════════

PARSED (set by parse command, read-only):
  OPENDAQ_VERSION_PARSED_MAJOR
  OPENDAQ_VERSION_PARSED_MINOR
  OPENDAQ_VERSION_PARSED_PATCH
  OPENDAQ_VERSION_PARSED_PREFIX
  OPENDAQ_VERSION_PARSED_SUFFIX
  OPENDAQ_VERSION_PARSED_HASH
  OPENDAQ_VERSION_PARSED_TYPE
  OPENDAQ_VERSION_PARSED_FORMAT

COMPOSED (set by user, read by compose --from-env):
  OPENDAQ_VERSION_COMPOSED_MAJOR      (required)
  OPENDAQ_VERSION_COMPOSED_MINOR      (required)
  OPENDAQ_VERSION_COMPOSED_PATCH      (required)
  OPENDAQ_VERSION_COMPOSED_PREFIX     (optional, default: v)
  OPENDAQ_VERSION_COMPOSED_SUFFIX     (optional, default: empty)
  OPENDAQ_VERSION_COMPOSED_HASH       (optional, default: empty)
  OPENDAQ_VERSION_COMPOSED_FORMAT     (optional)
  OPENDAQ_VERSION_COMPOSED_TYPE       (optional)

CONFIG (script constants, read-only):
  OPENDAQ_VERSION_CONFIG_DEFAULT_PREFIX=v
  OPENDAQ_VERSION_CONFIG_DEFAULT_SUFFIX=rc
  OPENDAQ_VERSION_CONFIG_DEFAULT_FORMAT=vX.YY.Z

═══════════════════════════════════════════════════════════════════════════
VALIDATION RULES
═══════════════════════════════════════════════════════════════════════════

Prefix: Must not start with digit or contain dots
  Valid:   v, ver, version-, release-, V
  Invalid: 3, 1.0, ver.

Suffix: Alphanumeric and hyphens only
  Valid:   rc, beta, alpha, rc1, beta-2
  Invalid: rc.1, beta_2, "pre release"

Hash: Lowercase hexadecimal only
  Valid:   abc123f, 1a2b3c4d
  Invalid: ABC123F, xyz, 123-456

Version components: Non-negative integers
  Valid:   0, 1, 42, 314
  Invalid: -1, 3.14, 1a

═══════════════════════════════════════════════════════════════════════════
EXAMPLES
═══════════════════════════════════════════════════════════════════════════

# Parse and extract components
version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}
version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --major
version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --major --minor --type

# Validate versions
version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}
version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --is-rc
version-format validate ${__DAQ_VERSION_EXAMPLE_X_YY_Z_HASH} --has-hash

# Compose versions
version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH}
version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --suffix rc --hash ${OPENDAQ_VERSION_PARSED_HASH}

# Detect type and format
version-format ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --detect-type
version-format ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH} --detect-format

# List available formats and types
version-format --list-formats
version-format --list-types --verbose

# Extract from text
version-format extract "Release ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} is available"
echo "opendaq-${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC}" | version-format extract -

VERSION: $SCRIPT_VERSION
BUILD:   $SCRIPT_BUILD_DATE

EOF
}

################################################################################
# HELP SYSTEM - Validate Command Help
################################################################################

__daq_version_help_validate() {
    cat << EOF
version-format validate - Validate version string

USAGE:
  version-format validate <VERSION> [OPTIONS]

DESCRIPTION:
  Validates a version string against format templates or version types.
  Returns exit code 0 if valid, 1 if invalid.

OPTIONS:
  --format <TEMPLATE>     Validate against specific format template
  --type <TYPE>           Validate against version type
  --is-release            Check if version is a release
  --is-rc                 Check if version is RC (suffix="rc", no hash)
  --is-dev                Check if version is dev (no suffix, has hash)
  --is-rc-dev             Check if version is RC dev (suffix="rc", has hash)
  --is-custom             Check if version has custom suffix, no hash
  --is-custom-dev         Check if version has custom suffix and hash
  --has-prefix            Check if version has prefix
  --has-suffix            Check if version has suffix
  --has-hash              Check if version has hash
  --verbose               Show detailed validation information

EXAMPLES:
  # Basic validation
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}

  # Validate against format
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --format vX.YY.Z

  # Type checks
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --is-rc
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_HASH} --is-dev

  # Component checks
  version-format validate ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --has-prefix
  version-format validate ${__DAQ_VERSION_EXAMPLE_X_YY_Z_RC} --has-suffix

EXIT CODES:
  0 - Version is valid
  1 - Version is invalid
  2 - Invalid arguments

EOF
}

################################################################################
# HELP SYSTEM - Parse Command Help
################################################################################

__daq_version_help_parse() {
    cat << EOF
version-format parse - Parse version string

USAGE:
  version-format parse <VERSION> [OPTIONS]

DESCRIPTION:
  Parses a version string and extracts its components. Can output all
  components or specific requested components.

OPTIONS:
  --major                 Extract major version
  --minor                 Extract minor version
  --patch                 Extract patch version
  --prefix                Extract prefix (empty if none)
  --suffix                Extract suffix (empty if none)
  --hash                  Extract hash (empty if none)
  --type                  Extract version type
  --format                Extract format template
  --verbose               Show detailed parsing information

OUTPUT RULES:
  No flags:       All components in KEY=VALUE format
  One flag:       Value only (no KEY=)
  Multiple flags: KEY=VALUE for each requested component

EXAMPLES:
  # Parse all components
  version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}
  # Output:
  # OPENDAQ_VERSION_PARSED_MAJOR=3
  # OPENDAQ_VERSION_PARSED_MINOR=14
  # OPENDAQ_VERSION_PARSED_PATCH=2
  # OPENDAQ_VERSION_PARSED_PREFIX=v
  # OPENDAQ_VERSION_PARSED_SUFFIX=rc
  # OPENDAQ_VERSION_PARSED_HASH=abc123f
  # OPENDAQ_VERSION_PARSED_TYPE=rc-dev
  # OPENDAQ_VERSION_PARSED_FORMAT=vX.YY.Z-rc-HASH

  # Extract single component (value only)
  version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} --major
  # Output: 3

  # Extract multiple components (KEY=VALUE)
  version-format parse ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC} --major --minor --type
  # Output:
  # OPENDAQ_VERSION_PARSED_MAJOR=3
  # OPENDAQ_VERSION_PARSED_MINOR=14
  # OPENDAQ_VERSION_PARSED_TYPE=rc

EXIT CODES:
  0 - Success
  1 - Parse failed
  2 - Invalid arguments

EOF
}

################################################################################
# HELP SYSTEM - Compose Command Help
################################################################################

__daq_version_help_compose() {
    cat << EOF
version-format compose - Compose version string

USAGE:
  version-format compose [OPTIONS]

DESCRIPTION:
  Composes a version string from individual components. Supports multiple
  format specification methods with a clear priority order.

OPTIONS:
  --major <N>             Major version (required unless --from-env)
  --minor <N>             Minor version (required unless --from-env)
  --patch <N>             Patch version (required unless --from-env)
  --prefix <VALUE>        Set prefix (default: v)
  --prefix-exclude        Exclude prefix
  --no-prefix             Same as --prefix-exclude
  --suffix <VALUE>        Set suffix (default: none)
  --suffix-exclude        Exclude suffix
  --no-suffix             Same as --suffix-exclude
  --hash <HASH>           Set hash
  --format <TEMPLATE>     Use specific format template
  --type <TYPE>           Use format for specific type
  --from-env              Read from OPENDAQ_VERSION_COMPOSED_* variables
  --verbose               Show detailed composition information

FORMAT PRIORITY (highest to lowest):
  1. --format <TEMPLATE>
  2. --type <TYPE>
  3. Auto-detection from flags (--prefix, --suffix, --hash presence)
  4. Default format (vX.YY.Z)

EXAMPLES:
  # Simple release version
  version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH}
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}

  # Release candidate
  version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --suffix rc
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC}

  # Development version with hash
  version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --hash ${OPENDAQ_VERSION_PARSED_HASH}
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_HASH}

  # Custom format
  version-format compose --major ${__DAQ_VERSION_EXAMPLE_MAJOR} --minor ${__DAQ_VERSION_EXAMPLE_MINOR} --patch ${__DAQ_VERSION_EXAMPLE_PATCH} --format X.YY.Z-rc
  # Output: ${__DAQ_VERSION_EXAMPLE_X_YY_Z_RC}

  # From environment variables
  export OPENDAQ_VERSION_COMPOSED_MAJOR=${__DAQ_VERSION_EXAMPLE_MAJOR}
  export OPENDAQ_VERSION_COMPOSED_MINOR=${__DAQ_VERSION_EXAMPLE_MINOR}
  export OPENDAQ_VERSION_COMPOSED_PATCH=${__DAQ_VERSION_EXAMPLE_PATCH}
  export OPENDAQ_VERSION_COMPOSED_SUFFIX=rc
  version-format compose --from-env
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC}

EXIT CODES:
  0 - Success
  1 - Composition failed
  2 - Invalid arguments

EOF
}

################################################################################
# HELP SYSTEM - Extract Command Help
################################################################################

__daq_version_help_extract() {
    cat << EOF
version-format extract - Extract version from text

USAGE:
  version-format extract <TEXT> [OPTIONS]
  version-format extract - [OPTIONS]    (read from stdin)

DESCRIPTION:
  Extracts the first valid version string from text. Useful for parsing
  output from other commands or extracting versions from file names.

OPTIONS:
  --verbose               Show detailed extraction information

EXAMPLES:
  # Extract from string
  version-format extract "Release ${__DAQ_VERSION_EXAMPLE_vX_YY_Z} is available"
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}

  # Extract from stdin
  echo "opendaq-${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}.tar.gz" | version-format extract -
  # Output: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}

  # With verbose output
  version-format extract "Version: ${__DAQ_VERSION_EXAMPLE_vX_YY_Z}" --verbose

EXIT CODES:
  0 - Version found and extracted
  1 - No version found
  2 - Invalid arguments

EOF
}

################################################################################
# HELP SYSTEM - Error: Usage
################################################################################

__daq_version_error_usage() {
    local message="$1"
    
    echo "ERROR: $message" >&2
    echo "" >&2
    echo "Try 'version-format --help' for more information." >&2
    
    return 2
}

################################################################################
# HELP SYSTEM - Error: Missing Environment Variables
################################################################################

__daq_version_error_missing_env() {
    local missing_vars="$1"
    
    cat >&2 << EOF
ERROR: Missing required environment variables for compose --from-env

Required variables:
  OPENDAQ_VERSION_COMPOSED_MAJOR
  OPENDAQ_VERSION_COMPOSED_MINOR
  OPENDAQ_VERSION_COMPOSED_PATCH

Missing: $missing_vars

Optional variables:
  OPENDAQ_VERSION_COMPOSED_PREFIX     (default: v)
  OPENDAQ_VERSION_COMPOSED_SUFFIX     (default: empty)
  OPENDAQ_VERSION_COMPOSED_HASH       (default: empty)
  OPENDAQ_VERSION_COMPOSED_FORMAT     (default: auto-detect)
  OPENDAQ_VERSION_COMPOSED_TYPE       (default: auto-detect)

EOF
    
    return 1
}

################################################################################
# PRIVATE FUNCTIONS - Component Validation
################################################################################

# Validate if string is a valid prefix
# Args: $1 - prefix string
# Returns: 0 if valid, 1 if invalid
__daq_version_is_valid_prefix() {
    local prefix="$1"
    
    if [ -z "$prefix" ]; then
        return 0  # Empty prefix is valid
    fi
    
    if echo "$prefix" | grep -Eq "$__DAQ_VERSION_VALID_PREFIX_REGEX"; then
        return 0
    else
        return 1
    fi
}

# Validate if string is a valid suffix
# Args: $1 - suffix string
# Returns: 0 if valid, 1 if invalid
__daq_version_is_valid_suffix() {
    local suffix="$1"
    
    if [ -z "$suffix" ]; then
        return 0  # Empty suffix is valid
    fi
    
    if echo "$suffix" | grep -Eq "$__DAQ_VERSION_VALID_SUFFIX_REGEX"; then
        return 0
    else
        return 1
    fi
}

# Validate if string is a valid hash
# Args: $1 - hash string
# Returns: 0 if valid, 1 if invalid
__daq_version_is_valid_hash() {
    local hash="$1"
    
    if [ -z "$hash" ]; then
        return 0  # Empty hash is valid
    fi
    
    if echo "$hash" | grep -Eq "$__DAQ_VERSION_VALID_HASH_REGEX"; then
        return 0
    else
        return 1
    fi
}

# Validate if string is a valid version number
# Args: $1 - number string
# Returns: 0 if valid, 1 if invalid
__daq_version_is_valid_number() {
    local number="$1"
    
    if echo "$number" | grep -Eq "$__DAQ_VERSION_VALID_NUMBER_REGEX"; then
        return 0
    else
        return 1
    fi
}

################################################################################
# PRIVATE FUNCTIONS - Format Analysis
################################################################################

# Check if format template has prefix
# Args: $1 - format template
# Returns: 0 if has prefix, 1 if not
__daq_version_format_has_prefix() {
    local template="$1"
    
    case "$template" in
        v*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if format template has suffix
# Args: $1 - format template
# Returns: 0 if has suffix, 1 if not
__daq_version_format_has_suffix() {
    local template="$1"
    
    case "$template" in
        *-rc*|*-\<suffix\>*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check if format template has hash
# Args: $1 - format template
# Returns: 0 if has hash, 1 if not
__daq_version_format_has_hash() {
    local template="$1"
    
    case "$template" in
        *-HASH)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get suffix from format template
# Args: $1 - format template
# Returns: suffix value or "<suffix>" or empty
__daq_version_format_get_suffix() {
    local template="$1"
    
    # Extract suffix part between X.YY.Z- and -HASH or end
    case "$template" in
        *-rc-HASH)
            echo "rc"
            ;;
        *-rc)
            echo "rc"
            ;;
        *-\<suffix\>-HASH)
            echo "<suffix>"
            ;;
        *-\<suffix\>)
            echo "<suffix>"
            ;;
        *)
            echo ""
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - Type Detection
################################################################################

# Detect version type from parsed components
# Args: $1 - suffix (may be empty)
#       $2 - hash (may be empty)
# Returns: version type string
__daq_version_detect_type() {
    local suffix="$1"
    local hash="$2"
    
    local has_hash=false
    local has_suffix=false
    
    [ -n "$hash" ] && has_hash=true
    [ -n "$suffix" ] && has_suffix=true
    
    __daq_version_log_debug "Type detection: suffix='$suffix', hash='$hash', has_suffix=$has_suffix, has_hash=$has_hash"
    
    # Decision tree for type detection
    if [ "$has_hash" = "true" ]; then
        if [ "$has_suffix" = "true" ]; then
            if [ "$suffix" = "rc" ]; then
                echo "rc-dev"
            else
                echo "custom-dev"
            fi
        else
            echo "dev"
        fi
    else
        if [ "$has_suffix" = "true" ]; then
            if [ "$suffix" = "rc" ]; then
                echo "rc"
            else
                echo "custom"
            fi
        else
            echo "release"
        fi
    fi
}

# Detect format template from parsed components
# Args: $1 - prefix (may be empty)
#       $2 - suffix (may be empty)
#       $3 - hash (may be empty)
# Returns: format template string
__daq_version_detect_format() {
    local prefix="$1"
    local suffix="$2"
    local hash="$3"
    
    local format=""
    
    # Start with base
    if [ -n "$prefix" ]; then
        format="vX.YY.Z"
    else
        format="X.YY.Z"
    fi
    
    # Add suffix
    if [ -n "$suffix" ]; then
        if [ "$suffix" = "rc" ]; then
            format="${format}-rc"
        else
            format="${format}-<suffix>"
        fi
    fi
    
    # Add hash
    if [ -n "$hash" ]; then
        format="${format}-HASH"
    fi
    
    __daq_version_log_debug "Format detection: prefix='$prefix', suffix='$suffix', hash='$hash' -> format='$format'"
    
    echo "$format"
}

################################################################################
# PRIVATE FUNCTIONS - Version Parsing
################################################################################

# Parse version string into components
# Args: $1 - version string
# Sets global variables: __PARSED_PREFIX, __PARSED_MAJOR, __PARSED_MINOR, 
#                        __PARSED_PATCH, __PARSED_SUFFIX, __PARSED_HASH
# Returns: 0 on success, 1 on failure
__daq_version_parse_components() {
    local version="$1"
    
    __daq_version_log_debug "Parsing version: $version"
    
    # Match against main regex
    local match_line
    match_line=$(echo "$version" | grep -E "$__DAQ_VERSION_REGEX")
    
    if [ -z "$match_line" ]; then
        __daq_version_log_error "Version string does not match expected format: $version"
        return 1
    fi
    
    # Extract components using sed
    __PARSED_PREFIX=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\1/")
    __PARSED_MAJOR=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\2/")
    __PARSED_MINOR=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\3/")
    __PARSED_PATCH=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\4/")
    
    # Extract suffix and hash (groups 5 and 6)
    local suffix_part
    local hash_part
    suffix_part=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\5/")
    hash_part=$(echo "$version" | sed -E "s/$__DAQ_VERSION_REGEX/\6/")
    
    # Clean up suffix (remove leading dash)
    if [ -n "$suffix_part" ]; then
        suffix_part="${suffix_part#-}"
    fi
    
    # Clean up hash (remove leading dash)
    if [ -n "$hash_part" ]; then
        hash_part="${hash_part#-}"
    fi
    
    # Smart detection: if we have suffix_part but no hash_part,
    # check if suffix_part is actually a hash (only hex characters)
    if [ -n "$suffix_part" ] && [ -z "$hash_part" ]; then
        # Check if suffix_part looks like a hash (only 0-9a-f)
        if echo "$suffix_part" | grep -Eq "^[0-9a-f]+$"; then
            # Additional check: real hashes are usually at least 6 characters
            # If it's shorter, it's probably part of a suffix like "beta-1"
            local suffix_len=${#suffix_part}
            if [ $suffix_len -ge 6 ]; then
                # It's a hash, not a suffix
                __PARSED_SUFFIX=""
                __PARSED_HASH="$suffix_part"
                __daq_version_log_debug "Detected hash in suffix position: $suffix_part"
            else
                # Too short to be a hash, treat as suffix
                __PARSED_SUFFIX="$suffix_part"
                __PARSED_HASH=""
                __daq_version_log_debug "Short hex string treated as suffix: $suffix_part"
            fi
        else
            # Check if it contains a hash at the end (e.g., "rc-abc123f")
            # Split by last dash to see if we have suffix-hash pattern
            if echo "$suffix_part" | grep -q "-"; then
                local potential_suffix="${suffix_part%-*}"
                local potential_hash="${suffix_part##*-}"
                
                # Check if potential_hash is hex AND long enough to be a real hash
                if echo "$potential_hash" | grep -Eq "^[0-9a-f]+$" && [ ${#potential_hash} -ge 6 ]; then
                    # Yes, it's suffix-hash
                    __PARSED_SUFFIX="$potential_suffix"
                    __PARSED_HASH="$potential_hash"
                    __daq_version_log_debug "Split into suffix='$potential_suffix' and hash='$potential_hash'"
                else
                    # No, it's just a suffix (maybe with numbers like "beta-1")
                    __PARSED_SUFFIX="$suffix_part"
                    __PARSED_HASH=""
                    __daq_version_log_debug "Composite suffix (no valid hash): $suffix_part"
                fi
            else
                # No dash, just a suffix
                __PARSED_SUFFIX="$suffix_part"
                __PARSED_HASH=""
            fi
        fi
    else
        __PARSED_SUFFIX="$suffix_part"
        __PARSED_HASH="$hash_part"
    fi
    
    __daq_version_log_debug "Parsed components: prefix='$__PARSED_PREFIX', major='$__PARSED_MAJOR', minor='$__PARSED_MINOR', patch='$__PARSED_PATCH', suffix='$__PARSED_SUFFIX', hash='$__PARSED_HASH'"
    
    # Validate components
    if ! __daq_version_is_valid_number "$__PARSED_MAJOR"; then
        __daq_version_log_error "Invalid major version: $__PARSED_MAJOR"
        return 1
    fi
    
    if ! __daq_version_is_valid_number "$__PARSED_MINOR"; then
        __daq_version_log_error "Invalid minor version: $__PARSED_MINOR"
        return 1
    fi
    
    if ! __daq_version_is_valid_number "$__PARSED_PATCH"; then
        __daq_version_log_error "Invalid patch version: $__PARSED_PATCH"
        return 1
    fi
    
    if ! __daq_version_is_valid_prefix "$__PARSED_PREFIX"; then
        __daq_version_log_error "Invalid prefix: $__PARSED_PREFIX"
        return 1
    fi
    
    if ! __daq_version_is_valid_suffix "$__PARSED_SUFFIX"; then
        __daq_version_log_error "Invalid suffix: $__PARSED_SUFFIX"
        return 1
    fi
    
    if ! __daq_version_is_valid_hash "$__PARSED_HASH"; then
        __daq_version_log_error "Invalid hash: $__PARSED_HASH"
        return 1
    fi
    
    return 0
}

# Extract version string from text
# Args: $1 - text to search
# Returns: first found version string or empty
__daq_version_extract_from_text() {
    local text="$1"
    
    __daq_version_log_debug "Extracting version from text: ${text:0:100}..."
    
    # Try to find version pattern in text
    # We need a simpler regex for grep -oE that captures the whole version
    # The full regex with groups doesn't work well with grep -oE
    local extracted
    extracted=$(echo "$text" | grep -oE "(v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9-]+)?(-[0-9a-f]+)?)" | head -n 1)
    
    if [ -n "$extracted" ]; then
        # Verify it's a valid version by trying to parse it
        if __daq_version_parse_components "$extracted" 2>/dev/null; then
            __daq_version_log_debug "Extracted version: $extracted"
            echo "$extracted"
            return 0
        else
            __daq_version_log_debug "Found text matching pattern but not valid version: $extracted"
            return 1
        fi
    else
        __daq_version_log_debug "No version found in text"
        return 1
    fi
}

################################################################################
# PRIVATE FUNCTIONS - Format Matching
################################################################################

# Match version against format template
# Args: $1 - version string
#       $2 - format template
# Returns: 0 if matches, 1 if not
__daq_version_match_format() {
    local version="$1"
    local template="$2"
    
    __daq_version_log_debug "Matching version '$version' against format '$template'"
    
    # Parse the version
    if ! __daq_version_parse_components "$version"; then
        return 1
    fi
    
    local expected_prefix=""
    local expected_suffix=""
    local expected_hash=""
    
    # Determine what the template expects
    if __daq_version_format_has_prefix "$template"; then
        expected_prefix="required"
    else
        expected_prefix="excluded"
    fi
    
    if __daq_version_format_has_suffix "$template"; then
        expected_suffix="required"
        local template_suffix
        template_suffix=$(__daq_version_format_get_suffix "$template")
        
        # If template specifies "rc", suffix must be "rc"
        # If template specifies "<suffix>", suffix must be non-empty and not "rc"
        if [ "$template_suffix" = "rc" ]; then
            if [ "$__PARSED_SUFFIX" != "rc" ]; then
                __daq_version_log_debug "Format mismatch: expected suffix 'rc', got '$__PARSED_SUFFIX'"
                return 1
            fi
        elif [ "$template_suffix" = "<suffix>" ]; then
            if [ -z "$__PARSED_SUFFIX" ] || [ "$__PARSED_SUFFIX" = "rc" ]; then
                __daq_version_log_debug "Format mismatch: expected custom suffix, got '$__PARSED_SUFFIX'"
                return 1
            fi
        fi
    else
        expected_suffix="excluded"
    fi
    
    if __daq_version_format_has_hash "$template"; then
        expected_hash="required"
    else
        expected_hash="excluded"
    fi
    
    # Check prefix
    if [ "$expected_prefix" = "required" ] && [ -z "$__PARSED_PREFIX" ]; then
        __daq_version_log_debug "Format mismatch: prefix required but missing"
        return 1
    fi
    
    if [ "$expected_prefix" = "excluded" ] && [ -n "$__PARSED_PREFIX" ]; then
        __daq_version_log_debug "Format mismatch: prefix excluded but present: '$__PARSED_PREFIX'"
        return 1
    fi
    
    # Check suffix
    if [ "$expected_suffix" = "required" ] && [ -z "$__PARSED_SUFFIX" ]; then
        __daq_version_log_debug "Format mismatch: suffix required but missing"
        return 1
    fi
    
    if [ "$expected_suffix" = "excluded" ] && [ -n "$__PARSED_SUFFIX" ]; then
        __daq_version_log_debug "Format mismatch: suffix excluded but present: '$__PARSED_SUFFIX'"
        return 1
    fi
    
    # Check hash
    if [ "$expected_hash" = "required" ] && [ -z "$__PARSED_HASH" ]; then
        __daq_version_log_debug "Format mismatch: hash required but missing"
        return 1
    fi
    
    if [ "$expected_hash" = "excluded" ] && [ -n "$__PARSED_HASH" ]; then
        __daq_version_log_debug "Format mismatch: hash excluded but present: '$__PARSED_HASH'"
        return 1
    fi
    
    __daq_version_log_debug "Format match successful"
    return 0
}

# Match version against type
# Args: $1 - version string
#       $2 - type (release|rc|dev|rc-dev|custom|custom-dev)
# Returns: 0 if matches, 1 if not
__daq_version_match_type() {
    local version="$1"
    local expected_type="$2"
    
    __daq_version_log_debug "Matching version '$version' against type '$expected_type'"
    
    # Parse the version
    if ! __daq_version_parse_components "$version"; then
        return 1
    fi
    
    # Detect actual type
    local actual_type
    actual_type=$(__daq_version_detect_type "$__PARSED_SUFFIX" "$__PARSED_HASH")
    
    if [ "$actual_type" = "$expected_type" ]; then
        __daq_version_log_debug "Type match successful: $actual_type"
        return 0
    else
        __daq_version_log_debug "Type mismatch: expected '$expected_type', got '$actual_type'"
        return 1
    fi
}

################################################################################
# PRIVATE FUNCTIONS - Format Inference
################################################################################

# Infer format template from compose flags
# Args: $1 - prefix (may be empty or "EXCLUDE")
#       $2 - suffix (may be empty or "EXCLUDE")
#       $3 - hash (may be empty)
# Returns: inferred format template
__daq_version_infer_format() {
    local prefix="$1"
    local suffix="$2"
    local hash="$3"
    
    local format=""
    
    # Determine prefix part
    if [ "$prefix" = "EXCLUDE" ] || [ "$prefix" = "" ]; then
        format="X.YY.Z"
    else
        format="vX.YY.Z"
    fi
    
    # Determine suffix part
    if [ "$suffix" = "EXCLUDE" ]; then
        # No suffix
        :
    elif [ -n "$suffix" ]; then
        if [ "$suffix" = "rc" ]; then
            format="${format}-rc"
        else
            format="${format}-<suffix>"
        fi
    fi
    
    # Determine hash part
    if [ -n "$hash" ]; then
        format="${format}-HASH"
    fi
    
    __daq_version_log_debug "Inferred format from flags: prefix='$prefix', suffix='$suffix', hash='$hash' -> '$format'"
    
    echo "$format"
}

# Convert type to default format template
# Args: $1 - type (release|rc|dev|rc-dev|custom|custom-dev)
# Returns: format template
__daq_version_type_to_format() {
    local type="$1"
    
    case "$type" in
        release)
            echo "vX.YY.Z"
            ;;
        rc)
            echo "vX.YY.Z-rc"
            ;;
        dev)
            echo "vX.YY.Z-HASH"
            ;;
        rc-dev)
            echo "vX.YY.Z-rc-HASH"
            ;;
        custom)
            echo "vX.YY.Z-<suffix>"
            ;;
        custom-dev)
            echo "vX.YY.Z-<suffix>-HASH"
            ;;
        *)
            __daq_version_log_error "Unknown type: $type"
            echo "vX.YY.Z"
            ;;
    esac
}

################################################################################
# PRIVATE FUNCTIONS - Version Composition
################################################################################

# Compose version string from components and format
# Args: $1 - major
#       $2 - minor
#       $3 - patch
#       $4 - format template
#       $5 - prefix value (optional, may be empty)
#       $6 - suffix value (optional, may be empty)
#       $7 - hash value (optional, may be empty)
# Returns: composed version string
__daq_version_compose_string() {
    local major="$1"
    local minor="$2"
    local patch="$3"
    local template="$4"
    local prefix_val="${5:-}"
    local suffix_val="${6:-}"
    local hash_val="${7:-}"
    
    __daq_version_log_debug "Composing version: major=$major, minor=$minor, patch=$patch, template=$template, prefix='$prefix_val', suffix='$suffix_val', hash='$hash_val'"
    
    # Validate numeric components
    if ! __daq_version_is_valid_number "$major"; then
        __daq_version_log_error "Invalid major version: $major"
        return 1
    fi
    
    if ! __daq_version_is_valid_number "$minor"; then
        __daq_version_log_error "Invalid minor version: $minor"
        return 1
    fi
    
    if ! __daq_version_is_valid_number "$patch"; then
        __daq_version_log_error "Invalid patch version: $patch"
        return 1
    fi
    
    local version=""
    
    # Add prefix if required by format
    if __daq_version_format_has_prefix "$template"; then
        if [ -z "$prefix_val" ]; then
            prefix_val="$OPENDAQ_VERSION_CONFIG_DEFAULT_PREFIX"
        fi
        
        if ! __daq_version_is_valid_prefix "$prefix_val"; then
            __daq_version_log_error "Invalid prefix: $prefix_val"
            return 1
        fi
        
        version="$prefix_val"
    fi
    
    # Add version numbers
    version="${version}${major}.${minor}.${patch}"
    
    # Add suffix if required by format
    if __daq_version_format_has_suffix "$template"; then
        local template_suffix
        template_suffix=$(__daq_version_format_get_suffix "$template")
        
        if [ "$template_suffix" = "rc" ]; then
            # Format specifies RC
            suffix_val="rc"
        elif [ "$template_suffix" = "<suffix>" ]; then
            # Format allows custom suffix
            if [ -z "$suffix_val" ]; then
                __daq_version_log_error "Format requires custom suffix but none provided"
                return 1
            fi
        fi
        
        if [ -z "$suffix_val" ]; then
            suffix_val="$OPENDAQ_VERSION_CONFIG_DEFAULT_SUFFIX"
        fi
        
        if ! __daq_version_is_valid_suffix "$suffix_val"; then
            __daq_version_log_error "Invalid suffix: $suffix_val"
            return 1
        fi
        
        version="${version}-${suffix_val}"
    fi
    
    # Add hash if required by format
    if __daq_version_format_has_hash "$template"; then
        if [ -z "$hash_val" ]; then
            __daq_version_log_error "Format requires hash but none provided"
            return 1
        fi
        
        if ! __daq_version_is_valid_hash "$hash_val"; then
            __daq_version_log_error "Invalid hash: $hash_val"
            return 1
        fi
        
        version="${version}-${hash_val}"
    fi
    
    __daq_version_log_debug "Composed version: $version"
    echo "$version"
}

################################################################################
# PUBLIC API - Format Queries
################################################################################

# Get default format template
# Returns: default format string
daq_version_format_default() {
    echo "$OPENDAQ_VERSION_CONFIG_DEFAULT_FORMAT"
}

# Get default prefix
# Returns: default prefix string
daq_version_prefix_default() {
    echo "$OPENDAQ_VERSION_CONFIG_DEFAULT_PREFIX"
}

# Get default suffix
# Returns: default suffix string
daq_version_suffix_default() {
    echo "$OPENDAQ_VERSION_CONFIG_DEFAULT_SUFFIX"
}

# List all supported format templates
# Args: $1 - verbose flag (optional, "verbose" for detailed output)
#       $2 - filter (optional, "prefix-only" or "prefix-exclude")
# Returns: list of formats
daq_version_format_list() {
    local verbose=false
    local filter=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            verbose|--verbose)
                verbose=true
                shift
                ;;
            prefix-only|--prefix-only)
                filter="prefix-only"
                shift
                ;;
            prefix-exclude|--prefix-exclude)
                filter="prefix-exclude"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    __daq_version_log_debug "Listing formats: verbose=$verbose, filter='$filter'"
    
    # Iterate through all formats
    for format in $__DAQ_VERSION_ALL_FORMATS; do
        # Apply filter
        if [ "$filter" = "prefix-only" ]; then
            if ! __daq_version_format_has_prefix "$format"; then
                continue
            fi
        elif [ "$filter" = "prefix-exclude" ]; then
            if __daq_version_format_has_prefix "$format"; then
                continue
            fi
        fi
        
        if [ "$verbose" = "true" ]; then
            # Detailed output
            local desc=""
            local has_prefix="no"
            local has_suffix="no"
            local has_hash="no"
            
            __daq_version_format_has_prefix "$format" && has_prefix="yes"
            __daq_version_format_has_suffix "$format" && has_suffix="yes"
            __daq_version_format_has_hash "$format" && has_hash="yes"
            
            # Build description
            case "$format" in
                "X.YY.Z")
                    desc="Release without prefix"
                    ;;
                "vX.YY.Z")
                    desc="Release with prefix (default)"
                    ;;
                "X.YY.Z-rc")
                    desc="Release candidate without prefix"
                    ;;
                "vX.YY.Z-rc")
                    desc="Release candidate with prefix"
                    ;;
                "X.YY.Z-HASH")
                    desc="Development version without prefix"
                    ;;
                "vX.YY.Z-HASH")
                    desc="Development version with prefix"
                    ;;
                "X.YY.Z-rc-HASH")
                    desc="RC with commits, no prefix"
                    ;;
                "vX.YY.Z-rc-HASH")
                    desc="RC with commits, with prefix"
                    ;;
                "X.YY.Z-<suffix>")
                    desc="Custom suffix without prefix"
                    ;;
                "vX.YY.Z-<suffix>")
                    desc="Custom suffix with prefix"
                    ;;
                "X.YY.Z-<suffix>-HASH")
                    desc="Custom suffix with hash, no prefix"
                    ;;
                "vX.YY.Z-<suffix>-HASH")
                    desc="Custom suffix with hash, with prefix"
                    ;;
                *)
                    desc="Unknown format"
                    ;;
            esac
            
            printf "%-25s prefix=%-3s suffix=%-3s hash=%-3s  %s\n" \
                   "$format" "$has_prefix" "$has_suffix" "$has_hash" "$desc"
        else
            # Simple output
            echo "$format"
        fi
    done
}

# List all supported version types
# Args: $1 - verbose flag (optional, "verbose" for detailed output)
# Returns: list of types
daq_version_type_list() {
    local verbose=false
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            verbose|--verbose)
                verbose=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    __daq_version_log_debug "Listing types: verbose=$verbose"
    
    # Iterate through all types
    for type in $__DAQ_VERSION_ALL_TYPES; do
        if [ "$verbose" = "true" ]; then
            # Detailed output
            local desc=""
            local example=""
            
            case "$type" in
                release)
                    desc="Release version (no suffix, no hash)"
                    example="${__DAQ_VERSION_EXAMPLE_vX_YY_Z}"
                    ;;
                rc)
                    desc="Release candidate (suffix='rc', no hash)"
                    example="${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC}"
                    ;;
                dev)
                    desc="Development version (no suffix, has hash)"
                    example="${__DAQ_VERSION_EXAMPLE_vX_YY_Z_HASH}"
                    ;;
                rc-dev)
                    desc="RC with commits (suffix='rc', has hash)"
                    example="${__DAQ_VERSION_EXAMPLE_vX_YY_Z_RC_HASH}"
                    ;;
                custom)
                    desc="Custom suffix (suffix!='rc', no hash)"
                    example="$__DAQ_VERSION_EXAMPLE_vX_YY_Z-beta"
                    ;;
                custom-dev)
                    desc="Custom suffix with hash (suffix!='rc', has hash)"
                    example="$__DAQ_VERSION_EXAMPLE_vX_YY_Z-beta-${__DAQ_VERSION_EXAMPLE_HASH}"
                    ;;
                *)
                    desc="Unknown type"
                    example="N/A"
                    ;;
            esac
            
            printf "%-12s %-50s Example: %s\n" "$type" "$desc" "$example"
        else
            # Simple output
            echo "$type"
        fi
    done
}

################################################################################
# PUBLIC API - Detection
################################################################################

# Detect version type
# Args: $1 - version string
# Returns: type string (release|rc|dev|rc-dev|custom|custom-dev)
daq_version_detect_type() {
    local version="$1"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    # Parse the version
    if ! __daq_version_parse_components "$version"; then
        return 1
    fi
    
    # Detect and return type
    __daq_version_detect_type "$__PARSED_SUFFIX" "$__PARSED_HASH"
}

# Detect version format template
# Args: $1 - version string
# Returns: format template string
daq_version_detect_format() {
    local version="$1"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    # Parse the version
    if ! __daq_version_parse_components "$version"; then
        return 1
    fi
    
    # Detect and return format
    __daq_version_detect_format "$__PARSED_PREFIX" "$__PARSED_SUFFIX" "$__PARSED_HASH"
}

################################################################################
# PUBLIC API - Validation
################################################################################

# Validate version string (basic validation)
# Args: $1 - version string
#       $2 - format template (optional, if provided will validate against it)
# Returns: 0 if valid, 1 if invalid
daq_version_validate() {
    local version="$1"
    local format="${2:-}"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    __daq_version_log_debug "Validating version: $version (format: ${format:-auto})"
    
    # Parse the version (basic validation)
    if ! __daq_version_parse_components "$version"; then
        __daq_version_log_error "Version validation failed: invalid format"
        return 1
    fi
    
    # If format specified, validate against it
    if [ -n "$format" ]; then
        if ! __daq_version_match_format "$version" "$format"; then
            __daq_version_log_error "Version does not match format: $format"
            return 1
        fi
    fi
    
    __daq_version_log_verbose "Version is valid: $version"
    return 0
}

# Validate version against format template (strict)
# Args: $1 - version string
#       $2 - format template (required)
# Returns: 0 if valid, 1 if invalid
daq_version_validate_format() {
    local version="$1"
    local format="$2"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    if [ -z "$format" ]; then
        __daq_version_log_error "Format template is required"
        return 1
    fi
    
    __daq_version_log_debug "Validating version '$version' against format '$format'"
    
    if __daq_version_match_format "$version" "$format"; then
        __daq_version_log_verbose "Version matches format: $version -> $format"
        return 0
    else
        __daq_version_log_error "Version does not match format: $version -> $format"
        return 1
    fi
}

# Validate version against type (strict)
# Args: $1 - version string
#       $2 - type (required: release|rc|dev|rc-dev|custom|custom-dev)
# Returns: 0 if valid, 1 if invalid
daq_version_validate_type() {
    local version="$1"
    local type="$2"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    if [ -z "$type" ]; then
        __daq_version_log_error "Type is required"
        return 1
    fi
    
    __daq_version_log_debug "Validating version '$version' against type '$type'"
    
    if __daq_version_match_type "$version" "$type"; then
        __daq_version_log_verbose "Version matches type: $version -> $type"
        return 0
    else
        __daq_version_log_error "Version does not match type: $version -> $type"
        return 1
    fi
}

################################################################################
# PUBLIC API - Parse
################################################################################

# Parse version string and set environment variables
# Args: $1 - version string
# Sets: OPENDAQ_VERSION_PARSED_* environment variables
# Returns: 0 on success, 1 on failure
daq_version_parse() {
    local version="$1"
    
    if [ -z "$version" ]; then
        __daq_version_log_error "Version string is required"
        return 1
    fi
    
    # Parse components
    if ! __daq_version_parse_components "$version"; then
        return 1
    fi
    
    # Detect type and format
    local detected_type
    local detected_format
    detected_type=$(__daq_version_detect_type "$__PARSED_SUFFIX" "$__PARSED_HASH")
    detected_format=$(__daq_version_detect_format "$__PARSED_PREFIX" "$__PARSED_SUFFIX" "$__PARSED_HASH")
    
    # Set environment variables
    export OPENDAQ_VERSION_PARSED_MAJOR="$__PARSED_MAJOR"
    export OPENDAQ_VERSION_PARSED_MINOR="$__PARSED_MINOR"
    export OPENDAQ_VERSION_PARSED_PATCH="$__PARSED_PATCH"
    export OPENDAQ_VERSION_PARSED_PREFIX="$__PARSED_PREFIX"
    export OPENDAQ_VERSION_PARSED_SUFFIX="$__PARSED_SUFFIX"
    export OPENDAQ_VERSION_PARSED_HASH="$__PARSED_HASH"
    export OPENDAQ_VERSION_PARSED_TYPE="$detected_type"
    export OPENDAQ_VERSION_PARSED_FORMAT="$detected_format"
    
    __daq_version_log_verbose "Parsed version: $version -> type=$detected_type, format=$detected_format"
    
    return 0
}

# Get specific parameter from last parsed version
# Args: $1 - parameter name (major|minor|patch|prefix|suffix|hash|type|format)
# Returns: parameter value
daq_version_get_parameter() {
    local param="$1"
    
    case "$param" in
        major)
            echo "${OPENDAQ_VERSION_PARSED_MAJOR:-}"
            ;;
        minor)
            echo "${OPENDAQ_VERSION_PARSED_MINOR:-}"
            ;;
        patch)
            echo "${OPENDAQ_VERSION_PARSED_PATCH:-}"
            ;;
        prefix)
            echo "${OPENDAQ_VERSION_PARSED_PREFIX:-}"
            ;;
        suffix)
            echo "${OPENDAQ_VERSION_PARSED_SUFFIX:-}"
            ;;
        hash)
            echo "${OPENDAQ_VERSION_PARSED_HASH:-}"
            ;;
        type)
            echo "${OPENDAQ_VERSION_PARSED_TYPE:-}"
            ;;
        format)
            echo "${OPENDAQ_VERSION_PARSED_FORMAT:-}"
            ;;
        *)
            __daq_version_log_error "Unknown parameter: $param"
            return 1
            ;;
    esac
}

# Get detected type from last parsed version
# Returns: version type
daq_version_get_type() {
    echo "${OPENDAQ_VERSION_PARSED_TYPE:-}"
}

################################################################################
# PUBLIC API - Extract
################################################################################

# Extract version from text
# Args: $1 - text to search
# Returns: extracted version string or empty
daq_version_extract() {
    local text="$1"
    
    if [ -z "$text" ]; then
        __daq_version_log_error "Text is required"
        return 1
    fi
    
    __daq_version_extract_from_text "$text"
}

################################################################################
# PUBLIC API - Compose
################################################################################

# Compose version string from components
# Args: Various options (see help)
# Returns: composed version string
daq_version_compose() {
    local major=""
    local minor=""
    local patch=""
    local prefix=""
    local suffix=""
    local hash=""
    local explicit_format=""
    local explicit_type=""
    local use_env=false
    local prefix_exclude=false
    local suffix_exclude=false
    
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
            --prefix)
                prefix="$2"
                shift 2
                ;;
            --prefix-exclude|--no-prefix)
                prefix_exclude=true
                shift
                ;;
            --suffix)
                suffix="$2"
                shift 2
                ;;
            --suffix-exclude|--no-suffix)
                suffix_exclude=true
                shift
                ;;
            --hash)
                hash="$2"
                shift 2
                ;;
            --format)
                explicit_format="$2"
                shift 2
                ;;
            --type)
                explicit_type="$2"
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
                __daq_version_log_warning "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # If using environment variables
    if [ "$use_env" = "true" ]; then
        major="${OPENDAQ_VERSION_COMPOSED_MAJOR:-}"
        minor="${OPENDAQ_VERSION_COMPOSED_MINOR:-}"
        patch="${OPENDAQ_VERSION_COMPOSED_PATCH:-}"
        prefix="${OPENDAQ_VERSION_COMPOSED_PREFIX:-}"
        suffix="${OPENDAQ_VERSION_COMPOSED_SUFFIX:-}"
        hash="${OPENDAQ_VERSION_COMPOSED_HASH:-}"
        explicit_format="${OPENDAQ_VERSION_COMPOSED_FORMAT:-}"
        explicit_type="${OPENDAQ_VERSION_COMPOSED_TYPE:-}"
    fi
    
    # Validate required components
    if [ -z "$major" ] || [ -z "$minor" ] || [ -z "$patch" ]; then
        __daq_version_log_error "Major, minor, and patch versions are required"
        return 1
    fi
    
    # Determine format with priority
    local final_format=""
    
    if [ -n "$explicit_format" ]; then
        # Priority 1: Explicit format
        final_format="$explicit_format"
        __daq_version_log_debug "Using explicit format: $final_format"
    elif [ -n "$explicit_type" ]; then
        # Priority 2: Type
        final_format=$(__daq_version_type_to_format "$explicit_type")
        __daq_version_log_debug "Using format from type '$explicit_type': $final_format"
    else
        # Priority 3: Auto-detect from flags
        local infer_prefix=""
        local infer_suffix=""
        local infer_hash=""
        
        if [ "$prefix_exclude" = "true" ]; then
            infer_prefix="EXCLUDE"
        else
            infer_prefix="${prefix:-v}"
        fi
        
        if [ "$suffix_exclude" = "true" ]; then
            infer_suffix="EXCLUDE"
        else
            infer_suffix="$suffix"
        fi
        
        infer_hash="$hash"
        
        final_format=$(__daq_version_infer_format "$infer_prefix" "$infer_suffix" "$infer_hash")
        __daq_version_log_debug "Auto-detected format: $final_format"
    fi
    
    # Handle prefix exclusion
    if [ "$prefix_exclude" = "true" ]; then
        prefix=""
    fi
    
    # Handle suffix exclusion
    if [ "$suffix_exclude" = "true" ]; then
        suffix=""
    fi
    
    # Compose version string
    __daq_version_compose_string "$major" "$minor" "$patch" "$final_format" "$prefix" "$suffix" "$hash"
}

# Compose version from environment variables
# Returns: composed version string
daq_version_compose_from_env() {
    # Check required variables
    local missing=""
    [ -z "${OPENDAQ_VERSION_COMPOSED_MAJOR:-}" ] && missing="${missing}OPENDAQ_VERSION_COMPOSED_MAJOR "
    [ -z "${OPENDAQ_VERSION_COMPOSED_MINOR:-}" ] && missing="${missing}OPENDAQ_VERSION_COMPOSED_MINOR "
    [ -z "${OPENDAQ_VERSION_COMPOSED_PATCH:-}" ] && missing="${missing}OPENDAQ_VERSION_COMPOSED_PATCH "
    
    if [ -n "$missing" ]; then
        __daq_version_error_missing_env "$missing"
        return 1
    fi
    
    daq_version_compose --from-env
}

################################################################################
# CLI INTERFACE
################################################################################

# Main CLI entry point
# Only execute if script is run directly (not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then

    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        __daq_version_help_short
        exit 0
    fi

    # Parse global flags first
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                __daq_version_help
                exit 0
                ;;
            --version|-v)
                echo "version-format v$SCRIPT_VERSION (build: $SCRIPT_BUILD_DATE)"
                exit 0
                ;;
            --verbose)
                __DAQ_VERSION_VERBOSE=true
                export OPENDAQ_VERBOSE=true
                shift
                ;;
            --debug|-d)
                __DAQ_VERSION_DEBUG=true
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
        __daq_version_help_short
        exit 0
    fi

    # Get command or version string
    COMMAND="$1"
    shift

    ################################################################################
    # CLI COMMAND: Query Commands
    ################################################################################

    case "$COMMAND" in
        --list-formats)
            # Parse options
            VERBOSE_FLAG=""
            FILTER_FLAG=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        VERBOSE_FLAG="verbose"
                        shift
                        ;;
                    --prefix-only)
                        FILTER_FLAG="prefix-only"
                        shift
                        ;;
                    --prefix-exclude)
                        FILTER_FLAG="prefix-exclude"
                        shift
                        ;;
                    *)
                        __daq_version_error_usage "Unknown option for --list-formats: $1"
                        exit 2
                        ;;
                esac
            done
            daq_version_format_list $VERBOSE_FLAG $FILTER_FLAG
            exit 0
            ;;

        --list-types)
            # Parse options
            VERBOSE_FLAG=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --verbose)
                        VERBOSE_FLAG="verbose"
                        shift
                        ;;
                    *)
                        __daq_version_error_usage "Unknown option for --list-types: $1"
                        exit 2
                        ;;
                esac
            done
            daq_version_type_list $VERBOSE_FLAG
            exit 0
            ;;

        --default-format)
            daq_version_format_default
            exit 0
            ;;

        --default-prefix)
            daq_version_prefix_default
            exit 0
            ;;

        --default-suffix)
            daq_version_suffix_default
            exit 0
            ;;

    ################################################################################
    # CLI COMMAND: validate
    ################################################################################

        validate)
            if [ $# -eq 0 ]; then
                __daq_version_help_validate
                exit 2
            fi

            VERSION="$1"
            shift

            # Check for help
            if [ "$VERSION" = "--help" ] || [ "$VERSION" = "-h" ]; then
                __daq_version_help_validate
                exit 0
            fi

            # Parse validation options
            VALIDATE_FORMAT=""
            VALIDATE_TYPE=""
            CHECK_TYPE=""
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    --format)
                        VALIDATE_FORMAT="$2"
                        shift 2
                        ;;
                    --type)
                        VALIDATE_TYPE="$2"
                        shift 2
                        ;;
                    --is-release)
                        CHECK_TYPE="release"
                        shift
                        ;;
                    --is-rc)
                        CHECK_TYPE="rc"
                        shift
                        ;;
                    --is-dev)
                        CHECK_TYPE="dev"
                        shift
                        ;;
                    --is-rc-dev)
                        CHECK_TYPE="rc-dev"
                        shift
                        ;;
                    --is-custom)
                        CHECK_TYPE="custom"
                        shift
                        ;;
                    --is-custom-dev)
                        CHECK_TYPE="custom-dev"
                        shift
                        ;;
                    --has-prefix)
                        if ! __daq_version_parse_components "$VERSION"; then
                            exit 1
                        fi
                        if [ -n "$__PARSED_PREFIX" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --has-suffix)
                        if ! __daq_version_parse_components "$VERSION"; then
                            exit 1
                        fi
                        if [ -n "$__PARSED_SUFFIX" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --has-hash)
                        if ! __daq_version_parse_components "$VERSION"; then
                            exit 1
                        fi
                        if [ -n "$__PARSED_HASH" ]; then
                            exit 0
                        else
                            exit 1
                        fi
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_version_error_usage "Unknown option for validate: $1"
                        exit 2
                        ;;
                esac
            done

            # Perform validation
            if [ -n "$VALIDATE_FORMAT" ]; then
                daq_version_validate_format "$VERSION" "$VALIDATE_FORMAT"
                exit $?
            elif [ -n "$VALIDATE_TYPE" ]; then
                daq_version_validate_type "$VERSION" "$VALIDATE_TYPE"
                exit $?
            elif [ -n "$CHECK_TYPE" ]; then
                daq_version_validate_type "$VERSION" "$CHECK_TYPE"
                exit $?
            else
                # Basic validation
                daq_version_validate "$VERSION"
                exit $?
            fi
            ;;

    ################################################################################
    # CLI COMMAND: parse
    ################################################################################

        parse)
            if [ $# -eq 0 ]; then
                __daq_version_help_parse
                exit 2
            fi

            VERSION="$1"
            shift

            # Check for help
            if [ "$VERSION" = "--help" ] || [ "$VERSION" = "-h" ]; then
                __daq_version_help_parse
                exit 0
            fi

            # Parse the version first
            if ! daq_version_parse "$VERSION"; then
                exit 1
            fi

            # Collect requested components
            REQUESTED_COMPONENTS=()
            while [ $# -gt 0 ]; do
                case "$1" in
                    --major)
                        REQUESTED_COMPONENTS+=("major")
                        shift
                        ;;
                    --minor)
                        REQUESTED_COMPONENTS+=("minor")
                        shift
                        ;;
                    --patch)
                        REQUESTED_COMPONENTS+=("patch")
                        shift
                        ;;
                    --prefix)
                        REQUESTED_COMPONENTS+=("prefix")
                        shift
                        ;;
                    --suffix)
                        REQUESTED_COMPONENTS+=("suffix")
                        shift
                        ;;
                    --hash)
                        REQUESTED_COMPONENTS+=("hash")
                        shift
                        ;;
                    --type)
                        REQUESTED_COMPONENTS+=("type")
                        shift
                        ;;
                    --format)
                        REQUESTED_COMPONENTS+=("format")
                        shift
                        ;;
                    --verbose)
                        shift
                        ;;
                    *)
                        __daq_version_error_usage "Unknown option for parse: $1"
                        exit 2
                        ;;
                esac
            done

            # Output based on number of requested components
            COMPONENT_COUNT=${#REQUESTED_COMPONENTS[@]}

            if [ $COMPONENT_COUNT -eq 0 ]; then
                # Output all components in KEY=VALUE format
                echo "OPENDAQ_VERSION_PARSED_MAJOR=$OPENDAQ_VERSION_PARSED_MAJOR"
                echo "OPENDAQ_VERSION_PARSED_MINOR=$OPENDAQ_VERSION_PARSED_MINOR"
                echo "OPENDAQ_VERSION_PARSED_PATCH=$OPENDAQ_VERSION_PARSED_PATCH"
                echo "OPENDAQ_VERSION_PARSED_PREFIX=$OPENDAQ_VERSION_PARSED_PREFIX"
                echo "OPENDAQ_VERSION_PARSED_SUFFIX=$OPENDAQ_VERSION_PARSED_SUFFIX"
                echo "OPENDAQ_VERSION_PARSED_HASH=$OPENDAQ_VERSION_PARSED_HASH"
                echo "OPENDAQ_VERSION_PARSED_TYPE=$OPENDAQ_VERSION_PARSED_TYPE"
                echo "OPENDAQ_VERSION_PARSED_FORMAT=$OPENDAQ_VERSION_PARSED_FORMAT"
            elif [ $COMPONENT_COUNT -eq 1 ]; then
                # Output single value only (no KEY=)
                PARAM="${REQUESTED_COMPONENTS[0]}"
                daq_version_get_parameter "$PARAM"
            else
                # Output multiple KEY=VALUE pairs
                for PARAM in "${REQUESTED_COMPONENTS[@]}"; do
                    VALUE=$(daq_version_get_parameter "$PARAM")
                    PARAM_UPPER=$(echo "$PARAM" | tr '[:lower:]' '[:upper:]')
                    echo "OPENDAQ_VERSION_PARSED_${PARAM_UPPER}=$VALUE"
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
                __daq_version_help_compose
                exit 0
            fi

            # Call compose function with all arguments
            COMPOSED=$(daq_version_compose "$@")
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "$COMPOSED"
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
                __daq_version_help_extract
                exit 2
            fi

            TEXT="$1"
            shift

            # Check for help
            if [ "$TEXT" = "--help" ] || [ "$TEXT" = "-h" ]; then
                __daq_version_help_extract
                exit 0
            fi

            # Read from stdin if TEXT is "-"
            if [ "$TEXT" = "-" ]; then
                TEXT=$(cat)
            fi

            # Extract version
            EXTRACTED=$(daq_version_extract "$TEXT")
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "$EXTRACTED"
                exit 0
            else
                __daq_version_log_error "No version found in text"
                exit 1
            fi
            ;;

    ################################################################################
    # CLI COMMAND: Detection (version string with flags)
    ################################################################################

        *)
            # Check if COMMAND looks like a version string
            if echo "$COMMAND" | grep -Eq "$__DAQ_VERSION_REGEX"; then
                VERSION="$COMMAND"
                
                # Parse detection flags
                if [ $# -eq 0 ]; then
                    __daq_version_error_usage "Version string provided but no action specified"
                    exit 2
                fi

                case "$1" in
                    --detect-type)
                        DETECTED=$(daq_version_detect_type "$VERSION")
                        EXIT_CODE=$?
                        if [ $EXIT_CODE -eq 0 ]; then
                            echo "$DETECTED"
                            exit 0
                        else
                            exit $EXIT_CODE
                        fi
                        ;;
                    --detect-format)
                        DETECTED=$(daq_version_detect_format "$VERSION")
                        EXIT_CODE=$?
                        if [ $EXIT_CODE -eq 0 ]; then
                            echo "$DETECTED"
                            exit 0
                        else
                            exit $EXIT_CODE
                        fi
                        ;;
                    *)
                        __daq_version_error_usage "Unknown option for version detection: $1"
                        exit 2
                        ;;
                esac
            else
                __daq_version_error_usage "Unknown command: $COMMAND"
                exit 2
            fi
            ;;
    esac

fi

################################################################################
# END OF SCRIPT
################################################################################
