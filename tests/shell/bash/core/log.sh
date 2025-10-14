#!/usr/bin/env bash
# Logging utilities for test runner

# Global logging configuration
__DAQ_TESTS_LOG_VERBOSE=0

# Regular info message (always shown)
__daq_tests_log_info() {
    echo "$@"
}

# Verbose message (only shown when --verbose is enabled)
__daq_tests_log_verbose() {
    if [[ "${__DAQ_TESTS_LOG_VERBOSE}" == "1" ]]; then
        echo "$@"
    fi
}

# Warning message (only shown when --verbose is enabled, goes to stderr)
__daq_tests_log_warn() {
    if [[ "${__DAQ_TESTS_LOG_VERBOSE}" == "1" ]]; then
        echo "⚠️  $*" >&2
    fi
}

# Error message (always shown, goes to stderr)
__daq_tests_log_error() {
    echo "❌ $*" >&2
}

# Success message
__daq_tests_log_success() {
    echo "✅ $*"
}

# Enable verbose logging
__daq_tests_log_enable_verbose() {
    __DAQ_TESTS_LOG_VERBOSE=1
}

# Disable verbose logging
__daq_tests_log_disable_verbose() {
    __DAQ_TESTS_LOG_VERBOSE=0
}

# Check if verbose logging is enabled
__daq_tests_log_is_verbose() {
    [[ "${__DAQ_TESTS_LOG_VERBOSE}" == "1" ]]
}
