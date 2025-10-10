#!/bin/bash

# ========================
# Global context
# ========================
__DAQ_ASSERTION_VERBOSE=false

# Last assertion context
__DAQ_ASSERTION_LAST_NAME=""
__DAQ_ASSERTION_LAST_RESULT=0
__DAQ_ASSERTION_LAST_MSG=""

# ========================
# Private API
# ========================
__daq_t_assertion_is_verbose() {
    [ "$__DAQ_ASSERTION_VERBOSE" = true ]
}

__daq_t_assertion_fail_msg() {
    local msg="$1"
    local expected="$2"
    local actual="$3"
    echo "${DAQ_TESTING_COLOR_YELLOW}Assertion failure: $msg — expected '$expected', got '$actual'${DAQ_TESTING_COLOR_RESET}" >&2
}

__daq_t_assertion_pass_msg() {
    local msg="$1"
    __daq_t_assertion_is_verbose && echo "${DAQ_TESTING_COLOR_GREEN}Assertion success: $msg${DAQ_TESTING_COLOR_RESET}"
}

# ========================
# Init
# $1 - verbose flag (true/false), optional
# ========================
daq_testing_assertion_init() {
    __DAQ_ASSERTION_VERBOSE="${1:-false}"
}

# ========================
# Public assertions
# ========================

daq_testing_assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    __DAQ_ASSERTION_LAST_NAME="assert_equals"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ "$expected" != "$actual" ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "$expected" "$actual"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

daq_testing_assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    __DAQ_ASSERTION_LAST_NAME="assert_not_equal"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ "$expected" = "$actual" ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "not $expected" "$actual"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

daq_testing_assert_success() {
    local code="$1"
    local msg="$2"

    __DAQ_ASSERTION_LAST_NAME="assert_success"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ "$code" -ne 0 ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "success (0)" "$code"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

daq_testing_assert_fail() {
    local code="$1"
    local msg="$2"

    __DAQ_ASSERTION_LAST_NAME="assert_fail"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ "$code" -eq 0 ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "failure (non-zero)" "$code"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

# ========================
# Assert: contains substring
# ========================
daq_testing_assert_contains() {
    local string="$1"
    local substring="$2"
    local msg="$3"

    __DAQ_ASSERTION_LAST_NAME="assert_contains"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [[ "$string" != *"$substring"* ]]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "contains '$substring'" "$string"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

# ========================
# Assert: string is empty
# ========================
daq_testing_assertion_empty() {
    local string="$1"
    local msg="$2"

    __DAQ_ASSERTION_LAST_NAME="assert_empty"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ -n "$string" ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "empty string" "$string"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

# ========================
# Assert: string not empty
# ========================
daq_testing_assert_not_empty() {
    local string="$1"
    local msg="$2"

    __DAQ_ASSERTION_LAST_NAME="assert_not_empty"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [ -z "$string" ]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "non-empty string" "empty"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}

# ========================
# Assert: matches regex
# ========================
daq_testing_assert_matches() {
    local string="$1"
    local regex="$2"
    local msg="$3"

    __DAQ_ASSERTION_LAST_NAME="assert_matches"
    __DAQ_ASSERTION_LAST_MSG="$msg"

    if [[ ! "$string" =~ $regex ]]; then
        __DAQ_ASSERTION_LAST_RESULT=1
        __daq_t_assertion_fail_msg "$msg" "matches regex '$regex'" "$string"
        return 1
    fi

    __DAQ_ASSERTION_LAST_RESULT=0
    __daq_t_assertion_pass_msg "$msg"
    return 0
}
