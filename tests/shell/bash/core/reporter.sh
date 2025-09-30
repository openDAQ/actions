#!/bin/bash
################################################################################
# Module: reporter (testing framework core)
# Version: 1.0.1
# Description: Test result reporting and output formatting for openDAQ test framework
#
# Usage:
#   source core/reporter.sh
#   daq_testing_reporter_section "Test Section"
#   daq_testing_reporter_pass "test name"
#
# Dependencies: core/common.sh (for colors and state)
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

readonly DAQ_TESTING_REPORTER_VERSION="1.0.1"
readonly DAQ_TESTING_REPORTER_BUILD_DATE="2025-01-15"

################################################################################
# PUBLIC API - Test Result Reporting
################################################################################

# Report a passed test
# Args: $1 - test name/description
# Returns: 0 always
daq_testing_reporter_pass() {
    local test_name="$1"
    
    echo "${DAQ_TESTING_COLOR_GREEN}✓ PASS${DAQ_TESTING_COLOR_RESET}: $test_name"
    
    return 0
}

# Report a failed test
# Args: $1 - test name/description
#       $2... - failure details (optional)
# Returns: 0 always
daq_testing_reporter_fail() {
    local test_name="$1"
    shift
    
    echo "${DAQ_TESTING_COLOR_RED}✗ FAIL${DAQ_TESTING_COLOR_RESET}: $test_name"
    
    # Print additional failure details if provided
    while [ $# -gt 0 ]; do
        echo "  $1"
        shift
    done
    
    return 0
}

# Report a skipped test
# Args: $1 - test name/description
#       $2 - reason (optional)
# Returns: 0 always
daq_testing_reporter_skip() {
    local test_name="$1"
    local reason="${2:-}"
    
    if [ -n "$reason" ]; then
        echo "${DAQ_TESTING_COLOR_YELLOW}○ SKIP${DAQ_TESTING_COLOR_RESET}: $test_name (${reason})"
    else
        echo "${DAQ_TESTING_COLOR_YELLOW}○ SKIP${DAQ_TESTING_COLOR_RESET}: $test_name"
    fi
    
    return 0
}

################################################################################
# PUBLIC API - Section Headers
################################################################################

# Print a test section header
# Args: $1 - section name
# Returns: 0 always
daq_testing_reporter_section() {
    local section_name="$1"
    
    echo
    echo "${DAQ_TESTING_COLOR_BLUE}=== $section_name ===${DAQ_TESTING_COLOR_RESET}"
    
    return 0
}

# Print a subsection header (less prominent than section)
# Args: $1 - subsection name
# Returns: 0 always
daq_testing_reporter_subsection() {
    local subsection_name="$1"
    
    echo
    echo "${DAQ_TESTING_COLOR_BLUE}--- $subsection_name ---${DAQ_TESTING_COLOR_RESET}"
    
    return 0
}

################################################################################
# PUBLIC API - Test Suite Summary
################################################################################

# Print summary for a single test suite
# Returns: 0 if all tests passed, 1 if any failed
daq_testing_reporter_suite_summary() {
    local suite_name
    suite_name=$(daq_testing_common_get_suite)
    
    echo
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}                 TEST SUMMARY              ${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "Suite: $suite_name"
    echo "Total tests: $OPENDAQ_TEST_TOTAL"
    echo "${DAQ_TESTING_COLOR_GREEN}Passed: $OPENDAQ_TEST_PASSED${DAQ_TESTING_COLOR_RESET}"
    
    if [ $OPENDAQ_TEST_FAILED -gt 0 ]; then
        echo "${DAQ_TESTING_COLOR_RED}Failed: $OPENDAQ_TEST_FAILED${DAQ_TESTING_COLOR_RESET}"
        return 1
    else
        echo "${DAQ_TESTING_COLOR_RED}Failed: $OPENDAQ_TEST_FAILED${DAQ_TESTING_COLOR_RESET}"
        
        # Check if any tests were executed
        if [ $OPENDAQ_TEST_TOTAL -eq 0 ]; then
            echo "${DAQ_TESTING_COLOR_YELLOW}Warning: No tests were executed${DAQ_TESTING_COLOR_RESET}"
        fi
        
        return 0
    fi
}

################################################################################
# PUBLIC API - Multi-Suite Summary
################################################################################

# Print grand summary for multiple test suites
# Args: $1 - total suites executed
#       $2 - passed suites
#       $3 - failed suites
#       $4 - grand total tests
#       $5 - grand passed tests
#       $6 - grand failed tests
# Returns: 0 if all passed, 1 if any failed
daq_testing_reporter_grand_summary() {
    local total_suites="$1"
    local passed_suites="$2"
    local failed_suites="$3"
    local grand_total="$4"
    local grand_passed="$5"
    local grand_failed="$6"
    
    echo
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}             OVERALL SUMMARY               ${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "Total suites: $total_suites"
    echo "${DAQ_TESTING_COLOR_GREEN}Passed suites: $passed_suites${DAQ_TESTING_COLOR_RESET}"
    
    if [ $failed_suites -gt 0 ]; then
        echo "${DAQ_TESTING_COLOR_RED}Failed suites: $failed_suites${DAQ_TESTING_COLOR_RESET}"
    else
        echo "${DAQ_TESTING_COLOR_RED}Failed suites: $failed_suites${DAQ_TESTING_COLOR_RESET}"
    fi
    
    echo
    echo "Grand total tests: $grand_total"
    echo "${DAQ_TESTING_COLOR_GREEN}Grand total passed: $grand_passed${DAQ_TESTING_COLOR_RESET}"
    
    if [ $grand_failed -gt 0 ]; then
        echo "${DAQ_TESTING_COLOR_RED}Grand total failed: $grand_failed${DAQ_TESTING_COLOR_RESET}"
        echo
        echo "${DAQ_TESTING_COLOR_RED}Some tests failed. Please review the output above.${DAQ_TESTING_COLOR_RESET}"
        return 1
    else
        echo "${DAQ_TESTING_COLOR_RED}Grand total failed: $grand_failed${DAQ_TESTING_COLOR_RESET}"
        echo
        
        if [ $grand_total -gt 0 ]; then
            echo "${DAQ_TESTING_COLOR_GREEN}All tests passed!${DAQ_TESTING_COLOR_RESET}"
        else
            echo "${DAQ_TESTING_COLOR_YELLOW}No tests were executed.${DAQ_TESTING_COLOR_RESET}"
        fi
        
        return 0
    fi
}

################################################################################
# PUBLIC API - Test-Level Reporting
################################################################################

# Start test report
# Args: $1 - test function name
# Returns: 0 always
daq_testing_reporter_test_start() {
    local test_name="$1"
    
    echo
    echo "${DAQ_TESTING_COLOR_BLUE}--- Test: $test_name ---${DAQ_TESTING_COLOR_RESET}"
    
    return 0
}

# End test report with result
# Args: $1 - test function name
#       $2 - result (PASS/FAIL)
# Returns: 0 always
daq_testing_reporter_test_end() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo "${DAQ_TESTING_COLOR_GREEN}✓ PASS${DAQ_TESTING_COLOR_RESET}: $test_name"
    else
        echo "${DAQ_TESTING_COLOR_RED}✗ FAIL${DAQ_TESTING_COLOR_RESET}: $test_name"
    fi
    
    return 0
}

# Report assertion success detail (only shown in verbose mode)
# Args: $1 - detail message
# Returns: 0 always
daq_testing_reporter_assertion_pass_detail() {
    local detail="$1"
    
    if daq_testing_common_is_verbose; then
        echo "  ${DAQ_TESTING_COLOR_GREEN}✓${DAQ_TESTING_COLOR_RESET} $detail"
    fi
    
    return 0
}

# Report assertion failure detail (always shown)
# Args: $1... - detail messages (one per line)
# Returns: 0 always
daq_testing_reporter_assertion_fail_detail() {
    while [ $# -gt 0 ]; do
        echo "  ${DAQ_TESTING_COLOR_RED}✗${DAQ_TESTING_COLOR_RESET} $1"
        shift
    done
    
    return 0
}

################################################################################
# PUBLIC API - Informational Messages
################################################################################

# Print informational message
# Args: $1... - message parts
# Returns: 0 always
daq_testing_reporter_info() {
    echo "${DAQ_TESTING_COLOR_BLUE}[INFO]${DAQ_TESTING_COLOR_RESET} $*"
    return 0
}

# Print warning message
# Args: $1... - message parts
# Returns: 0 always
daq_testing_reporter_warning() {
    echo "${DAQ_TESTING_COLOR_YELLOW}[WARNING]${DAQ_TESTING_COLOR_RESET} $*"
    return 0
}

# Print error message
# Args: $1... - message parts
# Returns: 0 always
daq_testing_reporter_error() {
    echo "${DAQ_TESTING_COLOR_RED}[ERROR]${DAQ_TESTING_COLOR_RESET} $*" >&2
    return 0
}

################################################################################
# PUBLIC API - Suite Initialization Banner
################################################################################

# Print banner at the start of a test suite
# Args: $1 - suite name
#       $2 - script path being tested
#       $3 - filtering info (optional)
# Returns: 0 always
daq_testing_reporter_suite_banner() {
    local suite_name="$1"
    local script_path="$2"
    local filtering_info="${3:-}"
    
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}         Running Suite: $suite_name       ${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "Testing: $script_path"
    
    if [ -n "$filtering_info" ]; then
        echo "$filtering_info"
    fi
    
    return 0
}

# Print banner at the start of test runner
# Args: $1 - runner name
#       $2 - runner version (optional)
# Returns: 0 always
daq_testing_reporter_runner_banner() {
    local runner_name="$1"
    local runner_version="${2:-}"
    
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    echo "${DAQ_TESTING_COLOR_BLUE}         $runner_name              ${DAQ_TESTING_COLOR_RESET}"
    
    if [ -n "$runner_version" ]; then
        echo "${DAQ_TESTING_COLOR_BLUE}         Version: $runner_version              ${DAQ_TESTING_COLOR_RESET}"
    fi
    
    echo "${DAQ_TESTING_COLOR_BLUE}===========================================${DAQ_TESTING_COLOR_RESET}"
    
    return 0
}

################################################################################
# PUBLIC API - Verbose/Debug Output
################################################################################

# Print verbose message (only if verbose mode enabled)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_reporter_verbose() {
    if daq_testing_common_is_verbose; then
        echo "${DAQ_TESTING_COLOR_BLUE}[VERBOSE]${DAQ_TESTING_COLOR_RESET} $*"
    fi
    return 0
}

# Print debug message (only if debug mode enabled)
# Args: $1... - message parts
# Returns: 0 always
daq_testing_reporter_debug() {
    if daq_testing_common_is_debug; then
        echo "${DAQ_TESTING_COLOR_BLUE}[DEBUG]${DAQ_TESTING_COLOR_RESET} $*" >&2
    fi
    return 0
}

################################################################################
# PUBLIC API - Progress Indicators
################################################################################

# Print progress indicator for test execution
# Args: $1 - current test number
#       $2 - total tests
#       $3 - test name (optional)
# Returns: 0 always
daq_testing_reporter_progress() {
    local current="$1"
    local total="$2"
    local test_name="${3:-}"
    
    if daq_testing_common_is_verbose; then
        if [ -n "$test_name" ]; then
            echo "${DAQ_TESTING_COLOR_BLUE}[$current/$total]${DAQ_TESTING_COLOR_RESET} Running: $test_name"
        else
            echo "${DAQ_TESTING_COLOR_BLUE}[$current/$total]${DAQ_TESTING_COLOR_RESET}"
        fi
    fi
    
    return 0
}

################################################################################
# END OF MODULE
################################################################################
