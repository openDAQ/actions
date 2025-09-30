#!/bin/bash
################################################################################
# Module: common (testing framework core)
# Version: 1.0.1
# Description: Common utilities and state management for openDAQ test framework
#
# Usage:
#   source core/common.sh
#   daq_testing_common_init
#
# Dependencies: none
# Exit codes: N/A (library only)
################################################################################

# set -euo pipefail

# # Zsh compatibility
# if [ -n "$ZSH_VERSION" ]; then
#     setopt SH_WORD_SPLIT
#     setopt KSH_ARRAYS
# fi

################################################################################
# SCRIPT METADATA
################################################################################

readonly DAQ_TESTING_COMMON_VERSION="1.0.1"
readonly DAQ_TESTING_COMMON_BUILD_DATE="2025-01-15"

################################################################################
# GLOBAL STATE - Test Counters
################################################################################
# Public variables exported for access by other modules and test suites

OPENDAQ_TEST_TOTAL=0
OPENDAQ_TEST_PASSED=0
OPENDAQ_TEST_FAILED=0
OPENDAQ_TEST_SKIPPED=0

################################################################################
# GLOBAL STATE - Current Context
################################################################################
# Private variables for internal framework use

__DAQ_TESTING_CURRENT_SUITE=""
__DAQ_TESTING_SCRIPT_PATH=""
__DAQ_TESTING_VERBOSE=false
__DAQ_TESTING_DEBUG=false
__DAQ_TESTING_CURRENT_TEST_FAILED=false  # Tracks if current test has failed

################################################################################
# GLOBAL STATE - Color Output
################################################################################
# Private variables for terminal color codes (internal use only)

__DAQ_TESTING_COLOR_RED=""
__DAQ_TESTING_COLOR_GREEN=""
__DAQ_TESTING_COLOR_YELLOW=""
__DAQ_TESTING_COLOR_BLUE=""
__DAQ_TESTING_COLOR_RESET=""

# Public color variables (exported after init for use by other modules)
DAQ_TESTING_COLOR_RED=""
DAQ_TESTING_COLOR_GREEN=""
DAQ_TESTING_COLOR_YELLOW=""
DAQ_TESTING_COLOR_BLUE=""
DAQ_TESTING_COLOR_RESET=""

################################################################################
# PRIVATE FUNCTIONS - Color Setup
################################################################################

# Setup terminal colors if supported
# Returns: 0 always
__daq_testing_common_setup_colors() {
    # Check if output is to terminal and tput is available
    if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
        __DAQ_TESTING_COLOR_RED=$(tput setaf 1)
        __DAQ_TESTING_COLOR_GREEN=$(tput setaf 2)
        __DAQ_TESTING_COLOR_YELLOW=$(tput setaf 3)
        __DAQ_TESTING_COLOR_BLUE=$(tput setaf 4)
        __DAQ_TESTING_COLOR_RESET=$(tput sgr0)
    else
        __DAQ_TESTING_COLOR_RED=""
        __DAQ_TESTING_COLOR_GREEN=""
        __DAQ_TESTING_COLOR_YELLOW=""
        __DAQ_TESTING_COLOR_BLUE=""
        __DAQ_TESTING_COLOR_RESET=""
    fi
    
    return 0
}

################################################################################
# PUBLIC API - Initialization
################################################################################

# Initialize test framework common state
# Args: $1 - script path (path to script being tested)
#       $2 - suite name (name of test suite)
#       $3 - verbose flag (optional, "true" or "false", default: false)
#       $4 - debug flag (optional, "true" or "false", default: false)
# Sets: Global state variables
# Returns: 0 on success, 1 on error
daq_testing_common_init() {
    local script_path="$1"
    local suite_name="$2"
    local verbose="${3:-false}"
    local debug="${4:-false}"
    
    # Validate required arguments
    if [ -z "$script_path" ]; then
        echo "ERROR: Script path is required" >&2
        return 1
    fi
    
    if [ -z "$suite_name" ]; then
        echo "ERROR: Suite name is required" >&2
        return 1
    fi
    
    # Set context
    __DAQ_TESTING_SCRIPT_PATH="$script_path"
    __DAQ_TESTING_CURRENT_SUITE="$suite_name"
    __DAQ_TESTING_VERBOSE="$verbose"
    __DAQ_TESTING_DEBUG="$debug"
    
    # Reset counters
    OPENDAQ_TEST_TOTAL=0
    OPENDAQ_TEST_PASSED=0
    OPENDAQ_TEST_FAILED=0
    
    # Setup colors
    __daq_testing_common_setup_colors
    
    # Export color variables for use by other modules
    export DAQ_TESTING_COLOR_RED="$__DAQ_TESTING_COLOR_RED"
    export DAQ_TESTING_COLOR_GREEN="$__DAQ_TESTING_COLOR_GREEN"
    export DAQ_TESTING_COLOR_YELLOW="$__DAQ_TESTING_COLOR_YELLOW"
    export DAQ_TESTING_COLOR_BLUE="$__DAQ_TESTING_COLOR_BLUE"
    export DAQ_TESTING_COLOR_RESET="$__DAQ_TESTING_COLOR_RESET"
    
    # Verify script exists and is executable
    if [ ! -f "$script_path" ]; then
        echo "${__DAQ_TESTING_COLOR_RED}ERROR: Script not found at $script_path${__DAQ_TESTING_COLOR_RESET}" >&2
        echo "Please ensure the script exists or use correct path" >&2
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        echo "${__DAQ_TESTING_COLOR_YELLOW}WARNING: Script is not executable, making it executable...${__DAQ_TESTING_COLOR_RESET}" >&2
        chmod +x "$script_path" || {
            echo "${__DAQ_TESTING_COLOR_RED}ERROR: Failed to make script executable${__DAQ_TESTING_COLOR_RESET}" >&2
            return 1
        }
    fi
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Initialized - script=$script_path, suite=$suite_name" >&2
    fi
    
    return 0
}

################################################################################
# PUBLIC API - State Management
################################################################################

# Reset test counters (for running multiple suites)
# Returns: 0 always
daq_testing_common_reset() {
    OPENDAQ_TEST_TOTAL=0
    OPENDAQ_TEST_PASSED=0
    OPENDAQ_TEST_FAILED=0
    OPENDAQ_TEST_SKIPPED=0
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Counters reset" >&2
    fi
    
    return 0
}

# Get current test results
# Returns: Space-separated string "total passed failed"
daq_testing_common_get_results() {
    echo "$OPENDAQ_TEST_TOTAL $OPENDAQ_TEST_PASSED $OPENDAQ_TEST_FAILED $OPENDAQ_TEST_SKIPPED"
}

# Get current suite name
# Returns: Current suite name
daq_testing_common_get_suite() {
    echo "$__DAQ_TESTING_CURRENT_SUITE"
}

# Get script path being tested
# Returns: Script path
daq_testing_common_get_script_path() {
    echo "$__DAQ_TESTING_SCRIPT_PATH"
}

# Check if verbose mode is enabled
# Returns: 0 if verbose, 1 if not
daq_testing_common_is_verbose() {
    [ "$__DAQ_TESTING_VERBOSE" = "true" ]
}

# Check if debug mode is enabled
# Returns: 0 if debug, 1 if not
daq_testing_common_is_debug() {
    [ "$__DAQ_TESTING_DEBUG" = "true" ]
}

################################################################################
# PUBLIC API - Counter Manipulation
################################################################################

# Increment total test counter
# Returns: 0 always
daq_testing_common_increment_total() {
    OPENDAQ_TEST_TOTAL=$((OPENDAQ_TEST_TOTAL + 1))
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Total tests: $OPENDAQ_TEST_TOTAL" >&2
    fi
    
    return 0
}

# Increment passed test counter
# Returns: 0 always
daq_testing_common_increment_passed() {
    OPENDAQ_TEST_PASSED=$((OPENDAQ_TEST_PASSED + 1))
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Passed tests: $OPENDAQ_TEST_PASSED" >&2
    fi
    
    return 0
}

# Increment failed test counter
# Returns: 0 always
daq_testing_common_increment_failed() {
    OPENDAQ_TEST_FAILED=$((OPENDAQ_TEST_FAILED + 1))
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Failed tests: $OPENDAQ_TEST_FAILED" >&2
    fi
    
    return 0
}

# Increment skipped test counter
# Returns: 0 always
daq_testing_common_increment_skipped() {
    OPENDAQ_TEST_SKIPPED=$((OPENDAQ_TEST_SKIPPED + 1))
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Skipped tests: $OPENDAQ_TEST_SKIPPED" >&2
    fi
    
    return 0
}

################################################################################
# PUBLIC API - Test State Management
################################################################################

# Mark current test as failed
# Returns: 0 always
daq_testing_common_mark_test_failed() {
    __DAQ_TESTING_CURRENT_TEST_FAILED=true
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Current test marked as failed" >&2
    fi
    
    return 0
}

# Reset test failed flag (called before each test)
# Returns: 0 always
daq_testing_common_reset_test_state() {
    __DAQ_TESTING_CURRENT_TEST_FAILED=false
    
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: Test state reset" >&2
    fi
    
    return 0
}

# Check if current test has failed
# Returns: 0 if failed, 1 if not failed
daq_testing_common_is_test_failed() {
    [ "$__DAQ_TESTING_CURRENT_TEST_FAILED" = "true" ]
}

################################################################################
# PUBLIC API - Logging Utilities
################################################################################

# Log debug message (if debug mode enabled)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_common_log_debug() {
    if [ "$__DAQ_TESTING_DEBUG" = "true" ]; then
        echo "[DEBUG] common: $*" >&2
    fi
    return 0
}

# Log verbose message (if verbose mode enabled)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_common_log_verbose() {
    if [ "$__DAQ_TESTING_VERBOSE" = "true" ]; then
        echo "[VERBOSE] common: $*" >&2
    fi
    return 0
}

# Log info message (always)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_common_log_info() {
    echo "[INFO] common: $*" >&2
    return 0
}

# Log warning message (always)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_common_log_warning() {
    echo "[WARNING] common: $*" >&2
    return 0
}

# Log error message (always)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_common_log_error() {
    echo "[ERROR] common: $*" >&2
    return 0
}

################################################################################
# END OF MODULE
################################################################################
