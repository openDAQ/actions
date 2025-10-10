#!/usr/bin/env bash
# test-math-utils.sh - Tests for math-utils.sh script functions

# Setup: Source the script we want to test
test_setup() {
    # Load the math utilities script
    source "${__DAQ_TESTS_SCRIPTS_DIR}/math-utils.sh"
}

# No teardown needed for this suite
test_teardown() {
    # Clean teardown - functions will be cleaned up automatically
    # because each test runs in a subshell
    :
}

# Test: math_add
test-math-add-positive-numbers() {
    local result
    result=$(math_add 5 10)
    
    daq_assert_num_equals 15 "${result}" "5 + 10 should equal 15"
}

test-math-add-negative-numbers() {
    local result
    result=$(math_add -5 -10)
    
    daq_assert_num_equals -15 "${result}" "-5 + -10 should equal -15"
}

test-math-add-zero() {
    local result
    result=$(math_add 42 0)
    
    daq_assert_num_equals 42 "${result}" "Adding zero should not change value"
}

# Test: math_subtract
test-math-subtract-basic() {
    local result
    result=$(math_subtract 10 3)
    
    daq_assert_num_equals 7 "${result}" "10 - 3 should equal 7"
}

test-math-subtract-negative-result() {
    local result
    result=$(math_subtract 5 10)
    
    daq_assert_num_equals -5 "${result}" "5 - 10 should equal -5"
}

# Test: math_multiply
test-math-multiply-positive() {
    local result
    result=$(math_multiply 6 7)
    
    daq_assert_num_equals 42 "${result}" "6 * 7 should equal 42"
}

test-math-multiply-by-zero() {
    local result
    result=$(math_multiply 100 0)
    
    daq_assert_num_equals 0 "${result}" "Anything times zero should be zero"
}

test-math-multiply-negative() {
    local result
    result=$(math_multiply -3 4)
    
    daq_assert_num_equals -12 "${result}" "-3 * 4 should equal -12"
}

# Test: math_divide
test-math-divide-basic() {
    local result
    result=$(math_divide 20 4)
    
    daq_assert_num_equals 5 "${result}" "20 / 4 should equal 5"
}

test-math-divide-integer-division() {
    local result
    result=$(math_divide 10 3)
    
    daq_assert_num_equals 3 "${result}" "10 / 3 should equal 3 (integer division)"
}

test-math-divide-by-zero() {
    local result exit_code=0
    
    # Should fail with error
    result=$(math_divide 10 0 2>&1) || exit_code=$?
    
    daq_assert_failure "${exit_code}" "Division by zero should fail" || return 1
    daq_assert_contains "Division by zero" "${result}" "Should show error message"
}

# Test: math_is_even
test-math-is-even-true() {
    if math_is_even 4; then
        return 0
    else
        echo "4 should be even"
        return 1
    fi
}

test-math-is-even-false() {
    if ! math_is_even 5; then
        return 0
    else
        echo "5 should be odd"
        return 1
    fi
}

test-math-is-even-zero() {
    if math_is_even 0; then
        return 0
    else
        echo "0 should be even"
        return 1
    fi
}

# Test: math_factorial
test-math-factorial-zero() {
    local result
    result=$(math_factorial 0)
    
    daq_assert_num_equals 1 "${result}" "0! should equal 1"
}

test-math-factorial-five() {
    local result
    result=$(math_factorial 5)
    
    daq_assert_num_equals 120 "${result}" "5! should equal 120"
}

test-math-factorial-negative() {
    local result exit_code=0
    
    result=$(math_factorial -5 2>&1) || exit_code=$?
    
    daq_assert_failure "${exit_code}" "Factorial of negative should fail"
}

# Test: math_max
test-math-max-first-larger() {
    local result
    result=$(math_max 10 5)
    
    daq_assert_num_equals 10 "${result}" "max(10, 5) should be 10"
}

test-math-max-second-larger() {
    local result
    result=$(math_max 3 8)
    
    daq_assert_num_equals 8 "${result}" "max(3, 8) should be 8"
}

test-math-max-equal() {
    local result
    result=$(math_max 7 7)
    
    daq_assert_num_equals 7 "${result}" "max(7, 7) should be 7"
}

# Test: math_min
test-math-min-first-smaller() {
    local result
    result=$(math_min 3 9)
    
    daq_assert_num_equals 3 "${result}" "min(3, 9) should be 3"
}

test-math-min-second-smaller() {
    local result
    result=$(math_min 15 2)
    
    daq_assert_num_equals 2 "${result}" "min(15, 2) should be 2"
}

# Test: math_power
test-math-power-basic() {
    local result
    result=$(math_power 2 3)
    
    daq_assert_num_equals 8 "${result}" "2^3 should equal 8"
}

test-math-power-zero-exponent() {
    local result
    result=$(math_power 100 0)
    
    daq_assert_num_equals 1 "${result}" "Any number to power 0 should be 1"
}

test-math-power-one-exponent() {
    local result
    result=$(math_power 42 1)
    
    daq_assert_num_equals 42 "${result}" "42^1 should equal 42"
}

# Test: math_is_prime
test-math-is-prime-two() {
    if math_is_prime 2; then
        return 0
    else
        echo "2 should be prime"
        return 1
    fi
}

test-math-is-prime-seven() {
    if math_is_prime 7; then
        return 0
    else
        echo "7 should be prime"
        return 1
    fi
}

test-math-is-prime-not-prime() {
    if ! math_is_prime 9; then
        return 0
    else
        echo "9 should not be prime"
        return 1
    fi
}

test-math-is-prime-one() {
    if ! math_is_prime 1; then
        return 0
    else
        echo "1 should not be prime"
        return 1
    fi
}

# Test: Complex scenario - using multiple functions
test-math-complex-calculation() {
    # Calculate: (5 + 3) * 2 - 4 / 2
    local sum=$(math_add 5 3)              # 8
    local product=$(math_multiply "${sum}" 2)  # 16
    local division=$(math_divide 4 2)          # 2
    local result=$(math_subtract "${product}" "${division}")  # 14
    
    daq_assert_num_equals 14 "${result}" "Complex calculation should equal 14"
}
