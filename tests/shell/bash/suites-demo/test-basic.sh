#!/usr/bin/env bash
# Example test suite - basic tests

# Test that always passes
test-basic-pass() {
    echo "This test passes"
    return 0
}

# Another passing test
test-basic-simple() {
    local result=$((2 + 2))
    if [[ ${result} -eq 4 ]]; then
        return 0
    else
        echo "Math is broken!"
        return 1
    fi
}

# Test string operations
test-basic-strings() {
    local str="hello world"
    if [[ "${str}" == "hello world" ]]; then
        return 0
    else
        return 1
    fi
}

# Test array operations
test-basic-arrays() {
    local arr=("one" "two" "three")
    if [[ ${#arr[@]} -eq 3 ]]; then
        return 0
    else
        echo "Expected 3 elements, got ${#arr[@]}"
        return 1
    fi
}
