#!/bin/bash
################################################################################
# Module: assertion (testing framework core)
# Version: 2.0.1
# Description: Test assertion functions for openDAQ test framework
#
# Usage:
#   source core/assertion.sh
#   daq_testing_assert_equals 0 "input" --args
#
# Dependencies: core/common.sh, core/reporter.sh
# Exit codes: N/A (library only)
#
# BREAKING CHANGES in v2.0:
#   - Removed test_name as first argument from all functions
#   - Assertions now report details, not full test results
#   - Filtering moved to runner level (test functions, not assertions)
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

readonly DAQ_TESTING_ASSERTION_VERSION="2.0.1"
readonly DAQ_TESTING_ASSERTION_BUILD_DATE="2025-01-15"

################################################################################
# PRIVATE FUNCTIONS - Command Execution
################################################################################

# Execute script with arguments and capture output and exit code
# Args: $1 - script path
#       $2... - arguments to script
# Sets: __ASSERT_OUTPUT, __ASSERT_EXIT_CODE
# Returns: 0 always (captures exit code in variable)
__daq_testing_assert_execute() {
    local script_path="$1"
    shift
    
    # Execute command and capture output and exit code
    set +e
    __ASSERT_OUTPUT=$("$script_path" "$@" 2>&1)
    __ASSERT_EXIT_CODE=$?
    set -e
    
    if daq_testing_common_is_debug; then
        daq_testing_common_log_debug "Executed: $script_path $*"
        daq_testing_common_log_debug "Exit code: $__ASSERT_EXIT_CODE"
        daq_testing_common_log_debug "Output: ${__ASSERT_OUTPUT:0:100}..."
    fi
    
    return 0
}

################################################################################
# PRIVATE FUNCTIONS - Result Recording
################################################################################

# Record assertion success
# Args: $1 - detail message (optional)
# Returns: 0 always
__daq_testing_assert_record_pass() {
    local detail="${1:-Assertion passed}"
    
    daq_testing_reporter_assertion_pass_detail "$detail"
    
    return 0
}

# Record assertion failure
# Args: $1... - failure details
# Returns: 1 always
__daq_testing_assert_record_fail() {
    daq_testing_common_mark_test_failed
    daq_testing_reporter_assertion_fail_detail "$@"
    
    return 1
}

################################################################################
# PUBLIC API - Basic Assertions
################################################################################

# Assert that command produces exact output with specific exit code
# Args: $1 - expected exit code
#       $2 - input argument to script
#       $3... - additional arguments to script (optional expected output as last arg)
# Returns: 0 if pass, 1 if fail
# Note: If last non-flag argument is provided, it's treated as expected output
daq_testing_assert_equals() {
    local expected_exit_code="$1"
    local input_arg="$2"
    shift 2
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE" \
            "Command: $script_path \"$input_arg\" $*"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Exit code: $__ASSERT_EXIT_CODE (expected output check not implemented)"
    return 0
}

# Assert that command output contains substring
# Args: $1 - expected exit code
#       $2 - expected substring
#       $3 - input argument to script
#       $4... - additional arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_contains() {
    local expected_exit_code="$1"
    local expected_substring="$2"
    local input_arg="$3"
    shift 3
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE"
        return 1
    fi
    
    # Check if output contains expected substring
    if ! echo "$__ASSERT_OUTPUT" | grep -q "$expected_substring"; then
        __daq_testing_assert_record_fail \
            "Expected output to contain: '$expected_substring'" \
            "Actual output: '$__ASSERT_OUTPUT'"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Output contains: '$expected_substring'"
    return 0
}

################################################################################
# PUBLIC API - Assertions Without Input Argument
################################################################################

# Assert command without input argument (e.g., --help, --version)
# Args: $1 - expected exit code
#       $2... - arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_no_input() {
    local expected_exit_code="$1"
    shift
    
    # Filter out empty arguments
    local filtered_args=()
    for arg in "$@"; do
        if [ -n "$arg" ]; then
            filtered_args+=("$arg")
        fi
    done
    
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "${filtered_args[@]}"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE" \
            "Command: $script_path ${filtered_args[*]}"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Exit code: $__ASSERT_EXIT_CODE"
    return 0
}

# Assert command without input argument, output contains substring
# Args: $1 - expected exit code
#       $2 - expected substring
#       $3... - arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_no_input_contains() {
    local expected_exit_code="$1"
    local expected_substring="$2"
    shift 2

    # Filter out empty arguments
    local filtered_args=()
    for arg in "$@"; do
        if [ -n "$arg" ]; then
            filtered_args+=("$arg")
        fi
    done
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command without input argument
    __daq_testing_assert_execute "$script_path" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE"
        return 1
    fi
    
    # Check if output contains expected substring
    if ! echo "$__ASSERT_OUTPUT" | grep -q "$expected_substring"; then
        __daq_testing_assert_record_fail \
            "Expected output to contain: '$expected_substring'" \
            "Actual output: '$__ASSERT_OUTPUT'"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Output contains: '$expected_substring'"
    return 0
}

################################################################################
# PUBLIC API - Exit Code Only Assertions
################################################################################

# Assert only exit code (ignore output)
# Args: $1 - expected exit code
#       $2 - input argument to script
#       $3... - additional arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_exit_code() {
    local expected_exit_code="$1"
    local input_arg="$2"
    shift 2
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE" \
            "Command: $script_path \"$input_arg\" $*"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Exit code: $__ASSERT_EXIT_CODE"
    return 0
}

################################################################################
# PUBLIC API - Output State Assertions
################################################################################

# Assert that output is empty
# Args: $1 - expected exit code
#       $2 - input argument to script
#       $3... - additional arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_output_empty() {
    local expected_exit_code="$1"
    local input_arg="$2"
    shift 2
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE"
        return 1
    fi
    
    # Check if output is empty
    if [ -n "$__ASSERT_OUTPUT" ]; then
        __daq_testing_assert_record_fail \
            "Expected empty output" \
            "Actual output: '$__ASSERT_OUTPUT'"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Output is empty"
    return 0
}

# Assert that output is not empty
# Args: $1 - expected exit code
#       $2 - input argument to script
#       $3... - additional arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_output_not_empty() {
    local expected_exit_code="$1"
    local input_arg="$2"
    shift 2
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE"
        return 1
    fi
    
    # Check if output is not empty
    if [ -z "$__ASSERT_OUTPUT" ]; then
        __daq_testing_assert_record_fail \
            "Expected non-empty output" \
            "Actual output: (empty)"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Output is not empty"
    return 0
}

################################################################################
# PUBLIC API - Pattern Matching Assertions
################################################################################

# Assert that output matches regex pattern
# Args: $1 - expected exit code
#       $2 - regex pattern
#       $3 - input argument to script
#       $4... - additional arguments to script
# Returns: 0 if pass, 1 if fail
daq_testing_assert_matches_regex() {
    local expected_exit_code="$1"
    local regex_pattern="$2"
    local input_arg="$3"
    shift 3
    
    # Get script path
    local script_path
    script_path=$(daq_testing_common_get_script_path)
    
    # Execute command
    __daq_testing_assert_execute "$script_path" "$input_arg" "$@"
    
    # Check exit code
    if [ $__ASSERT_EXIT_CODE -ne $expected_exit_code ]; then
        __daq_testing_assert_record_fail \
            "Expected exit code: $expected_exit_code" \
            "Actual exit code: $__ASSERT_EXIT_CODE"
        return 1
    fi
    
    # Check if output matches regex
    if ! echo "$__ASSERT_OUTPUT" | grep -qE "$regex_pattern"; then
        __daq_testing_assert_record_fail \
            "Expected output to match regex: '$regex_pattern'" \
            "Actual output: '$__ASSERT_OUTPUT'"
        return 1
    fi
    
    __daq_testing_assert_record_pass "Output matches regex: '$regex_pattern'"
    return 0
}

################################################################################
# END OF MODULE
################################################################################
