#!/usr/bin/env bash
# Example test suite - integration tests

# Test file operations
test-integration-files() {
    local temp_file="/tmp/test-runner-$$-$RANDOM"
    echo "test content" > "${temp_file}"
    
    if [[ -f "${temp_file}" ]]; then
        local content
        content=$(cat "${temp_file}")
        rm -f "${temp_file}"
        
        if [[ "${content}" == "test content" ]]; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Test command execution
test-integration-commands() {
    local output
    output=$(echo "hello" | tr '[:lower:]' '[:upper:]')
    
    if [[ "${output}" == "HELLO" ]]; then
        return 0
    else
        echo "Expected HELLO, got ${output}"
        return 1
    fi
}

# Test that fails
test-integration-fail() {
    echo "This test is designed to fail"
    return 1
}

# Test environment variables
test-integration-env() {
    local test_var="test_value"
    export TEST_VAR="${test_var}"
    
    if [[ "${TEST_VAR}" == "test_value" ]]; then
        unset TEST_VAR
        return 0
    else
        return 1
    fi
}

# Slow test
test-integration-slow() {
    sleep 0.1
    return 0
}
