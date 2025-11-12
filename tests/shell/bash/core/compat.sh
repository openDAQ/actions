#!/usr/bin/env bash
# Compatibility layer for bash 3.2+, bash 4+, and zsh
# This module provides shell-agnostic functions for common operations

# Global variables for shell detection
__DAQ_TESTS_SHELL=""
__DAQ_TESTS_SHELL_MAJOR=""
__DAQ_TESTS_SHELL_MINOR=""

# Detect current shell and version
__daq_tests_detect_shell() {
    if [[ -n "${BASH_VERSION:-}" ]]; then
        __DAQ_TESTS_SHELL="bash"
        __DAQ_TESTS_SHELL_MAJOR="${BASH_VERSINFO[0]}"
        __DAQ_TESTS_SHELL_MINOR="${BASH_VERSINFO[1]}"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        __DAQ_TESTS_SHELL="zsh"
        __DAQ_TESTS_SHELL_MAJOR="${ZSH_VERSION%%.*}"
        local temp="${ZSH_VERSION#*.}"
        __DAQ_TESTS_SHELL_MINOR="${temp%%.*}"
    else
        echo "❌ Unsupported shell. Only bash and zsh are supported." >&2
        exit 1
    fi
    
    # Check minimum bash version requirement (3.2+)
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        if [[ "${__DAQ_TESTS_SHELL_MAJOR}" -lt 3 ]] || \
           [[ "${__DAQ_TESTS_SHELL_MAJOR}" -eq 3 && "${__DAQ_TESTS_SHELL_MINOR}" -lt 2 ]]; then
            echo "❌ bash 3.2 or higher required (found ${BASH_VERSION})" >&2
            exit 1
        fi
    fi
}

# Initialize compatibility layer
__daq_tests_compat_init() {
    __daq_tests_detect_shell
    return 0
}

# Check if script is being sourced or executed directly
__daq_tests_is_sourced() {
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        [[ "${BASH_SOURCE[0]}" != "${0}" ]]
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        [[ "${ZSH_EVAL_CONTEXT}" == *:file:* ]]
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Get the path to the current script
__daq_tests_get_script_path() {
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        echo "${BASH_SOURCE[0]}"
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        echo "${(%):-%x}"
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Get the directory of the current script
__daq_tests_get_script_dir() {
    local script_path
    script_path="$(__daq_tests_get_script_path)"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        dirname "${script_path}"
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        dirname "${script_path}"
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# List all defined functions
__daq_tests_list_functions() {
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        declare -F | awk '{print $3}'
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        print -l ${(k)functions}
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# List all defined variables
__daq_tests_list_variables() {
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        compgen -v
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        print -l ${(k)parameters}
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# List all defined aliases
__daq_tests_list_aliases() {
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        alias | cut -d'=' -f1 | sed 's/^alias //'
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        alias | cut -d'=' -f1
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Pattern matching using case (works the same in bash and zsh)
__daq_tests_match_pattern() {
    local string="$1"
    local pattern="$2"
    
    case "${string}" in
        ${pattern})
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Append element to array (array name passed as string)
__daq_tests_array_append() {
    local array_name="$1"
    local value="$2"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        eval "${array_name}+=(\"\${value}\")"
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        eval "${array_name}+=(\"\${value}\")"
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Get array size (array name passed as string)
__daq_tests_array_size() {
    local array_name="$1"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        eval "echo \${#${array_name}[@]}"
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        eval "echo \${#${array_name}[@]}"
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Check if array contains element
__daq_tests_array_contains() {
    local array_name="$1"
    local search_value="$2"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        eval "
        for __item in \"\${${array_name}[@]}\"; do
            if [[ \"\${__item}\" == \"\${search_value}\" ]]; then
                return 0
            fi
        done
        "
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        eval "
        for __item in \"\${${array_name}[@]}\"; do
            if [[ \"\${__item}\" == \"\${search_value}\" ]]; then
                return 0
            fi
        done
        "
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
    
    return 1
}

# Unset function by name
__daq_tests_unset_function() {
    local func_name="$1"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        unset -f "${func_name}" 2>/dev/null
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        unset -f "${func_name}" 2>/dev/null
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Unset variable by name
__daq_tests_unset_variable() {
    local var_name="$1"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        unset "${var_name}" 2>/dev/null
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        unset "${var_name}" 2>/dev/null
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Unset alias by name
__daq_tests_unset_alias() {
    local alias_name="$1"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        unalias "${alias_name}" 2>/dev/null
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        unalias "${alias_name}" 2>/dev/null
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}

# Check if function exists
# Arguments: function_name
# Returns: 0 if function exists, 1 if not
__daq_tests_function_exists() {
    local func_name="$1"
    
    if [[ "${__DAQ_TESTS_SHELL}" == "bash" ]]; then
        declare -F "${func_name}" &>/dev/null
    elif [[ "${__DAQ_TESTS_SHELL}" == "zsh" ]]; then
        [[ -n "${functions[$func_name]}" ]]
    else
        echo "❌ Unsupported shell: ${__DAQ_TESTS_SHELL}" >&2
        exit 1
    fi
}
