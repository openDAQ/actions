#!/bin/bash

# test-framework.sh - Reusable testing framework for openDAQ scripts
# Compatible with Bash 3.x and macOS

# Global test state
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CURRENT_SUITE=""
SCRIPT_PATH=""
TEST_FILTER=""

# Colors for output (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

# Initialize test framework
test_framework_init() {
    local script_path="$1"
    local suite_name="$2"
    local filter="${3:-}"
    
    SCRIPT_PATH="$script_path"
    CURRENT_SUITE="$suite_name"
    TEST_FILTER="$filter"
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    
    # Check if script exists and is executable
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "${RED}Error: Script not found at $SCRIPT_PATH${RESET}"
        echo "Please ensure the script exists or use correct path"
        return 1
    fi
    
    if [ ! -x "$SCRIPT_PATH" ]; then
        echo "${YELLOW}Warning: Script is not executable, making it executable...${RESET}"
        chmod +x "$SCRIPT_PATH" || {
            echo "${RED}Error: Failed to make script executable${RESET}"
            return 1
        }
    fi
    
    echo "${BLUE}Testing: $SCRIPT_PATH${RESET}"
    echo "${BLUE}Suite: $CURRENT_SUITE${RESET}"
    if [ -n "$TEST_FILTER" ]; then
        echo "${BLUE}Filter: $TEST_FILTER${RESET}"
    fi
}

# Test helper functions
run_test() {
    local test_name="$1"
    local expected_exit_code="$2"
    local expected_output="$3"
    local version_input="$4"
    shift 4
    
    # Check if test matches filter
    if [ -n "$TEST_FILTER" ] && ! echo "$test_name" | grep -qE "$TEST_FILTER"; then
        return 0  # Skip this test silently
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Run the command and capture output and exit code
    local actual_output
    local actual_exit_code
    
    # Use eval to properly handle quoted arguments
    actual_output=$(eval "$SCRIPT_PATH" '"$version_input"' "$@" 2>&1)
    actual_exit_code=$?
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $actual_exit_code"
        echo "  Command: $SCRIPT_PATH \"$version_input\" $*"
        echo "  Output: $actual_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Check output if expected output is provided
    if [ -n "$expected_output" ] && [ "$actual_output" != "$expected_output" ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected output: '$expected_output'"
        echo "  Actual output: '$actual_output'"
        echo "  Command: $SCRIPT_PATH \"$version_input\" $*"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    echo "${GREEN}✓ PASS${RESET}: $test_name"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
}

run_test_contains() {
    local test_name="$1"
    local expected_exit_code="$2"
    local expected_substring="$3"
    local version_input="$4"
    shift 4
    
    # Check if test matches filter
    if [ -n "$TEST_FILTER" ] && ! echo "$test_name" | grep -qE "$TEST_FILTER"; then
        return 0  # Skip this test silently
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local actual_output
    local actual_exit_code
    
    # Use eval to properly handle quoted arguments
    actual_output=$(eval "$SCRIPT_PATH" '"$version_input"' "$@" 2>&1)
    actual_exit_code=$?
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $actual_exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Check if output contains expected substring
    if ! echo "$actual_output" | grep -q "$expected_substring"; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected output to contain: '$expected_substring'"
        echo "  Actual output: '$actual_output'"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    echo "${GREEN}✓ PASS${RESET}: $test_name"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
}

run_test_multiline() {
    local test_name="$1"
    local expected_exit_code="$2"
    local version_input="$3"
    shift 3
    
    # Check if test matches filter
    if [ -n "$TEST_FILTER" ] && ! echo "$test_name" | grep -qE "$TEST_FILTER"; then
        return 0  # Skip this test silently
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local actual_output
    local actual_exit_code
    
    # Use eval to properly handle quoted arguments
    actual_output=$(eval "$SCRIPT_PATH" '"$version_input"' "$@" 2>&1)
    actual_exit_code=$?
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $actual_exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    echo "${GREEN}✓ PASS${RESET}: $test_name"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
}

# Special test for commands without version input
run_test_no_input() {
    local test_name="$1"
    local expected_exit_code="$2"
    local expected_output="$3"
    shift 3
    
    # Check if test matches filter
    if [ -n "$TEST_FILTER" ] && ! echo "$test_name" | grep -qE "$TEST_FILTER"; then
        return 0  # Skip this test silently
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local actual_output
    local actual_exit_code
    actual_output=$(eval "$SCRIPT_PATH" "$@" 2>&1)
    actual_exit_code=$?
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $actual_exit_code"
        echo "  Command: $SCRIPT_PATH $*"
        echo "  Output: $actual_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    echo "${GREEN}✓ PASS${RESET}: $test_name"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
}

run_test_no_input_contains() {
    local test_name="$1"
    local expected_exit_code="$2"
    local expected_substring="$3"
    shift 3
    
    # Check if test matches filter
    if [ -n "$TEST_FILTER" ] && ! echo "$test_name" | grep -qE "$TEST_FILTER"; then
        return 0  # Skip this test silently
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local actual_output
    local actual_exit_code
    actual_output=$(eval "$SCRIPT_PATH" "$@" 2>&1)
    actual_exit_code=$?
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected exit code: $expected_exit_code"
        echo "  Actual exit code: $actual_exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Check if output contains expected substring
    if ! echo "$actual_output" | grep -q "$expected_substring"; then
        echo "${RED}✗ FAIL${RESET}: $test_name"
        echo "  Expected output to contain: '$expected_substring'"
        echo "  Actual output: '$actual_output'"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    echo "${GREEN}✓ PASS${RESET}: $test_name"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    return 0
}

# Section header
test_section() {
    local section_name="$1"
    echo
    echo "${BLUE}=== $section_name ===${RESET}"
}

# Print test summary
test_framework_summary() {
    echo
    echo "${BLUE}===========================================${RESET}"
    echo "${BLUE}                 TEST SUMMARY              ${RESET}"
    echo "${BLUE}===========================================${RESET}"
    echo "Suite: $CURRENT_SUITE"
    echo "Total tests: $TOTAL_TESTS"
    echo "${GREEN}Passed: $PASSED_TESTS${RESET}"
    
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "${RED}Failed: $FAILED_TESTS${RESET}"
        return 1
    else
        echo "${RED}Failed: $FAILED_TESTS${RESET}"
        return 0
    fi
}

# Get test results
test_framework_get_results() {
    echo "$TOTAL_TESTS $PASSED_TESTS $FAILED_TESTS"
}

# Reset test counters (for multiple suites)
test_framework_reset() {
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
}
