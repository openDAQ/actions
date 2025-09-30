#!/bin/bash
################################################################################
# Module: filter (testing framework core)
# Version: 1.0.1
# Description: Test and suite filtering logic for openDAQ test framework
#
# Usage:
#   source core/filter.sh
#   daq_testing_filter_init "suite:test1,test2" "excluded" "regex"
#   daq_testing_filter_should_run "test-name"
#
# Dependencies: core/common.sh (for logging)
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

readonly DAQ_TESTING_FILTER_VERSION="1.0.1"
readonly DAQ_TESTING_FILTER_BUILD_DATE="2025-01-15"

################################################################################
# GLOBAL STATE - Filter Configuration
################################################################################
# Private variables for filter state

__DAQ_TESTING_FILTER_POSITIVE_TESTS=""    # Comma-separated list of tests to include
__DAQ_TESTING_FILTER_EXCLUDED_TESTS=""    # Comma-separated list of tests to exclude
__DAQ_TESTING_FILTER_EXCLUDED_SUITES=""   # Comma-separated list of suites to exclude
__DAQ_TESTING_FILTER_REGEX=""             # Regex pattern for test names
__DAQ_TESTING_FILTER_ENABLED=false        # Whether any filtering is active

################################################################################
# PUBLIC API - Initialization
################################################################################

# Initialize filter configuration
# Args: $1 - positive tests (comma-separated, optional)
#       $2 - excluded tests (comma-separated, optional)
#       $3 - excluded suites (comma-separated, optional)
#       $4 - regex pattern (optional)
# Sets: Filter state variables
# Returns: 0 always
daq_testing_filter_init() {
    local positive_tests="${1:-}"
    local excluded_tests="${2:-}"
    local excluded_suites="${3:-}"
    local regex_pattern="${4:-}"
    
    __DAQ_TESTING_FILTER_POSITIVE_TESTS="$positive_tests"
    __DAQ_TESTING_FILTER_EXCLUDED_TESTS="$excluded_tests"
    __DAQ_TESTING_FILTER_EXCLUDED_SUITES="$excluded_suites"
    __DAQ_TESTING_FILTER_REGEX="$regex_pattern"
    
    # Determine if filtering is enabled
    if [ -n "$positive_tests" ] || [ -n "$excluded_tests" ] || [ -n "$excluded_suites" ] || [ -n "$regex_pattern" ]; then
        __DAQ_TESTING_FILTER_ENABLED=true
    else
        __DAQ_TESTING_FILTER_ENABLED=false
    fi
    
    if daq_testing_common_is_debug; then
        daq_testing_common_log_debug "Filter initialized: enabled=$__DAQ_TESTING_FILTER_ENABLED"
        [ -n "$positive_tests" ] && daq_testing_common_log_debug "  Positive tests: $positive_tests"
        [ -n "$excluded_tests" ] && daq_testing_common_log_debug "  Excluded tests: $excluded_tests"
        [ -n "$excluded_suites" ] && daq_testing_common_log_debug "  Excluded suites: $excluded_suites"
        [ -n "$regex_pattern" ] && daq_testing_common_log_debug "  Regex pattern: $regex_pattern"
    fi
    
    return 0
}

# Reset filter configuration
# Returns: 0 always
daq_testing_filter_reset() {
    __DAQ_TESTING_FILTER_POSITIVE_TESTS=""
    __DAQ_TESTING_FILTER_EXCLUDED_TESTS=""
    __DAQ_TESTING_FILTER_EXCLUDED_SUITES=""
    __DAQ_TESTING_FILTER_REGEX=""
    __DAQ_TESTING_FILTER_ENABLED=false
    
    return 0
}

################################################################################
# PUBLIC API - Filter Status
################################################################################

# Check if filtering is enabled
# Returns: 0 if enabled, 1 if not
daq_testing_filter_is_enabled() {
    [ "$__DAQ_TESTING_FILTER_ENABLED" = "true" ]
}

# Get filtering summary for display
# Returns: Multi-line string describing active filters
daq_testing_filter_get_summary() {
    if [ "$__DAQ_TESTING_FILTER_ENABLED" != "true" ]; then
        echo "No filtering active"
        return 0
    fi
    
    local summary=""
    
    if [ -n "$__DAQ_TESTING_FILTER_POSITIVE_TESTS" ]; then
        summary="${summary}Positive tests: $__DAQ_TESTING_FILTER_POSITIVE_TESTS\n"
    fi
    
    if [ -n "$__DAQ_TESTING_FILTER_EXCLUDED_TESTS" ]; then
        summary="${summary}Excluded tests: $__DAQ_TESTING_FILTER_EXCLUDED_TESTS\n"
    fi
    
    if [ -n "$__DAQ_TESTING_FILTER_EXCLUDED_SUITES" ]; then
        summary="${summary}Excluded suites: $__DAQ_TESTING_FILTER_EXCLUDED_SUITES\n"
    fi
    
    if [ -n "$__DAQ_TESTING_FILTER_REGEX" ]; then
        summary="${summary}Regex filter: $__DAQ_TESTING_FILTER_REGEX\n"
    fi
    
    echo -e "$summary"
}

################################################################################
# PUBLIC API - Suite Filtering
################################################################################

# Check if a suite should be executed (not excluded)
# Args: $1 - suite name
# Returns: 0 if should run, 1 if excluded
daq_testing_filter_is_suite_excluded() {
    local suite_name="$1"
    
    if [ -z "$__DAQ_TESTING_FILTER_EXCLUDED_SUITES" ]; then
        return 1  # Not excluded
    fi
    
    # Check if suite is in exclusion list
    local old_ifs="$IFS"
    IFS=','
    for excluded_suite in $__DAQ_TESTING_FILTER_EXCLUDED_SUITES; do
        # Remove whitespace
        excluded_suite=$(echo "$excluded_suite" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ "$excluded_suite" = "$suite_name" ]; then
            IFS="$old_ifs"
            daq_testing_common_log_debug "Suite '$suite_name' is excluded"
            return 0  # Excluded
        fi
    done
    IFS="$old_ifs"
    
    return 1  # Not excluded
}

################################################################################
# PUBLIC API - Test Filtering (Hierarchical)
################################################################################

# Check if a test should be executed based on hierarchical filtering
# Hierarchy: Positive specification -> Exclusions -> Regex filter
# Args: $1 - test name
# Returns: 0 if should run, 1 if should skip
daq_testing_filter_should_run() {
    local test_name="$1"
    
    # If no filtering enabled, run all tests
    if [ "$__DAQ_TESTING_FILTER_ENABLED" != "true" ]; then
        return 0
    fi
    
    # Step 1: Check positive specification (highest priority)
    if [ -n "$__DAQ_TESTING_FILTER_POSITIVE_TESTS" ]; then
        local found_in_positive=false
        local old_ifs="$IFS"
        IFS=','
        for positive_test in $__DAQ_TESTING_FILTER_POSITIVE_TESTS; do
            # Remove whitespace
            positive_test=$(echo "$positive_test" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [ "$positive_test" = "$test_name" ]; then
                found_in_positive=true
                break
            fi
        done
        IFS="$old_ifs"
        
        # If positive list exists but test not in it, skip
        if [ "$found_in_positive" != "true" ]; then
            daq_testing_common_log_debug "Test '$test_name' not in positive list, skipping"
            return 1
        fi
    fi
    
    # Step 2: Check exclusions
    if [ -n "$__DAQ_TESTING_FILTER_EXCLUDED_TESTS" ]; then
        local old_ifs="$IFS"
        IFS=','
        for excluded_test in $__DAQ_TESTING_FILTER_EXCLUDED_TESTS; do
            # Remove whitespace
            excluded_test=$(echo "$excluded_test" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [ "$excluded_test" = "$test_name" ]; then
                IFS="$old_ifs"
                daq_testing_common_log_debug "Test '$test_name' is excluded"
                return 1  # Skip excluded test
            fi
        done
        IFS="$old_ifs"
    fi
    
    # Step 3: Check regex filter
    if [ -n "$__DAQ_TESTING_FILTER_REGEX" ]; then
        if ! echo "$test_name" | grep -qE "$__DAQ_TESTING_FILTER_REGEX"; then
            daq_testing_common_log_debug "Test '$test_name' does not match regex, skipping"
            return 1  # Skip if doesn't match regex
        fi
    fi
    
    # All checks passed - run the test
    daq_testing_common_log_debug "Test '$test_name' will run"
    return 0
}

################################################################################
# PUBLIC API - Suite Specification Parsing
################################################################################

# Parse suite specification in format "suite:test1,test2"
# Args: $1 - suite specification string
# Returns: Two lines: suite_name and test_list (may be empty)
daq_testing_filter_parse_suite_spec() {
    local suite_spec="$1"
    local suite_name=""
    local test_list=""
    
    if echo "$suite_spec" | grep -q ":"; then
        # Split by first colon
        suite_name=$(echo "$suite_spec" | cut -d: -f1)
        test_list=$(echo "$suite_spec" | cut -d: -f2-)
    else
        # No colon, just suite name
        suite_name="$suite_spec"
        test_list=""
    fi
    
    echo "$suite_name"
    echo "$test_list"
}

################################################################################
# PRIVATE FUNCTIONS - Utilities
################################################################################

# Trim whitespace from string
# Args: $1 - string to trim
# Returns: Trimmed string
__daq_testing_filter_trim() {
    local str="$1"
    echo "$str" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

################################################################################
# PUBLIC API - List Validation
################################################################################

# Check if a value is in a comma-separated list
# Args: $1 - value to find
#       $2 - comma-separated list
# Returns: 0 if found, 1 if not found
daq_testing_filter_is_in_list() {
    local value="$1"
    local list="$2"
    
    if [ -z "$list" ]; then
        return 1
    fi
    
    local old_ifs="$IFS"
    IFS=','
    for item in $list; do
        item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ "$item" = "$value" ]; then
            IFS="$old_ifs"
            return 0
        fi
    done
    IFS="$old_ifs"
    
    return 1
}

################################################################################
# END OF MODULE
################################################################################
