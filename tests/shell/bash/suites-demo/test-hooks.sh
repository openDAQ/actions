#!/usr/bin/env bash
# Example test suite demonstrating test_setup and test_teardown hooks

# Global variable to track state
TEST_TEMP_FILE=""
TEST_COUNTER=0

# Setup function called before EACH test
test_setup() {
    echo "    [SETUP] Preparing test environment"
    TEST_COUNTER=$((TEST_COUNTER + 1))
    TEST_TEMP_FILE="/tmp/test-hooks-$$-${TEST_COUNTER}.txt"
    echo "test data" > "${TEST_TEMP_FILE}"
    echo "    [SETUP] Created temp file: ${TEST_TEMP_FILE}"
}

# Teardown function called after EACH test
test_teardown() {
    echo "    [TEARDOWN] Cleaning up test environment"
    if [[ -n "${TEST_TEMP_FILE}" && -f "${TEST_TEMP_FILE}" ]]; then
        rm -f "${TEST_TEMP_FILE}"
        echo "    [TEARDOWN] Removed temp file: ${TEST_TEMP_FILE}"
    fi
}

# Test 1: Verify setup creates file
test-hooks-file-created() {
    if [[ ! -f "${TEST_TEMP_FILE}" ]]; then
        echo "ERROR: Temp file not created by setup"
        return 1
    fi
    
    echo "Test 1: File exists - OK"
    return 0
}

# Test 2: Verify file content
test-hooks-file-content() {
    local content
    content=$(cat "${TEST_TEMP_FILE}")
    
    if [[ "${content}" != "test data" ]]; then
        echo "ERROR: Expected 'test data', got '${content}'"
        return 1
    fi
    
    echo "Test 2: Content correct - OK"
    return 0
}

# Test 3: Modify file (next test should get fresh file from setup)
test-hooks-file-modification() {
    echo "modified" > "${TEST_TEMP_FILE}"
    
    local content
    content=$(cat "${TEST_TEMP_FILE}")
    
    if [[ "${content}" != "modified" ]]; then
        echo "ERROR: Content not modified"
        return 1
    fi
    
    echo "Test 3: Modified file - OK"
    return 0
}

# Test 4: Verify we get fresh file (not modified from test 3)
test-hooks-file-fresh() {
    local content
    content=$(cat "${TEST_TEMP_FILE}")
    
    if [[ "${content}" != "test data" ]]; then
        echo "ERROR: File not fresh! Got '${content}' instead of 'test data'"
        echo "This means test_setup didn't run or teardown didn't clean up"
        return 1
    fi
    
    echo "Test 4: Fresh file from setup - OK"
    return 0
}

# Test 5: Verify setup was called for this test
test-hooks-counter() {
    # Counter should be 1 for this test (setup was called once for this test)
    # Note: Each test runs in separate subshell, so counter resets
    if [[ ${TEST_COUNTER} -ne 1 ]]; then
        echo "ERROR: Counter is ${TEST_COUNTER}, expected 1"
        echo "This means test_setup wasn't called for this test"
        return 1
    fi
    
    echo "Test 5: Setup was called (counter=${TEST_COUNTER}) - OK"
    return 0
}
