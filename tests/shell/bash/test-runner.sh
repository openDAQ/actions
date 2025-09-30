#!/bin/bash
################################################################################
# Module: test-runner (testing framework)
# Version: 1.0.1
# Description: Test runner for openDAQ shell scripts with hierarchical filtering
#
# Usage:
#   test-runner.sh [OPTIONS] [SUITE[:TESTS]...]
#
# Dependencies: core/common.sh, core/reporter.sh, core/filter.sh, core/assertion.sh
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#   2 - Configuration or setup error
################################################################################

################################################################################
# SCRIPT METADATA
################################################################################

readonly DAQ_TESTING_RUNNER_VERSION="1.0.1"
readonly DAQ_TESTING_RUNNER_BUILD_DATE="2025-01-15"
readonly DAQ_TESTING_RUNNER_NAME="openDAQ Test Runner"

################################################################################
# CONFIGURATION - Paths
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
TEST_RUNNER_DIR="$SCRIPT_DIR"
CORE_DIR="$TEST_RUNNER_DIR/core"
SUITES_DIR="$TEST_RUNNER_DIR/suites"

################################################################################
# GLOBAL STATE - Multi-Suite Counters
################################################################################

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
GRAND_TOTAL_TESTS=0
GRAND_PASSED_TESTS=0
GRAND_FAILED_TESTS=0
GRAND_SKIPPED_TESTS=0

################################################################################
# GLOBAL STATE - Runner Configuration
################################################################################

__DAQ_TESTING_RUNNER_VERBOSE=false
__DAQ_TESTING_RUNNER_DEBUG=false
__DAQ_TESTING_RUNNER_CONTINUE_ON_FAIL=false

# Global filter variables (shared across all suites)
GLOBAL_EXCLUDED_TESTS=""
GLOBAL_EXCLUDED_SUITES=""
GLOBAL_REGEX_FILTER=""

################################################################################
# DEPENDENCY LOADING
################################################################################

# Load core modules
if [ ! -f "$CORE_DIR/common.sh" ]; then
    echo "ERROR: Core module not found: $CORE_DIR/common.sh" >&2
    exit 2
fi

source "$CORE_DIR/common.sh"
source "$CORE_DIR/reporter.sh"
source "$CORE_DIR/filter.sh"
source "$CORE_DIR/assertion.sh"

################################################################################
# HELP SYSTEM - Short Help
################################################################################

__daq_testing_runner_help_short() {
    cat << 'EOF'
openDAQ Test Runner - Execute test suites with filtering

USAGE:
  test-runner.sh [OPTIONS] [SUITE[:TESTS]...]

OPTIONS:
  -h, --help              Show detailed help
  -l, --list              List available test suites
  -v, --verbose           Verbose output
  -d, --debug             Debug output
  --scripts-dir DIR       Directory containing scripts to test
  --continue-on-fail      Continue running suites even if one fails
  --filter PATTERN        Run only tests matching regex pattern
  --exclude-suite SUITE   Exclude specific test suite(s) - comma separated
  --exclude-test TEST     Exclude specific test(s) - comma separated
  --list-tests [SUITE]    List all tests in suite(s)

ARGUMENTS:
  SUITE[:TESTS]           Test suite with optional specific tests
                          SUITE - run all tests in suite
                          SUITE:test1,test2 - run only specified tests
                          If no suites specified, runs all available suites

EXAMPLES:
  test-runner.sh
  test-runner.sh version-format
  test-runner.sh version-format:basic,validation --verbose
  test-runner.sh --exclude-test "slow-test" --filter "validation.*"

For detailed help: test-runner.sh --help

EOF
}

################################################################################
# HELP SYSTEM - Full Help
################################################################################

__daq_testing_runner_help() {
    cat << 'EOF'
openDAQ Test Runner - Execute test suites with filtering

DESCRIPTION:
  Run test suites for openDAQ scripts with advanced filtering capabilities.
  Supports hierarchical filtering: positive specification → exclusions → regex.

USAGE:
  test-runner.sh [OPTIONS] [SUITE[:TESTS]...]

═══════════════════════════════════════════════════════════════════════════════
OPTIONS
═══════════════════════════════════════════════════════════════════════════════

  -h, --help              Show this help message
  -l, --list              List available test suites
  -v, --verbose           Verbose output (show test execution details)
  -d, --debug             Debug output (show internal operations)
  --scripts-dir DIR       Directory containing scripts to test (default: parent dir)
  --continue-on-fail      Continue running suites even if one fails
  --filter PATTERN        Run only tests matching regex pattern
  --exclude-suite SUITE   Exclude specific test suite(s) - comma separated
  --exclude-test TEST     Exclude specific test(s) from all suites - comma separated
  --list-tests [SUITE]    List all tests in suite(s) or all if none specified

═══════════════════════════════════════════════════════════════════════════════
FILTERING HIERARCHY (by priority)
═══════════════════════════════════════════════════════════════════════════════

  1. Positive specification: suite:test1,test2 (highest priority)
  2. Exclusions: --exclude-suite, --exclude-test
  3. Regex filter: --filter "pattern" (lowest priority)

═══════════════════════════════════════════════════════════════════════════════
ARGUMENTS
═══════════════════════════════════════════════════════════════════════════════

  SUITE[:TESTS]           Test suite with optional specific tests
                          SUITE - run all tests in suite
                          SUITE:test1,test2 - run only specified tests in suite
                          If no suites specified, runs all available suites

═══════════════════════════════════════════════════════════════════════════════
EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

  # Basic usage
  test-runner.sh
      Run all available test suites

  test-runner.sh version-format
      Run all tests in version-format suite

  # Positive specification (highest priority)
  test-runner.sh version-format:validation,format
      Run only "validation" and "format" tests in version-format suite

  test-runner.sh version-format:basic suite2:simple
      Run specific tests from multiple suites

  # Exclusions (second priority)
  test-runner.sh --exclude-suite deprecated-suite
      Run all suites except deprecated-suite

  test-runner.sh --exclude-test "flaky-test,slow-test"
      Run all tests except those named "flaky-test" or "slow-test"

  test-runner.sh version-format --exclude-test "edge-case"
      Run version-format suite excluding "edge-case" test

  # Regex filtering (lowest priority)
  test-runner.sh --filter "validation.*"
      Run tests matching regex pattern in all suites

  test-runner.sh version-format --filter "validation|verbose"
      Run tests matching "validation" OR "verbose" in version-format

  # Combined filtering (follows hierarchy)
  test-runner.sh version-format:validation,format \
    --exclude-test "slow-test" \
    --filter "verbose"
      1. Include only "validation,format" from version-format
      2. Exclude any tests named "slow-test"
      3. From remaining, only run tests matching "verbose"

  # Investigation and debugging
  test-runner.sh --list-tests
      List all test names in all suites

  test-runner.sh --list-tests version-format
      List all test names in specific suite

  test-runner.sh --list
      List all available test suites

  test-runner.sh version-format --verbose --debug
      Run with verbose and debug output

═══════════════════════════════════════════════════════════════════════════════
DIRECTORY STRUCTURE
═══════════════════════════════════════════════════════════════════════════════

  tests/
  ├── test-runner.sh              # This script
  ├── core/
  │   ├── common.sh               # Common utilities and state
  │   ├── reporter.sh             # Output formatting
  │   ├── filter.sh               # Test filtering logic
  │   └── assertion.sh            # Test assertion functions
  ├── suites/
  │   ├── test-version-format.sh
  │   └── test-<other-suite>.sh
  └── scripts/                    # Or parent directory with actual scripts
      └── version-format.sh

VERSION: $DAQ_TESTING_RUNNER_VERSION
BUILD:   $DAQ_TESTING_RUNNER_BUILD_DATE

EOF
}

################################################################################
# PRIVATE FUNCTIONS - Suite Discovery
################################################################################

# List available test suites
# Returns: 0 always
__daq_testing_runner_list_suites() {
    echo "Available test suites:"
    for suite_file in "$SUITES_DIR"/test-*.sh; do
        if [ -f "$suite_file" ]; then
            local suite_name=$(basename "$suite_file" .sh)
            suite_name=${suite_name#test-}
            echo "  $suite_name"
        fi
    done
}

# Extract test names from a suite file
# Args: $1 - path to suite file
# Returns: List of test names (one per line)
__daq_testing_runner_extract_test_names() {
    local suite_file="$1"
    
    if [ ! -f "$suite_file" ]; then
        return 1
    fi
    
    # Extract test function names
    grep -E '^\s*test_[a-zA-Z0-9_]+\(\)' "$suite_file" | \
        sed -E 's/^\s*test_([a-zA-Z0-9_]+)\(\).*/test_\1/' | \
        sort | uniq
}

# List tests in specific suite(s) or all suites
# Args: $1... - suite names (optional)
# Returns: 0 always
__daq_testing_runner_list_tests() {
    local target_suites=("$@")
    
    # If no suites specified, list all
    if [ ${#target_suites[@]} -eq 0 ]; then
        echo "All available tests by suite:"
        for suite_file in "$SUITES_DIR"/test-*.sh; do
            if [ -f "$suite_file" ]; then
                local suite_name=$(basename "$suite_file" .sh)
                suite_name=${suite_name#test-}
                echo
                echo "Suite: $suite_name"
                __daq_testing_runner_extract_test_names "$suite_file" | sed 's/^/  /'
            fi
        done
        return 0
    fi
    
    # List tests for specified suites
    for suite_spec in "${target_suites[@]}"; do
        local suite_name=$(basename "$suite_spec")
        if ! echo "$suite_name" | grep -q "^test-"; then
            suite_name="test-${suite_name}"
        fi
        
        local suite_file="$SUITES_DIR/${suite_name}.sh"
        
        if [ ! -f "$suite_file" ]; then
            daq_testing_common_log_error "Test suite not found: $suite_file"
            continue
        fi
        
        echo "Tests in suite '${suite_name#test-}':"
        __daq_testing_runner_extract_test_names "$suite_file" | sed 's/^/  /'
        echo
    done
}

################################################################################
# PRIVATE FUNCTIONS - Script Path Discovery
################################################################################

# Find script path for a given suite
# Args: $1 - suite name
#       $2 - scripts directory
# Returns: Script path if found, empty otherwise
__daq_testing_runner_find_script_path() {
    local suite_name="$1"
    local scripts_dir="$2"
    
    # Try different possible script names and locations
    # Adjusted for structure: tests/shell/bash/ -> scripts/shell/bash/core/
    local possible_paths=(
        "$scripts_dir/${suite_name}.sh"
        "$scripts_dir/$suite_name"
        "$scripts_dir/core/${suite_name}.sh"
        "$scripts_dir/core/$suite_name"
        "$SCRIPT_DIR/../../../scripts/shell/bash/core/${suite_name}.sh"
        "$SCRIPT_DIR/../../../scripts/shell/bash/core/$suite_name"
        "$SCRIPT_DIR/../../../scripts/shell/bash/${suite_name}.sh"
        "$SCRIPT_DIR/../../../scripts/shell/bash/$suite_name"
        "$SCRIPT_DIR/../../${suite_name}/${suite_name}.sh"
        "$SCRIPT_DIR/../../${suite_name}/${suite_name}"
        "$SCRIPT_DIR/../${suite_name}/${suite_name}.sh"
        "$SCRIPT_DIR/../${suite_name}/${suite_name}"
        "$SCRIPT_DIR/../../${suite_name}.sh"
        "$SCRIPT_DIR/../../$suite_name"
        "$SCRIPT_DIR/../${suite_name}.sh"
        "$SCRIPT_DIR/../$suite_name"
        "./${suite_name}.sh"
        "./$suite_name"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

################################################################################
# PRIVATE FUNCTIONS - Test Discovery and Execution
################################################################################

# Discover test functions from sourced suite
# Returns: Array of test function names
__daq_testing_runner_discover_tests() {
    local test_functions=()
    
    # Find all functions starting with "test_"
    if [ -n "$BASH_VERSION" ]; then
        # Bash
        while IFS= read -r func; do
            test_functions+=("$func")
        done < <(declare -F | grep "declare -f test_" | awk '{print $3}')
    elif [ -n "$ZSH_VERSION" ]; then
        # Zsh
        test_functions=(${(k)functions[(I)test_*]})
    fi
    
    # Return as space-separated string
    echo "${test_functions[@]}"
}

################################################################################
# PRIVATE FUNCTIONS - Suite Execution
################################################################################

# Run a single test suite with filtering
# Args: $1 - suite specification (suite or suite:test1,test2)
#       $2 - scripts directory
# Returns: 0 if all tests passed, 1 if any failed
__daq_testing_runner_execute_suite() {
    local suite_spec="$1"
    local scripts_dir="$2"
    
    # Parse suite specification
    local parse_result
    parse_result=$(daq_testing_filter_parse_suite_spec "$suite_spec")
    local suite_name=$(echo "$parse_result" | sed -n '1p')
    local positive_tests=$(echo "$parse_result" | sed -n '2p')
    
    # Clean suite name - remove any path prefixes
    suite_name=$(basename "$suite_name")
    
    # Check if suite is excluded
    if daq_testing_filter_is_suite_excluded "$suite_name"; then
        daq_testing_reporter_warning "Skipping excluded suite: $suite_name"
        return 0
    fi
    
    local suite_file="$SUITES_DIR/${suite_name}.sh"
    
    # If suite_name doesn't start with "test-", add it
    if ! echo "$suite_name" | grep -q "^test-"; then
        suite_file="$SUITES_DIR/test-${suite_name}.sh"
        suite_name="test-${suite_name}"
    fi
    
    if [ ! -f "$suite_file" ]; then
        daq_testing_reporter_error "Test suite not found: $suite_file"
        echo "Available suites:"
        __daq_testing_runner_list_suites
        return 1
    fi
    
    # Extract component name from suite name (remove test- prefix)
    local component_name="${suite_name#test-}"
    
    # Find the script to test
    local script_path
    script_path=$(__daq_testing_runner_find_script_path "$component_name" "$scripts_dir")
    if [ $? -ne 0 ]; then
        daq_testing_reporter_error "Script not found for suite '$suite_name'"
        daq_testing_reporter_info "Searched for component: $component_name"
        daq_testing_reporter_info "Searched in: $scripts_dir and relative paths"
        return 1
    fi
    
    # Print suite banner
    local filtering_info=""
    if daq_testing_filter_is_enabled; then
        filtering_info=$(daq_testing_filter_get_summary)
    fi
    daq_testing_reporter_suite_banner "$suite_name" "$script_path" "$filtering_info"
    
    # Initialize test framework for this suite
    if ! daq_testing_common_init "$script_path" "$suite_name" "$__DAQ_TESTING_RUNNER_VERBOSE" "$__DAQ_TESTING_RUNNER_DEBUG"; then
        return 1
    fi
    
    # Update filter with positive tests from suite spec
    daq_testing_filter_init "$positive_tests" "$GLOBAL_EXCLUDED_TESTS" "$GLOBAL_EXCLUDED_SUITES" "$GLOBAL_REGEX_FILTER"
    
    # Source the test suite
    if ! source "$suite_file"; then
        daq_testing_reporter_error "Failed to source test suite: $suite_file"
        return 1
    fi
    
    # Discover test functions
    local test_functions
    test_functions=$(__daq_testing_runner_discover_tests)
    
    if [ -z "$test_functions" ]; then
        daq_testing_reporter_warning "No test functions found in suite: $suite_name"
        return 0
    fi
    
    # Run suite setup if exists
    if declare -f test_suite_setup >/dev/null 2>&1; then
        test_suite_setup
    fi
    
    # Run each test function
    for test_func in $test_functions; do
        # Apply filtering
        if ! daq_testing_filter_should_run "$test_func"; then
            daq_testing_common_increment_skipped

            # Show skip only in verbose/debug mode
            if [ "$__DAQ_TESTING_RUNNER_VERBOSE" = "true" ] || [ "$__DAQ_TESTING_RUNNER_DEBUG" = "true" ]; then
                daq_testing_reporter_test_start "$test_func"
                daq_testing_reporter_skip "$test_func" "filtered"
            fi
            continue
        fi
        
        # Reset test state
        daq_testing_common_reset_test_state
        daq_testing_common_increment_total
        
        # Run test setup if exists
        if declare -f test_setup >/dev/null 2>&1; then
            test_setup
        fi

        # Report test start
        daq_testing_reporter_test_start "$test_func"

        # Run the test function
        if $test_func; then
            if ! daq_testing_common_is_test_failed; then
                daq_testing_common_increment_passed
                daq_testing_reporter_test_end "$test_func" "PASS"
            else
                daq_testing_common_increment_failed
                daq_testing_reporter_test_end "$test_func" "FAIL"
            fi
        else
            daq_testing_common_increment_failed
            daq_testing_reporter_test_end "$test_func" "FAIL"
        fi
        
        # Run test teardown if exists
        if declare -f test_teardown >/dev/null 2>&1; then
            test_teardown
        fi
    done
    
    # Run suite teardown if exists
    if declare -f test_suite_teardown >/dev/null 2>&1; then
        test_suite_teardown
    fi
    
    # Get results from this suite
    local results
    results=$(daq_testing_common_get_results)
    local suite_total=$(echo "$results" | cut -d' ' -f1)
    local suite_passed=$(echo "$results" | cut -d' ' -f2)
    local suite_failed=$(echo "$results" | cut -d' ' -f3)
    local suite_skipped=$(echo "$results" | cut -d' ' -f4)
    
    # Update grand totals
    GRAND_TOTAL_TESTS=$((GRAND_TOTAL_TESTS + suite_total))
    GRAND_PASSED_TESTS=$((GRAND_PASSED_TESTS + suite_passed))
    GRAND_FAILED_TESTS=$((GRAND_FAILED_TESTS + suite_failed))
    GRAND_SKIPPED_TESTS=$((GRAND_SKIPPED_TESTS + suite_skipped)) 
    
    # Print suite summary
    if daq_testing_reporter_suite_summary; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
        daq_testing_reporter_info "Suite '$suite_name' PASSED"
        return 0
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        daq_testing_reporter_error "Suite '$suite_name' FAILED"
        return 1
    fi
}

################################################################################
# PUBLIC API - Main Runner
################################################################################

# Main runner function
# Args: $@... - command line arguments
# Returns: 0 if all tests passed, 1 if any failed, 2 if configuration error
daq_testing_runner_main() {
    # Default scripts directory adjusted for project structure
    local scripts_dir="$SCRIPT_DIR/../../../scripts/shell/bash"
    local list_tests_suites=()
    local suites_to_run=()
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                __daq_testing_runner_help
                exit 0
                ;;
            -l|--list)
                __daq_testing_runner_list_suites
                exit 0
                ;;
            -v|--verbose)
                __DAQ_TESTING_RUNNER_VERBOSE=true
                shift
                ;;
            -d|--debug)
                __DAQ_TESTING_RUNNER_DEBUG=true
                shift
                ;;
            --scripts-dir)
                if [ $# -lt 2 ]; then
                    echo "ERROR: --scripts-dir requires a directory argument" >&2
                    exit 2
                fi
                scripts_dir="$2"
                shift 2
                ;;
            --continue-on-fail)
                __DAQ_TESTING_RUNNER_CONTINUE_ON_FAIL=true
                shift
                ;;
            --filter)
                if [ $# -lt 2 ]; then
                    echo "ERROR: --filter requires a pattern argument" >&2
                    exit 2
                fi
                GLOBAL_REGEX_FILTER="$2"
                shift 2
                ;;
            --exclude-suite)
                if [ $# -lt 2 ]; then
                    echo "ERROR: --exclude-suite requires suite name(s)" >&2
                    exit 2
                fi
                GLOBAL_EXCLUDED_SUITES="$2"
                shift 2
                ;;
            --exclude-test)
                if [ $# -lt 2 ]; then
                    echo "ERROR: --exclude-test requires test name(s)" >&2
                    exit 2
                fi
                GLOBAL_EXCLUDED_TESTS="$2"
                shift 2
                ;;
            --list-tests)
                # Check if next argument is a suite name or another option
                if [ $# -gt 1 ] && ! echo "$2" | grep -q "^-"; then
                    list_tests_suites+=("$2")
                    shift 2
                else
                    # No suite specified, list all
                    shift
                fi
                # Execute list-tests immediately
                __daq_testing_runner_list_tests "${list_tests_suites[@]}"
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 2
                ;;
            *)
                suites_to_run+=("$1")
                shift
                ;;
        esac
    done
    
    # If no suites specified, find all available suites
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        for suite_file in "$SUITES_DIR"/test-*.sh; do
            if [ -f "$suite_file" ]; then
                local suite_name=$(basename "$suite_file" .sh)
                suite_name=${suite_name#test-}
                
                # Check if suite is excluded
                if [ -n "$GLOBAL_EXCLUDED_SUITES" ]; then
                    daq_testing_filter_init "" "" "$GLOBAL_EXCLUDED_SUITES" ""
                    if ! daq_testing_filter_is_suite_excluded "$suite_name"; then
                        suites_to_run+=("$suite_name")
                    fi
                else
                    suites_to_run+=("$suite_name")
                fi
            fi
        done
    fi
    
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        echo "No test suites found in $SUITES_DIR" >&2
        if [ -n "$GLOBAL_EXCLUDED_SUITES" ]; then
            echo "Note: Some suites may have been excluded: $GLOBAL_EXCLUDED_SUITES" >&2
        fi
        echo "Use --list to see available suites" >&2
        exit 2
    fi
    
    # Print runner banner
    daq_testing_reporter_runner_banner "$DAQ_TESTING_RUNNER_NAME" "$DAQ_TESTING_RUNNER_VERSION"
    echo "Scripts directory: $scripts_dir"
    echo "Test suites to run: ${suites_to_run[*]}"
    
    # Show active filters
    local filters_active=false
    if [ -n "$GLOBAL_EXCLUDED_SUITES" ]; then
        echo "Excluded suites: $GLOBAL_EXCLUDED_SUITES"
        filters_active=true
    fi
    if [ -n "$GLOBAL_EXCLUDED_TESTS" ]; then
        echo "Excluded tests: $GLOBAL_EXCLUDED_TESTS"
        filters_active=true
    fi
    if [ -n "$GLOBAL_REGEX_FILTER" ]; then
        echo "Regex filter: $GLOBAL_REGEX_FILTER"
        filters_active=true
    fi
    
    # Check for positive specifications in suite names
    for suite in "${suites_to_run[@]}"; do
        if echo "$suite" | grep -q ":"; then
            echo "Positive test specification detected in: $suite"
            filters_active=true
        fi
    done
    
    if [ "$filters_active" = "true" ]; then
        daq_testing_reporter_warning "Filtering is active - some tests may be skipped"
    fi
    echo
    
    # Run each suite
    TOTAL_SUITES=${#suites_to_run[@]}
    local overall_success=true
    
    for suite in "${suites_to_run[@]}"; do
        if __daq_testing_runner_execute_suite "$suite" "$scripts_dir"; then
            if [ "$__DAQ_TESTING_RUNNER_VERBOSE" = "true" ]; then
                daq_testing_reporter_info "Suite '$suite' completed successfully"
            fi
        else
            daq_testing_reporter_error "Suite '$suite' failed"
            overall_success=false
            
            if [ "$__DAQ_TESTING_RUNNER_CONTINUE_ON_FAIL" != "true" ]; then
                daq_testing_reporter_warning "Stopping due to suite failure (use --continue-on-fail to continue)"
                break
            fi
        fi
        
        # Reset framework for next suite
        daq_testing_common_reset
        echo
    done
    
    # Print overall summary
    if daq_testing_reporter_grand_summary \
        "$TOTAL_SUITES" \
        "$PASSED_SUITES" \
        "$FAILED_SUITES" \
        "$GRAND_TOTAL_TESTS" \
        "$GRAND_PASSED_TESTS" \
        "$GRAND_FAILED_TESTS" \
        "$GRAND_SKIPPED_TESTS"; then
        exit 0
    else
        exit 1
    fi
}

################################################################################
# SCRIPT ENTRY POINT
################################################################################

# Only execute if script is run directly (not sourced)
if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
    # Parse global flags first
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                __daq_testing_runner_help
                exit 0
                ;;
            --version|-v)
                echo "test-runner v$DAQ_TESTING_RUNNER_VERSION (build: $DAQ_TESTING_RUNNER_BUILD_DATE)"
                exit 0
                ;;
            --verbose)
                __DAQ_TESTING_RUNNER_VERBOSE=true
                export OPENDAQ_VERBOSE=true
                shift
                ;;
            --debug|-d)
                __DAQ_TESTING_RUNNER_DEBUG=true
                export OPENDAQ_DEBUG=true
                shift
                ;;
            *)
                # Not a global flag, break to process commands
                break
                ;;
        esac
    done
    
    # Run main function
    daq_testing_runner_main "$@"
fi

################################################################################
# END OF SCRIPT
################################################################################
