#!/usr/bin/env bash
# Example test suite - advanced tests

# Test function definitions
test-advanced-functions() {
    helper_func() {
        echo "helper"
    }
    
    local result
    result=$(helper_func)
    
    if [[ "${result}" == "helper" ]]; then
        return 0
    else
        return 1
    fi
}

# Test error handling
test-advanced-error-handling() {
    (
        set -e
        true
        true
        true
    )
    
    if [[ $? -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Test subprocess
test-advanced-subprocess() {
    local result
    result=$(bash -c 'echo "subprocess output"')
    
    if [[ "${result}" == "subprocess output" ]]; then
        return 0
    else
        return 1
    fi
}

# Test API call simulation
test-advanced-api-mock() {
    # Simulate API response
    local response='{"status": "ok", "data": "test"}'
    
    if [[ "${response}" == *"ok"* ]]; then
        return 0
    else
        return 1
    fi
}
