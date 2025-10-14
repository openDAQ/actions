#!/usr/bin/env bash
# Test runner for shell scripts
# Supports bash 3.2+ and zsh

set -euo pipefail

# Script directory detection
__DAQ_TESTS_RUNNER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
__DAQ_TESTS_CORE_DIR="${__DAQ_TESTS_RUNNER_DIR}/core"

# Load core modules
source "${__DAQ_TESTS_CORE_DIR}/compat.sh"
source "${__DAQ_TESTS_CORE_DIR}/log.sh"
source "${__DAQ_TESTS_CORE_DIR}/filter.sh"
source "${__DAQ_TESTS_CORE_DIR}/assert.sh"
source "${__DAQ_TESTS_CORE_DIR}/paths.sh"

# Initialize compatibility layer
__daq_tests_compat_init

# Initialize paths (convert Windows paths to Unix if needed)
__daq_tests_paths_init

# Global configuration variables
__DAQ_TESTS_SCRIPTS_DIR="${OPENDAQ_TESTS_SCRIPTS_DIR:-}"
__DAQ_TESTS_SUITES_DIR="${OPENDAQ_TESTS_SUITES_DIR:-}"
__DAQ_TESTS_FAIL_FAST=0
__DAQ_TESTS_DRY_RUN=0

# Statistics
__DAQ_TESTS_STATS_TOTAL_SUITES=0
__DAQ_TESTS_STATS_TOTAL_TESTS=0
__DAQ_TESTS_STATS_INCLUDED_TESTS=0
__DAQ_TESTS_STATS_EXCLUDED_TESTS=0
__DAQ_TESTS_STATS_PASSED_TESTS=0
__DAQ_TESTS_STATS_FAILED_TESTS=0

# Arrays to store discovered suites and tests
__DAQ_TESTS_DISCOVERED_SUITES=()
__DAQ_TESTS_DISCOVERED_TESTS=()

# Print help message
__daq_tests_print_help() {
    cat << 'EOF'
Test Runner for Shell Scripts

USAGE:
    test-runner.sh [OPTIONS]

OPTIONS:
    --scripts-dir <path>         Path to scripts directory (overrides OPENDAQ_TESTS_SCRIPTS_DIR)
    --suites-dir <path>          Path to test suites directory (overrides OPENDAQ_TESTS_SUITES_DIR)
    
    --include-test <pattern>     Include tests matching pattern (can be used multiple times)
    --exclude-test <pattern>     Exclude tests matching pattern (can be used multiple times)
    
    --fail-fast [true|false]     Stop on first failure (default: false)
    --dry-run                    Show what would be executed without running tests
    --verbose, -v                Enable verbose output
    
    --list-suites                List all discovered test suites
    --list-tests                 List all discovered tests
    --list-tests-included        List tests that will be executed
    --list-tests-excluded        List tests that will be excluded
    
    --help, -h                   Show this help message

PATTERN FORMAT:
    test-<suite-name>                    Match entire suite
    test-<suite-name>:test-<test-name>   Match specific test in suite
    
    Wildcards are supported:
    test-*                               All suites
    test-integration*:test-api*          All API tests in integration suites

EXAMPLES:
    # Run all tests
    ./test-runner.sh --suites-dir ./suites
    
    # Run only integration tests
    ./test-runner.sh --suites-dir ./suites --include-test "test-integration*"
    
    # Run all tests except slow ones
    ./test-runner.sh --suites-dir ./suites --exclude-test "*:test-*-slow"
    
    # Dry run with verbose output
    ./test-runner.sh --suites-dir ./suites --dry-run --verbose
    
    # Stop on first failure
    ./test-runner.sh --suites-dir ./suites --fail-fast true

ENVIRONMENT VARIABLES:
    OPENDAQ_TESTS_SCRIPTS_DIR    Default scripts directory
    OPENDAQ_TESTS_SUITES_DIR     Default suites directory

EOF
}

# Parse command line arguments
__daq_tests_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --scripts-dir)
                __DAQ_TESTS_SCRIPTS_DIR=$(__daq_tests_normalize_path "$2")
                shift 2
                ;;
            --suites-dir)
                __DAQ_TESTS_SUITES_DIR=$(__daq_tests_normalize_path "$2")
                shift 2
                ;;
            --include-test)
                daq_tests_filter_include_test "$2"
                shift 2
                ;;
            --exclude-test)
                daq_tests_filter_exclude_test "$2"
                shift 2
                ;;
            --fail-fast)
                if [[ "$2" == "true" ]]; then
                    __DAQ_TESTS_FAIL_FAST=1
                elif [[ "$2" == "false" ]]; then
                    __DAQ_TESTS_FAIL_FAST=0
                else
                    __daq_tests_log_error "Invalid value for --fail-fast: $2 (expected: true or false)"
                    return 1
                fi
                shift 2
                ;;
            --dry-run)
                __DAQ_TESTS_DRY_RUN=1
                shift
                ;;
            --verbose|-v)
                __daq_tests_log_enable_verbose
                shift
                ;;
            --list-suites)
                __DAQ_TESTS_MODE="list-suites"
                shift
                ;;
            --list-tests)
                __DAQ_TESTS_MODE="list-tests"
                shift
                ;;
            --list-tests-included)
                __DAQ_TESTS_MODE="list-tests-included"
                shift
                ;;
            --list-tests-excluded)
                __DAQ_TESTS_MODE="list-tests-excluded"
                shift
                ;;
            --help|-h)
                __daq_tests_print_help
                exit 0
                ;;
            *)
                __daq_tests_log_error "Unknown option: $1"
                __daq_tests_log_info ""
                __daq_tests_print_help
                return 1
                ;;
        esac
    done
    
    return 0
}

# Validate configuration
__daq_tests_validate_config() {
    if [[ -z "${__DAQ_TESTS_SUITES_DIR}" ]]; then
        __daq_tests_log_error "Suites directory not specified. Use --suites-dir or set OPENDAQ_TESTS_SUITES_DIR"
        return 1
    fi
    
    if [[ ! -d "${__DAQ_TESTS_SUITES_DIR}" ]]; then
        __daq_tests_log_error "Suites directory does not exist: ${__DAQ_TESTS_SUITES_DIR}"
        return 1
    fi
    
    # Scripts directory is optional, only validate if set
    if [[ -n "${__DAQ_TESTS_SCRIPTS_DIR}" ]] && [[ ! -d "${__DAQ_TESTS_SCRIPTS_DIR}" ]]; then
        __daq_tests_log_error "Scripts directory does not exist: ${__DAQ_TESTS_SCRIPTS_DIR}"
        return 1
    fi
    
    return 0
}

# Discover all test suites in suites directory
__daq_tests_discover_suites() {
    __DAQ_TESTS_DISCOVERED_SUITES=()
    
    __daq_tests_log_verbose "Discovering test suites in: ${__DAQ_TESTS_SUITES_DIR}"
    
    for suite_file in "${__DAQ_TESTS_SUITES_DIR}"/test-*.sh; do
        if [[ -f "${suite_file}" ]]; then
            local suite_name
            suite_name=$(basename "${suite_file}" .sh)
            __daq_tests_array_append "__DAQ_TESTS_DISCOVERED_SUITES" "${suite_name}"
            __daq_tests_log_verbose "  Found suite: ${suite_name}"
        fi
    done
    
    __DAQ_TESTS_STATS_TOTAL_SUITES=$(__daq_tests_array_size "__DAQ_TESTS_DISCOVERED_SUITES")
    __daq_tests_log_verbose "Total suites discovered: ${__DAQ_TESTS_STATS_TOTAL_SUITES}"
}

# Discover tests in a suite
# Arguments: suite_name
# Returns: list of test function names via echo
__daq_tests_discover_tests_in_suite() {
    local suite_name="$1"
    local suite_file="${__DAQ_TESTS_SUITES_DIR}/${suite_name}.sh"
    
    # Source the suite in a subshell to get function names
    (
        source "${suite_file}"
        __daq_tests_list_functions | grep "^test-"
    )
}

# Discover all tests in all suites
__daq_tests_discover_all_tests() {
    __DAQ_TESTS_DISCOVERED_TESTS=()
    
    __daq_tests_log_verbose "Discovering tests in all suites..."
    
    for suite_name in "${__DAQ_TESTS_DISCOVERED_SUITES[@]+"${__DAQ_TESTS_DISCOVERED_SUITES[@]}"}"; do
        __daq_tests_log_verbose "  Discovering tests in: ${suite_name}"
        
        local test_functions
        test_functions=$(__daq_tests_discover_tests_in_suite "${suite_name}")
        
        for test_name in ${test_functions}; do
            local full_test_name="${suite_name}:${test_name}"
            __daq_tests_array_append "__DAQ_TESTS_DISCOVERED_TESTS" "${full_test_name}"
            __daq_tests_log_verbose "    Found test: ${test_name}"
        done
    done
    
    __DAQ_TESTS_STATS_TOTAL_TESTS=$(__daq_tests_array_size "__DAQ_TESTS_DISCOVERED_TESTS")
    __daq_tests_log_verbose "Total tests discovered: ${__DAQ_TESTS_STATS_TOTAL_TESTS}"
}

# Calculate included/excluded test counts
__daq_tests_calculate_statistics() {
    __DAQ_TESTS_STATS_INCLUDED_TESTS=0
    __DAQ_TESTS_STATS_EXCLUDED_TESTS=0
    
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        local suite_name="${full_test_name%%:*}"
        local test_name="${full_test_name##*:}"
        
        if daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            __DAQ_TESTS_STATS_INCLUDED_TESTS=$((__DAQ_TESTS_STATS_INCLUDED_TESTS + 1))
        else
            __DAQ_TESTS_STATS_EXCLUDED_TESTS=$((__DAQ_TESTS_STATS_EXCLUDED_TESTS + 1))
        fi
    done
}

# List all suites
__daq_tests_list_suites() {
    for suite_name in "${__DAQ_TESTS_DISCOVERED_SUITES[@]+"${__DAQ_TESTS_DISCOVERED_SUITES[@]}"}"; do
        echo "${suite_name}"
    done
}

# List all tests
__daq_tests_list_tests() {
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        echo "${full_test_name}"
    done
}

# List included tests
__daq_tests_list_tests_included() {
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        local suite_name="${full_test_name%%:*}"
        local test_name="${full_test_name##*:}"
        
        if daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            echo "${full_test_name}"
        fi
    done
}

# List excluded tests
__daq_tests_list_tests_excluded() {
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        local suite_name="${full_test_name%%:*}"
        local test_name="${full_test_name##*:}"
        
        if ! daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            echo "${full_test_name}"
        fi
    done
}

# Dry run output (non-verbose)
__daq_tests_dry_run() {
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        local suite_name="${full_test_name%%:*}"
        local test_name="${full_test_name##*:}"
        
        if daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            echo "+${full_test_name}"
        else
            echo "-${full_test_name}"
        fi
    done
}

# Dry run output (verbose)
__daq_tests_dry_run_verbose() {
    local current_suite=""
    
    for full_test_name in "${__DAQ_TESTS_DISCOVERED_TESTS[@]+"${__DAQ_TESTS_DISCOVERED_TESTS[@]}"}"; do
        local suite_name="${full_test_name%%:*}"
        local test_name="${full_test_name##*:}"
        
        # Print suite header if changed
        if [[ "${suite_name}" != "${current_suite}" ]]; then
            if [[ -n "${current_suite}" ]]; then
                echo ""
            fi
            echo "${suite_name}"
            current_suite="${suite_name}"
        fi
        
        # Print test with status
        if daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            echo "  ✅ ${test_name}"
        else
            echo "  ⚫ ${test_name}"
        fi
    done
}

# Run a single test
# Arguments: suite_name test_name
# Returns: 0 on success, 1 on failure
__daq_tests_run_test() {
    local suite_name="$1"
    local test_name="$2"
    local suite_file="${__DAQ_TESTS_SUITES_DIR}/${suite_name}.sh"
    
    __daq_tests_log_verbose "  Running: ${test_name}"
    
    # Run test in subshell for isolation
    (
        set -euo pipefail
        source "${suite_file}"
        
        # Call test_setup if it exists
        if __daq_tests_function_exists "test_setup"; then
            __daq_tests_log_verbose "    Running test_setup"
            if ! test_setup; then
                __daq_tests_log_error "    test_setup failed for ${test_name}"
                exit 1
            fi
        fi
        
        # Run the actual test
        if ! "${test_name}"; then
            # Test failed
            exit 1
        fi
        
        # Call test_teardown if it exists (even if test failed)
        if __daq_tests_function_exists "test_teardown"; then
            __daq_tests_log_verbose "    Running test_teardown"
            # Don't fail on teardown errors, just warn
            test_teardown || __daq_tests_log_warn "    test_teardown failed for ${test_name}"
        fi
    )
    
    local result=$?
    
    if [[ ${result} -eq 0 ]]; then
        if __daq_tests_log_is_verbose; then
            __daq_tests_log_success "    ${test_name}"
        fi
        return 0
    else
        __daq_tests_log_error "    ${test_name} FAILED"
        return 1
    fi
}

# Run all tests in a suite
# Arguments: suite_name
__daq_tests_run_suite() {
    local suite_name="$1"
    
    __daq_tests_log_info "Running suite: ${suite_name}"
    
    # Get all tests for this suite
    local suite_tests
    suite_tests=$(__daq_tests_discover_tests_in_suite "${suite_name}")
    
    for test_name in ${suite_tests}; do
        # Check if test should run
        if ! daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
            __daq_tests_log_verbose "  Skipping: ${test_name} (excluded)"
            continue
        fi
        
        # Run the test
        if __daq_tests_run_test "${suite_name}" "${test_name}"; then
            __DAQ_TESTS_STATS_PASSED_TESTS=$((__DAQ_TESTS_STATS_PASSED_TESTS + 1))
        else
            __DAQ_TESTS_STATS_FAILED_TESTS=$((__DAQ_TESTS_STATS_FAILED_TESTS + 1))
            
            # Check fail-fast mode
            if [[ ${__DAQ_TESTS_FAIL_FAST} -eq 1 ]]; then
                __daq_tests_log_error "Stopping due to --fail-fast"
                return 1
            fi
        fi
    done
    
    return 0
}

# Run all tests
__daq_tests_run_all() {
    __daq_tests_log_info "Running tests..."
    __daq_tests_log_info ""
    
    for suite_name in "${__DAQ_TESTS_DISCOVERED_SUITES[@]+"${__DAQ_TESTS_DISCOVERED_SUITES[@]}"}"; do
        # Check if any test in suite should run
        local should_run_suite=0
        local suite_tests
        suite_tests=$(__daq_tests_discover_tests_in_suite "${suite_name}")
        
        for test_name in ${suite_tests}; do
            if daq_tests_filter_should_run_test "${suite_name}" "${test_name}"; then
                should_run_suite=1
                break
            fi
        done
        
        if [[ ${should_run_suite} -eq 0 ]]; then
            __daq_tests_log_verbose "Skipping suite: ${suite_name} (all tests excluded)"
            continue
        fi
        
        # Run the suite
        if ! __daq_tests_run_suite "${suite_name}"; then
            if [[ ${__DAQ_TESTS_FAIL_FAST} -eq 1 ]]; then
                return 1
            fi
        fi
        
        __daq_tests_log_info ""
    done
    
    return 0
}

# Print final statistics
__daq_tests_print_statistics() {
    __daq_tests_log_info "============================================"
    __daq_tests_log_info "Test Results"
    __daq_tests_log_info "============================================"
    __daq_tests_log_info "Total suites:    ${__DAQ_TESTS_STATS_TOTAL_SUITES}"
    __daq_tests_log_info "Total tests:     ${__DAQ_TESTS_STATS_TOTAL_TESTS}"
    __daq_tests_log_info "Included tests:  ${__DAQ_TESTS_STATS_INCLUDED_TESTS}"
    __daq_tests_log_info "Excluded tests:  ${__DAQ_TESTS_STATS_EXCLUDED_TESTS}"
    __daq_tests_log_info ""
    
    if [[ ${__DAQ_TESTS_DRY_RUN} -eq 0 ]]; then
        __daq_tests_log_success "Passed:  ${__DAQ_TESTS_STATS_PASSED_TESTS}"
        
        if [[ ${__DAQ_TESTS_STATS_FAILED_TESTS} -gt 0 ]]; then
            __daq_tests_log_error "Failed:  ${__DAQ_TESTS_STATS_FAILED_TESTS}"
        else
            __daq_tests_log_info "Failed:  ${__DAQ_TESTS_STATS_FAILED_TESTS}"
        fi
    fi
    __daq_tests_log_info "============================================"
}

# Main function
__daq_tests_main() {
    # Initialize filters
    daq_tests_filters_init
    
    # Parse arguments
    if ! __daq_tests_parse_args "$@"; then
        return 1
    fi
    
    # Validate configuration
    if ! __daq_tests_validate_config; then
        return 1
    fi
    
    # Discover suites and tests
    __daq_tests_discover_suites
    __daq_tests_discover_all_tests
    __daq_tests_calculate_statistics
    
    # Handle different modes
    if [[ "${__DAQ_TESTS_MODE:-}" == "list-suites" ]]; then
        __daq_tests_list_suites
        return 0
    elif [[ "${__DAQ_TESTS_MODE:-}" == "list-tests" ]]; then
        __daq_tests_list_tests
        return 0
    elif [[ "${__DAQ_TESTS_MODE:-}" == "list-tests-included" ]]; then
        __daq_tests_list_tests_included
        return 0
    elif [[ "${__DAQ_TESTS_MODE:-}" == "list-tests-excluded" ]]; then
        __daq_tests_list_tests_excluded
        return 0
    fi
    
    # Handle dry-run mode
    if [[ ${__DAQ_TESTS_DRY_RUN} -eq 1 ]]; then
        if __daq_tests_log_is_verbose; then
            __daq_tests_dry_run_verbose
        else
            __daq_tests_dry_run
        fi
        __daq_tests_log_info ""
        __daq_tests_print_statistics
        return 0
    fi
    
    # Run tests
    __daq_tests_run_all
    local result=$?
    
    # Print statistics
    __daq_tests_print_statistics
    
    # Return appropriate exit code
    if [[ ${__DAQ_TESTS_STATS_FAILED_TESTS} -gt 0 ]]; then
        return 1
    fi
    
    return ${result}
}

# Only run main if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]:-${(%):-%x}}" == "${0}" ]]; then
    __daq_tests_main "$@"
fi
