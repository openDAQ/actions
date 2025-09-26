#!/bin/bash

# test-framework.sh - Enhanced reusable testing framework for openDAQ scripts
# Compatible with Bash 3.x and macOS
# Now supports hierarchical filtering: positive specification -> exclusions -> regex filter

# Global test state
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CURRENT_SUITE=""
SCRIPT_PATH=""

# Filtering state
POSITIVE_TESTS=""        # Comma-separated list of specific tests to include
EXCLUDED_TESTS=""        # Comma-separated list of tests to exclude
REGEX_FILTER=""          # Regex pattern filter
FILTERING_ENABLED=false  # Whether any filtering is active

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
    local positive_tests="${3:-}"      # suite:test1,test2 format
    local excluded_tests="${4:-}"      # comma-separated excluded tests
    local regex_filter="${5:-}"        # regex pattern
    
    SCRIPT_PATH="$script_path"
    CURRENT_SUITE="$suite_name"
    POSITIVE_TESTS="$positive_tests"
    EXCLUDED_TESTS="$excluded_tests"
    REGEX_FILTER="$regex_filter"
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    
    # Determine if filtering is enabled
    if [ -n "$positive_tests" ] || [ -n "$excluded_tests" ] || [ -n "$regex_filter" ]; then
        FILTERING_ENABLED=true
    else
        FILTERING_ENABLED=false
    fi
    
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
    
    if [ "$FILTERING_ENABLED" = true ]; then
        echo "${BLUE}Filtering enabled:${RESET}"
        if [ -n "$positive_tests" ]; then
            echo "${BLUE}  - Positive tests: $positive_tests${RESET}"
        fi
        if [ -n "$excluded_tests" ]; then
            echo "${BLUE}  - Excluded tests: $excluded_tests${RESET}"
        fi
        if [ -n "$regex_filter" ]; then
            echo "${BLUE}  - Regex filter: $regex_filter${RESET}"
        fi
    fi
}

# Check if a test should be executed based on hierarchical filtering
should_run_test() {
    local test_name="$1"
    
    # If no filtering enabled, run all tests
    if [ "$FILTERING_ENABLED" != true ]; then
        return 0
    fi
    
    # Step 1: Check positive specification (highest priority)
    if [ -n "$POSITIVE_TESTS" ]; then
        local found_in_positive=false
        local old_ifs="$IFS"
        IFS=','
        for positive_test in $POSITIVE_TESTS; do
            # Remove any leading/trailing whitespace
            positive_test=$(echo "$positive_test" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ "$positive_test" = "$test_name" ]; then
                found_in_positive=true
                break
            fi
        done
        IFS="$old_ifs"
        
        # If positive list exists but test not in it, skip
        if [ "$found_in_positive" != true ]; then
            return 1
        fi
    fi
    
    # Step 2: Check exclusions
    if [ -n "$EXCLUDED_TESTS" ]; then
        local old_ifs="$IFS"
        IFS=','
        for excluded_test in $EXCLUDED_TESTS; do
            # Remove any leading/trailing whitespace
            excluded_test=$(echo "$excluded_test" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ "$excluded_test" = "$test_name" ]; then
                IFS="$old_ifs"
                return 1  # Skip excluded test
            fi
        done
        IFS="$old_ifs"
    fi
    
    # Step 3: Check regex filter
    if [ -n "$REGEX_FILTER" ]; then
        if ! echo "$test_name" | grep -qE "$REGEX_FILTER"; then
            return 1  # Skip if doesn't match regex
        fi
    fi
    
    return 0  # Run the test
}

# Test helper functions
run_test() {
    local test_name="$1"
    local expected_exit_code="$2"
    local expected_output="$3"
    local version_input="$4"
    shift 4
    
    # Check hierarchical filtering
    if ! should_run_test "$test_name"; then
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
    
    # Check hierarchical filtering
    if ! should_run_test "$test_name"; then
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
    
    # Check hierarchical filtering
    if ! should_run_test "$test_name"; then
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
    
    # Check hierarchical filtering
    if ! should_run_test "$test_name"; then
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
    
    # Check hierarchical filtering
    if ! should_run_test "$test_name"; then
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
        
        # Warning if no tests were executed due to filtering
        if [ $TOTAL_TESTS -eq 0 ] && [ "$FILTERING_ENABLED" = true ]; then
            echo "${YELLOW}Warning: No tests matched the filtering criteria${RESET}"
            if [ -n "$POSITIVE_TESTS" ]; then
                echo "${YELLOW}  Positive filter: $POSITIVE_TESTS${RESET}"
            fi
            if [ -n "$EXCLUDED_TESTS" ]; then
                echo "${YELLOW}  Excluded tests: $EXCLUDED_TESTS${RESET}"
            fi
            if [ -n "$REGEX_FILTER" ]; then
                echo "${YELLOW}  Regex filter: $REGEX_FILTER${RESET}"
            fi
        fi
        
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

# Utility function to list all test names in current suite (for debugging/inspection)
list_available_tests() {
    echo "Available test functions in current context:"
    declare -F | grep -E '^declare -f (run_test|test_)' | sed 's/declare -f /  /'
}
