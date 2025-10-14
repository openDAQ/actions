#!/usr/bin/env bash
# math-utils.sh - Mathematical utility functions

# Add two numbers
math_add() {
    local a="$1"
    local b="$2"
    echo $((a + b))
}

# Subtract two numbers
math_subtract() {
    local a="$1"
    local b="$2"
    echo $((a - b))
}

# Multiply two numbers
math_multiply() {
    local a="$1"
    local b="$2"
    echo $((a * b))
}

# Divide two numbers (integer division)
math_divide() {
    local a="$1"
    local b="$2"
    
    if [[ "${b}" -eq 0 ]]; then
        echo "ERROR: Division by zero" >&2
        return 1
    fi
    
    echo $((a / b))
}

# Check if number is even
math_is_even() {
    local num="$1"
    [[ $((num % 2)) -eq 0 ]]
}

# Calculate factorial (recursive)
math_factorial() {
    local n="$1"
    
    if [[ "${n}" -lt 0 ]]; then
        echo "ERROR: Factorial of negative number" >&2
        return 1
    fi
    
    if [[ "${n}" -eq 0 ]] || [[ "${n}" -eq 1 ]]; then
        echo 1
        return 0
    fi
    
    local prev
    prev=$(math_factorial $((n - 1)))
    echo $((n * prev))
}

# Find maximum of two numbers
math_max() {
    local a="$1"
    local b="$2"
    
    if [[ "${a}" -gt "${b}" ]]; then
        echo "${a}"
    else
        echo "${b}"
    fi
}

# Find minimum of two numbers
math_min() {
    local a="$1"
    local b="$2"
    
    if [[ "${a}" -lt "${b}" ]]; then
        echo "${a}"
    else
        echo "${b}"
    fi
}

# Calculate power (a^b)
math_power() {
    local base="$1"
    local exponent="$2"
    
    if [[ "${exponent}" -eq 0 ]]; then
        echo 1
        return 0
    fi
    
    local result=1
    for ((i=0; i<exponent; i++)); do
        result=$((result * base))
    done
    
    echo "${result}"
}

# Check if number is prime
math_is_prime() {
    local n="$1"
    
    if [[ "${n}" -lt 2 ]]; then
        return 1
    fi
    
    if [[ "${n}" -eq 2 ]]; then
        return 0
    fi
    
    if [[ $((n % 2)) -eq 0 ]]; then
        return 1
    fi
    
    local i=3
    while [[ $((i * i)) -le "${n}" ]]; do
        if [[ $((n % i)) -eq 0 ]]; then
            return 1
        fi
        i=$((i + 2))
    done
    
    return 0
}
