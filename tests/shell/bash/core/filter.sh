#!/usr/bin/env bash
# Test filtering module with include/exclude pattern support

# Arrays to store include/exclude patterns
__DAQ_TESTS_INCLUDE_PATTERNS=()
__DAQ_TESTS_EXCLUDE_PATTERNS=()

# Initialize filter module
daq_tests_filters_init() {
    __DAQ_TESTS_INCLUDE_PATTERNS=()
    __DAQ_TESTS_EXCLUDE_PATTERNS=()
}

# Parse pattern into suite and test parts
# Format: "test-<suite>:test-<test>" or "test-<suite>"
# Returns: sets global __DAQ_TESTS_PATTERN_SUITE and __DAQ_TESTS_PATTERN_TEST
__daq_tests_filter_parse_pattern() {
    local pattern="$1"
    
    if [[ "${pattern}" == *:* ]]; then
        # Pattern contains colon - split into suite and test
        __DAQ_TESTS_PATTERN_SUITE="${pattern%%:*}"
        __DAQ_TESTS_PATTERN_TEST="${pattern##*:}"
    else
        # Pattern is suite only - match all tests in suite
        __DAQ_TESTS_PATTERN_SUITE="${pattern}"
        __DAQ_TESTS_PATTERN_TEST="*"
    fi
}

# Add include pattern
# Arguments: pattern in format "test-<suite>[:test-<test>]"
daq_tests_filter_include_test() {
    local pattern="$1"
    __daq_tests_array_append "__DAQ_TESTS_INCLUDE_PATTERNS" "${pattern}"
}

# Add exclude pattern
# Arguments: pattern in format "test-<suite>[:test-<test>]"
daq_tests_filter_exclude_test() {
    local pattern="$1"
    __daq_tests_array_append "__DAQ_TESTS_EXCLUDE_PATTERNS" "${pattern}"
}

# Add include pattern for suite (equivalent to suite:*)
daq_tests_filter_include_suite() {
    local suite_pattern="$1"
    daq_tests_filter_include_test "${suite_pattern}:*"
}

# Add exclude pattern for suite (equivalent to suite:*)
daq_tests_filter_exclude_suite() {
    local suite_pattern="$1"
    daq_tests_filter_exclude_test "${suite_pattern}:*"
}

# Check if test matches any pattern in the given array
# Arguments: suite_name test_name patterns_array_name
# Returns: 0 if matches, 1 if not
__daq_tests_filter_matches_any() {
    local suite_name="$1"
    local test_name="$2"
    local patterns_array_name="$3"
    
    # Get array size first to handle empty arrays
    local array_size
    array_size=$(eval "echo \${#${patterns_array_name}[@]}")
    
    if [[ "${array_size}" -eq 0 ]]; then
        return 1
    fi
    
    # Copy array to local variable using eval - single eval, safe approach
    local -a patterns
    eval "patterns=(\"\${${patterns_array_name}[@]}\")"
    
    # Clean iteration without eval
    local pattern
    for pattern in "${patterns[@]}"; do
        __daq_tests_filter_parse_pattern "${pattern}"
        
        if __daq_tests_match_pattern "${suite_name}" "${__DAQ_TESTS_PATTERN_SUITE}" && \
           __daq_tests_match_pattern "${test_name}" "${__DAQ_TESTS_PATTERN_TEST}"; then
            return 0
        fi
    done
    
    return 1
}

# Check if test is included
# Arguments: suite_name test_name
# Returns: 0 if included, 1 if not
# Logic:
# - If include list is empty, all tests are included by default
# - If include list has patterns, test must match at least one
daq_tests_filter_is_test_included() {
    local suite_name="$1"
    local test_name="$2"
    
    local include_count
    include_count=$(__daq_tests_array_size "__DAQ_TESTS_INCLUDE_PATTERNS")
    
    # If no include patterns specified, everything is included by default
    if [[ "${include_count}" -eq 0 ]]; then
        return 0
    fi
    
    # Check if test matches any include pattern
    __daq_tests_filter_matches_any "${suite_name}" "${test_name}" "__DAQ_TESTS_INCLUDE_PATTERNS"
}

# Check if test is excluded
# Arguments: suite_name test_name
# Returns: 0 if excluded, 1 if not
daq_tests_filter_is_test_excluded() {
    local suite_name="$1"
    local test_name="$2"
    
    # Check if test matches any exclude pattern
    __daq_tests_filter_matches_any "${suite_name}" "${test_name}" "__DAQ_TESTS_EXCLUDE_PATTERNS"
}

# Check if suite is included (checks if any test in suite would be included)
# Arguments: suite_name
# Returns: 0 if included, 1 if not
daq_tests_filter_is_suite_included() {
    local suite_name="$1"
    
    # Check with wildcard test name
    daq_tests_filter_is_test_included "${suite_name}" "*"
}

# Check if suite is excluded (checks if all tests in suite would be excluded)
# Arguments: suite_name
# Returns: 0 if excluded, 1 if not
daq_tests_filter_is_suite_excluded() {
    local suite_name="$1"
    
    # Check with wildcard test name
    daq_tests_filter_is_test_excluded "${suite_name}" "*"
}

# Final decision: should test be run?
# Arguments: suite_name test_name
# Returns: 0 if should run, 1 if should not
# Logic: exclude has priority over include
daq_tests_filter_should_run_test() {
    local suite_name="$1"
    local test_name="$2"
    
    # First check if excluded (exclude has priority)
    if daq_tests_filter_is_test_excluded "${suite_name}" "${test_name}"; then
        return 1
    fi
    
    # Then check if included
    if daq_tests_filter_is_test_included "${suite_name}" "${test_name}"; then
        return 0
    fi
    
    # Not included and not excluded - should not run
    return 1
}

# Get list of all include patterns
daq_tests_filter_get_include_patterns() {
    for pattern in "${__DAQ_TESTS_INCLUDE_PATTERNS[@]+"${__DAQ_TESTS_INCLUDE_PATTERNS[@]}"}"; do
        echo "${pattern}"
    done
}

# Get list of all exclude patterns
daq_tests_filter_get_exclude_patterns() {
    for pattern in "${__DAQ_TESTS_EXCLUDE_PATTERNS[@]+"${__DAQ_TESTS_EXCLUDE_PATTERNS[@]}"}"; do
        echo "${pattern}"
    done
}

# Get count of include patterns
daq_tests_filter_get_include_count() {
    __daq_tests_array_size "__DAQ_TESTS_INCLUDE_PATTERNS"
}

# Get count of exclude patterns
daq_tests_filter_get_exclude_count() {
    __daq_tests_array_size "__DAQ_TESTS_EXCLUDE_PATTERNS"
}
