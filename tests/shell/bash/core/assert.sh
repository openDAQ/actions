#!/usr/bin/env bash
# Assertion library for test runner
# Provides assertion functions for common test scenarios

# Assert that command succeeded (exit code 0)
# Arguments: exit_code message
# Returns: 0 if exit_code is 0, 1 otherwise
daq_assert_success() {
    local exit_code="$1"
    local message="${2:-Command should succeed}"
    
    if [[ "${exit_code}" -eq 0 ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: success (exit code 0)"
        echo "  Got: exit code ${exit_code}"
        return 1
    fi
}

# Assert that command failed (exit code non-zero)
# Arguments: exit_code message
# Returns: 0 if exit_code is non-zero, 1 otherwise
daq_assert_failure() {
    local exit_code="$1"
    local message="${2:-Command should fail}"
    
    if [[ "${exit_code}" -ne 0 ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: failure (exit code non-zero)"
        echo "  Got: exit code 0 (success)"
        return 1
    fi
}

# Assert that two values are equal
# Arguments: expected actual message
# Returns: 0 if equal, 1 otherwise
daq_assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "${expected}" == "${actual}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: '${expected}'"
        echo "  Got:      '${actual}'"
        return 1
    fi
}

# Assert that two values are not equal
# Arguments: expected actual message
# Returns: 0 if not equal, 1 otherwise
daq_assert_not_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "${expected}" != "${actual}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: NOT '${expected}'"
        echo "  Got:      '${actual}'"
        return 1
    fi
}

# Assert that string contains substring
# Arguments: substring string message
# Returns: 0 if contains, 1 otherwise
daq_assert_contains() {
    local substring="$1"
    local string="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "${string}" == *"${substring}"* ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected substring: '${substring}'"
        echo "  In string:          '${string}'"
        return 1
    fi
}

# Assert that string does not contain substring
# Arguments: substring string message
# Returns: 0 if does not contain, 1 otherwise
daq_assert_not_contains() {
    local substring="$1"
    local string="$2"
    local message="${3:-String should not contain substring}"
    
    if [[ "${string}" != *"${substring}"* ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Unexpected substring: '${substring}'"
        echo "  Found in string:      '${string}'"
        return 1
    fi
}

# Assert that string matches regex pattern
# Arguments: pattern string message
# Returns: 0 if matches, 1 otherwise
daq_assert_matches() {
    local pattern="$1"
    local string="$2"
    local message="${3:-String should match pattern}"
    
    if [[ "${string}" =~ ${pattern} ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected pattern: '${pattern}'"
        echo "  Got string:       '${string}'"
        return 1
    fi
}

# Assert that string does not match regex pattern
# Arguments: pattern string message
# Returns: 0 if does not match, 1 otherwise
daq_assert_not_matches() {
    local pattern="$1"
    local string="$2"
    local message="${3:-String should not match pattern}"
    
    if [[ ! "${string}" =~ ${pattern} ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Unexpected match with pattern: '${pattern}'"
        echo "  Got string:                    '${string}'"
        return 1
    fi
}

# Assert that file exists
# Arguments: filepath message
# Returns: 0 if exists, 1 otherwise
daq_assert_file_exists() {
    local filepath="$1"
    local message="${2:-File should exist}"
    
    if [[ -f "${filepath}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected file: '${filepath}'"
        echo "  File does not exist"
        return 1
    fi
}

# Assert that file does not exist
# Arguments: filepath message
# Returns: 0 if does not exist, 1 otherwise
daq_assert_file_not_exists() {
    local filepath="$1"
    local message="${2:-File should not exist}"
    
    if [[ ! -f "${filepath}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  File should not exist: '${filepath}'"
        echo "  But file exists"
        return 1
    fi
}

# Assert that directory exists
# Arguments: dirpath message
# Returns: 0 if exists, 1 otherwise
daq_assert_dir_exists() {
    local dirpath="$1"
    local message="${2:-Directory should exist}"
    
    if [[ -d "${dirpath}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected directory: '${dirpath}'"
        echo "  Directory does not exist"
        return 1
    fi
}

# Assert that directory does not exist
# Arguments: dirpath message
# Returns: 0 if does not exist, 1 otherwise
daq_assert_dir_not_exists() {
    local dirpath="$1"
    local message="${2:-Directory should not exist}"
    
    if [[ ! -d "${dirpath}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Directory should not exist: '${dirpath}'"
        echo "  But directory exists"
        return 1
    fi
}

# Assert that value is empty
# Arguments: value message
# Returns: 0 if empty, 1 otherwise
daq_assert_empty() {
    local value="$1"
    local message="${2:-Value should be empty}"
    
    if [[ -z "${value}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: empty string"
        echo "  Got:      '${value}'"
        return 1
    fi
}

# Assert that value is not empty
# Arguments: value message
# Returns: 0 if not empty, 1 otherwise
daq_assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    if [[ -n "${value}" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: non-empty string"
        echo "  Got:      empty string"
        return 1
    fi
}

# Assert that numeric values are equal
# Arguments: expected actual message
# Returns: 0 if equal, 1 otherwise
daq_assert_num_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Numeric values should be equal}"
    
    if [[ "${expected}" -eq "${actual}" ]] 2>/dev/null; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: ${expected}"
        echo "  Got:      ${actual}"
        return 1
    fi
}

# Assert that actual is greater than expected
# Arguments: expected actual message
# Returns: 0 if actual > expected, 1 otherwise
daq_assert_greater_than() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Value should be greater than expected}"
    
    if [[ "${actual}" -gt "${expected}" ]] 2>/dev/null; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: > ${expected}"
        echo "  Got:      ${actual}"
        return 1
    fi
}

# Assert that actual is less than expected
# Arguments: expected actual message
# Returns: 0 if actual < expected, 1 otherwise
daq_assert_less_than() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Value should be less than expected}"
    
    if [[ "${actual}" -lt "${expected}" ]] 2>/dev/null; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Expected: < ${expected}"
        echo "  Got:      ${actual}"
        return 1
    fi
}

# Assert that condition is true
# Arguments: condition message
# Returns: 0 if condition is true, 1 otherwise
# Usage: daq_assert_true "[[ -f /tmp/file.txt ]]" "File should exist"
daq_assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    if eval "${condition}"; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Condition: ${condition}"
        echo "  Evaluated to: false"
        return 1
    fi
}

# Assert that condition is false
# Arguments: condition message
# Returns: 0 if condition is false, 1 otherwise
# Usage: daq_assert_false "[[ -f /tmp/nonexistent ]]" "File should not exist"
daq_assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if ! eval "${condition}"; then
        return 0
    else
        echo "ASSERTION FAILED: ${message}"
        echo "  Condition: ${condition}"
        echo "  Evaluated to: true"
        return 1
    fi
}
