#!/usr/bin/env bash
# Example test suite demonstrating assertion library

# Note: assert.sh is already loaded by test-runner.sh
# No need to source it here!

test_setup() {
    # Create temp file for tests
    TEST_FILE="/tmp/test-assertions-$$.txt"
    echo "test content" > "${TEST_FILE}"
}

test_teardown() {
    # Clean up temp file
    rm -f "${TEST_FILE}"
}

# Test: daq_assert_equals
test-assertion-equals() {
    local expected="hello"
    local actual="hello"
    
    daq_assert_equals "${expected}" "${actual}" "Strings should be equal"
}

# Test: daq_assert_not_equals
test-assertion-not-equals() {
    local value1="foo"
    local value2="bar"
    
    daq_assert_not_equals "${value1}" "${value2}" "Strings should be different"
}

# Test: daq_assert_contains
test-assertion-contains() {
    local text="Hello World"
    local substring="World"
    
    daq_assert_contains "${substring}" "${text}" "Text should contain substring"
}

# Test: daq_assert_success
test-assertion-success() {
    true  # Command that succeeds
    local exit_code=$?
    
    daq_assert_success "${exit_code}" "true command should succeed"
}

# Test: daq_assert_failure
test-assertion-failure() {
    # Capture exit code without triggering set -e
    local exit_code=0
    false || exit_code=$?
    
    daq_assert_failure "${exit_code}" "false command should fail"
}

# Test: daq_assert_file_exists
test-assertion-file-exists() {
    daq_assert_file_exists "${TEST_FILE}" "Test file should exist"
}

# Test: daq_assert_empty
test-assertion-empty() {
    local empty_var=""
    
    daq_assert_empty "${empty_var}" "Variable should be empty"
}

# Test: daq_assert_not_empty
test-assertion-not-empty() {
    local non_empty_var="value"
    
    daq_assert_not_empty "${non_empty_var}" "Variable should not be empty"
}

# Test: daq_assert_num_equals
test-assertion-num-equals() {
    local expected=42
    local actual=42
    
    daq_assert_num_equals "${expected}" "${actual}" "Numbers should be equal"
}

# Test: daq_assert_greater_than
test-assertion-greater-than() {
    local expected=10
    local actual=20
    
    daq_assert_greater_than "${expected}" "${actual}" "20 should be greater than 10"
}

# Test: daq_assert_matches (regex)
test-assertion-matches() {
    local pattern="^[0-9]+$"
    local string="12345"
    
    daq_assert_matches "${pattern}" "${string}" "String should match numeric pattern"
}

# Test: Multiple assertions in one test
test-assertion-multiple() {
    local result="Hello World"
    
    # Multiple assertions - all must pass
    daq_assert_not_empty "${result}" "Result should not be empty" || return 1
    daq_assert_contains "Hello" "${result}" "Should contain Hello" || return 1
    daq_assert_contains "World" "${result}" "Should contain World" || return 1
    
    return 0
}

# Test: Demonstrating assertion failure (this test will fail intentionally)
test-assertion-demo-failure() {
    local expected="foo"
    local actual="bar"
    
    # This will fail and show helpful error message
    daq_assert_equals "${expected}" "${actual}" "This demonstrates assertion failure"
}
