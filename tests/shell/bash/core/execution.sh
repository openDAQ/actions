#!/bin/bash

# ========================
# Global context
# ========================
__DAQ_TESTING_SCRIPTS_DIR="/path/to/scripts"
__DAQ_TESTING_VERBOSE=false

# ========================
# Script execution context
# ========================
__DAQ_TESTING_EXECUTE_LAST_SCRIPT=""
__DAQ_TESTING_EXECUTE_LAST_SCRIPT_EC=0
__DAQ_TESTING_EXECUTE_LAST_SCRIPT_OUT=""

# ========================
# Function execution context
# ========================
__DAQ_TESTING_EXECUTE_LAST_FUNC=""
__DAQ_TESTING_EXECUTE_LAST_FUNC_EC=0
__DAQ_TESTING_EXECUTE_LAST_FUNC_OUT=""

# ========================
# Private API
# ========================
__daq_t_execute_is_verbose() {
    # всегда возвращает числовой код выхода
    if [ "${__DAQ_TESTING_VERBOSE}" = "true" ]; then
        return 0  # verbose включен
    fi
    return 1      # verbose выключен
}

# ========================
# Init
# ========================
# $1 - scripts directory
# $2 - verbose flag (true/false), optional
daq_testing_execute_init() {
    local scripts_dir="$1"
    local verbose="${2:-false}"  # default to false if not provided

    __DAQ_TESTING_SCRIPTS_DIR="$scripts_dir"
    __DAQ_TESTING_VERBOSE="$verbose"
}

# ========================
# Getters for scripts
# ========================
daq_testing_execute_get_last_script() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_SCRIPT"
}

daq_testing_execute_get_last_script_ec() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_SCRIPT_EC"
}

daq_testing_execute_get_last_script_out() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_SCRIPT_OUT"
}

# ========================
# Getters for functions
# ========================
daq_testing_execute_get_last_func() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_FUNC"
}

daq_testing_execute_get_last_func_ec() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_FUNC_EC"
}

daq_testing_execute_get_last_func_out() {
    echo "$__DAQ_TESTING_EXECUTE_LAST_FUNC_OUT"
}

# ========================
# Executor for scripts
# ========================
daq_testing_execute_script() {
    local script="$1"
    shift

    local full_path
    if [[ "$script" == /* ]]; then
        full_path="$script"
    else
        full_path="${__DAQ_TESTING_SCRIPTS_DIR}/${script}"
    fi

    if [ ! -f "$full_path" ]; then
        echo "ERROR: Script not found: $full_path" >&2
        __DAQ_TESTING_EXECUTE_LAST_SCRIPT="$full_path $*"
        __DAQ_TESTING_EXECUTE_LAST_SCRIPT_EC=127
        __DAQ_TESTING_EXECUTE_LAST_SCRIPT_OUT=""
        return 127
    fi

    local output
    output=$("$full_path" "$@" 2>&1)
    local exit_code=$?

    __DAQ_TESTING_EXECUTE_LAST_SCRIPT="$full_path $*"
    __DAQ_TESTING_EXECUTE_LAST_SCRIPT_EC=$exit_code
    __DAQ_TESTING_EXECUTE_LAST_SCRIPT_OUT="$output"

    if [ $exit_code -ne 0 ]; then
        echo "${DAQ_TESTING_COLOR_RED}Script: $full_path $*${DAQ_TESTING_COLOR_RESET}" >&2
        echo "${DAQ_TESTING_COLOR_RED}Exit code: $exit_code${DAQ_TESTING_COLOR_RESET}" >&2
        __daq_t_execute_is_verbose && {
            echo "${DAQ_TESTING_COLOR_RED}Output:${DAQ_TESTING_COLOR_RESET}" >&2
            echo "${DAQ_TESTING_COLOR_RED}$output${DAQ_TESTING_COLOR_RESET}" >&2
        }
        return $exit_code
    fi

    __daq_t_execute_is_verbose && {
        echo "${DAQ_TESTING_COLOR_GREEN}Script: $full_path $*${DAQ_TESTING_COLOR_RESET}"
        echo "${DAQ_TESTING_COLOR_GREEN}Exit code: $exit_code${DAQ_TESTING_COLOR_RESET}"
        echo "${DAQ_TESTING_COLOR_GREEN}Output: ${output:0:100}...${DAQ_TESTING_COLOR_RESET}"
    }

    return $exit_code
}

# ========================
# Executor for functions
# ========================
daq_testing_execute_function() {
    local func_name="$1"
    shift

    if ! declare -F "$func_name" >/dev/null 2>&1; then
        echo "ERROR: Function not found: $func_name" >&2
        __DAQ_TESTING_EXECUTE_LAST_FUNC="$func_name $*"
        __DAQ_TESTING_EXECUTE_LAST_FUNC_EC=127
        __DAQ_TESTING_EXECUTE_LAST_FUNC_OUT=""
        return 127
    fi

    local output
    # Correct way to capture output of a function with arguments
    output=$("$func_name" "$@" 2>&1)
    local exit_code=$?

    __DAQ_TESTING_EXECUTE_LAST_FUNC="$func_name $*"
    __DAQ_TESTING_EXECUTE_LAST_FUNC_EC=$exit_code
    __DAQ_TESTING_EXECUTE_LAST_FUNC_OUT="$output"

    if [ $exit_code -ne 0 ]; then
        echo "${DAQ_TESTING_COLOR_RED}Function: $func_name $*${DAQ_TESTING_COLOR_RESET}" >&2
        echo "${DAQ_TESTING_COLOR_RED}Exit code: $exit_code${DAQ_TESTING_COLOR_RESET}" >&2
        __daq_t_execute_is_verbose && {
            echo "${DAQ_TESTING_COLOR_RED}Output:${DAQ_TESTING_COLOR_RESET}" >&2
            echo "${DAQ_TESTING_COLOR_RED}$output${DAQ_TESTING_COLOR_RESET}" >&2
        }
        return $exit_code
    fi

    __daq_t_execute_is_verbose && {
        echo "${DAQ_TESTING_COLOR_GREEN}Function: $func_name $*${DAQ_TESTING_COLOR_RESET}"
        echo "${DAQ_TESTING_COLOR_GREEN}Exit code: $exit_code${DAQ_TESTING_COLOR_RESET}"
        echo "${DAQ_TESTING_COLOR_GREEN}Output: ${output:0:100}...${DAQ_TESTING_COLOR_RESET}"
    }

    return $exit_code
}
