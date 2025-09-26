#!/bin/bash

# test-runner.sh - Main test runner for openDAQ scripts
# Compatible with Bash 3.x and macOS

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
SUITES_DIR="$SCRIPT_DIR/suites"

# Global counters for all suites
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
GRAND_TOTAL_TESTS=0
GRAND_PASSED_TESTS=0
GRAND_FAILED_TESTS=0

# Load the test framework
if [ -f "$LIB_DIR/test-framework.sh" ]; then
    source "$LIB_DIR/test-framework.sh"
else
    echo "Error: Test framework not found at $LIB_DIR/test-framework.sh"
    exit 1
fi

# Show help
show_runner_help() {
    cat << 'EOF'
NAME
    test-runner.sh - Main test runner for openDAQ scripts

SYNOPSIS
    test-runner.sh [OPTIONS] [SUITE...]

DESCRIPTION
    Run test suites for openDAQ scripts. Can run specific suites or all available suites.

OPTIONS
    -h, --help              Show this help message
    -l, --list              List available test suites
    -v, --verbose           Verbose output
    --scripts-dir DIR       Directory containing scripts to test (default: parent dir)
    --continue-on-fail      Continue running suites even if one fails
    --filter PATTERN        Run only tests matching pattern (regex)
    --list-tests SUITE      List all tests in a specific suite

ARGUMENTS
    SUITE                   Specific test suite to run (without test- prefix)
                           If no suites specified, runs all available suites

EXAMPLES
    test-runner.sh
        Run all available test suites

    test-runner.sh opendaq-version-parse
        Run only the opendaq-version-parse test suite

    test-runner.sh opendaq-version-parse opendaq-version-compose
        Run multiple specific test suites

    test-runner.sh opendaq-version-parse --filter "extract.*major"
        Run only tests matching pattern in opendaq-version-parse suite

    test-runner.sh --filter "validation" 
        Run tests matching "validation" in all suites

    test-runner.sh --list-tests opendaq-version-parse
        List all test names in opendaq-version-parse suite

    test-runner.sh --list
        List all available test suites

DIRECTORY STRUCTURE
    tests/
    ├── test-runner.sh              # This script
    ├── lib/
    │   └── test-framework.sh       # Test framework library
    ├── suites/
    │   ├── test-opendaq-version-parse.sh
    │   └── test-opendaq-version-compose.sh
    └── scripts/                    # Or parent directory with actual scripts
        ├── opendaq-version-parse.sh
        └── opendaq-version-compose.sh

EXIT STATUS
    0       All test suites passed
    1       One or more test suites failed
    2       Configuration or setup error

EOF
}

# List available test suites
list_suites() {
    echo "Available test suites:"
    for suite_file in "$SUITES_DIR"/test-*.sh; do
        if [ -f "$suite_file" ]; then
            local suite_name=$(basename "$suite_file" .sh)
            suite_name=${suite_name#test-}
            echo "  $suite_name"
        fi
    done
}

# List tests in a specific suite
list_tests_in_suite() {
    local suite_name="$1"
    
    # Clean suite name
    suite_name=$(basename "$suite_name")
    if ! echo "$suite_name" | grep -q "^test-"; then
        suite_name="test-${suite_name}"
    fi
    
    local suite_file="$SUITES_DIR/${suite_name}.sh"
    
    if [ ! -f "$suite_file" ]; then
        echo "Error: Test suite not found: $suite_file"
        echo "Available suites:"
        list_suites
        return 1
    fi
    
    echo "Tests in suite '$suite_name':"
    grep -E '^\s*run_test.*"[^"]*"' "$suite_file" | \
        sed -E 's/.*run_test[^"]*"([^"]*)".*$/  \1/' | \
        sort
}

# Find script path for a given suite
find_script_path() {
    local suite_name="$1"
    local scripts_dir="$2"
    
    # Try different possible script names and locations
    local possible_paths=(
        "$scripts_dir/${suite_name}.sh"
        "$scripts_dir/$suite_name"
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

# Run a single test suite
run_suite() {
    local suite_name="$1"
    local scripts_dir="$2"
    local verbose="$3"
    local filter="$4"
    
    # Clean suite name - remove any path prefixes
    suite_name=$(basename "$suite_name")
    
    local suite_file="$SUITES_DIR/${suite_name}.sh"
    
    # If suite_name doesn't start with "test-", add it
    if ! echo "$suite_name" | grep -q "^test-"; then
        suite_file="$SUITES_DIR/test-${suite_name}.sh"
        suite_name="test-${suite_name}"
    fi
    
    if [ ! -f "$suite_file" ]; then
        echo "${RED}Error: Test suite not found: $suite_file${RESET}"
        echo "Available suites:"
        list_suites
        return 1
    fi
    
    # Extract component name from suite name (remove test- prefix)
    local component_name="${suite_name#test-}"
    
    # Find the script to test
    local script_path
    script_path=$(find_script_path "$component_name" "$scripts_dir")
    if [ $? -ne 0 ]; then
        echo "${RED}Error: Script not found for suite '$suite_name'${RESET}"
        echo "Searched for component: $component_name"
        echo "Searched in: $scripts_dir, parent directory, current directory"
        return 1
    fi
    
    echo "${BLUE}===========================================${RESET}"
    echo "${BLUE}         Running Suite: $suite_name       ${RESET}"
    echo "${BLUE}===========================================${RESET}"
    
    # Initialize test framework for this suite
    if ! test_framework_init "$script_path" "$suite_name" "$filter"; then
        return 1
    fi
    
    # Source and run the test suite
    if ! source "$suite_file"; then
        echo "${RED}Error: Failed to run test suite: $suite_file${RESET}"
        return 1
    fi
    
    # Get results from this suite
    local results
    results=$(test_framework_get_results)
    local suite_total=$(echo "$results" | cut -d' ' -f1)
    local suite_passed=$(echo "$results" | cut -d' ' -f2)
    local suite_failed=$(echo "$results" | cut -d' ' -f3)
    
    # Update grand totals
    GRAND_TOTAL_TESTS=$((GRAND_TOTAL_TESTS + suite_total))
    GRAND_PASSED_TESTS=$((GRAND_PASSED_TESTS + suite_passed))
    GRAND_FAILED_TESTS=$((GRAND_FAILED_TESTS + suite_failed))
    
    # Print suite summary
    if test_framework_summary; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
        echo "${GREEN}Suite '$suite_name' PASSED${RESET}"
        return 0
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        echo "${RED}Suite '$suite_name' FAILED${RESET}"
        return 1
    fi
}

# Print grand summary
print_grand_summary() {
    echo
    echo "${BLUE}===========================================${RESET}"
    echo "${BLUE}             OVERALL SUMMARY               ${RESET}"
    echo "${BLUE}===========================================${RESET}"
    echo "Total suites: $TOTAL_SUITES"
    echo "${GREEN}Passed suites: $PASSED_SUITES${RESET}"
    if [ $FAILED_SUITES -gt 0 ]; then
        echo "${RED}Failed suites: $FAILED_SUITES${RESET}"
    else
        echo "${RED}Failed suites: $FAILED_SUITES${RESET}"
    fi
    echo
    echo "Grand total tests: $GRAND_TOTAL_TESTS"
    echo "${GREEN}Grand total passed: $GRAND_PASSED_TESTS${RESET}"
    if [ $GRAND_FAILED_TESTS -gt 0 ]; then
        echo "${RED}Grand total failed: $GRAND_FAILED_TESTS${RESET}"
        echo
        echo "${RED}Some tests failed. Please review the output above.${RESET}"
    else
        echo "${RED}Grand total failed: $GRAND_FAILED_TESTS${RESET}"
        echo
        # Only show success if we actually ran some tests
        if [ $GRAND_TOTAL_TESTS -gt 0 ]; then
            echo "${GREEN}All tests passed! 🎉${RESET}"
        else
            echo "${YELLOW}No tests were executed.${RESET}"
        fi
    fi
}

# Main function
main() {
    local scripts_dir="$SCRIPT_DIR/.."
    local verbose=false
    local continue_on_fail=false
    local test_filter=""
    local list_tests_suite=""
    local suites_to_run=()
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_runner_help
                exit 0
                ;;
            -l|--list)
                list_suites
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --scripts-dir)
                if [ $# -lt 2 ]; then
                    echo "Error: --scripts-dir requires a directory argument"
                    exit 2
                fi
                scripts_dir="$2"
                shift 2
                ;;
            --continue-on-fail)
                continue_on_fail=true
                shift
                ;;
            --filter)
                if [ $# -lt 2 ]; then
                    echo "Error: --filter requires a pattern argument"
                    exit 2
                fi
                test_filter="$2"
                shift 2
                ;;
            --list-tests)
                if [ $# -lt 2 ]; then
                    echo "Error: --list-tests requires a suite name"
                    exit 2
                fi
                list_tests_suite="$2"
                shift 2
                ;;
            -*)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 2
                ;;
            *)
                suites_to_run+=("$1")
                shift
                ;;
        esac
    done
    
    # Handle --list-tests
    if [ -n "$list_tests_suite" ]; then
        list_tests_in_suite "$list_tests_suite"
        exit $?
    fi
    
    # If no suites specified, find all available suites
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        for suite_file in "$SUITES_DIR"/test-*.sh; do
            if [ -f "$suite_file" ]; then
                local suite_name=$(basename "$suite_file" .sh)
                suite_name=${suite_name#test-}
                suites_to_run+=("$suite_name")
            fi
        done
    fi
    
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        echo "No test suites found in $SUITES_DIR"
        echo "Use --list to see available suites"
        exit 2
    fi
    
    echo "${BLUE}===========================================${RESET}"
    echo "${BLUE}         openDAQ Test Runner              ${RESET}"
    echo "${BLUE}===========================================${RESET}"
    echo "Scripts directory: $scripts_dir"
    echo "Test suites to run: ${suites_to_run[*]}"
    if [ -n "$test_filter" ]; then
        echo "Test filter: $test_filter"
    fi
    echo
    
    # Run each suite
    TOTAL_SUITES=${#suites_to_run[@]}
    local overall_success=true
    
    for suite in "${suites_to_run[@]}"; do
        if run_suite "$suite" "$scripts_dir" "$verbose" "$test_filter"; then
            if [ "$verbose" = true ]; then
                echo "${GREEN}✓ Suite '$suite' completed successfully${RESET}"
            fi
        else
            echo "${RED}✗ Suite '$suite' failed${RESET}"
            overall_success=false
            
            if [ "$continue_on_fail" != true ]; then
                echo "${YELLOW}Stopping due to suite failure (use --continue-on-fail to continue)${RESET}"
                break
            fi
        fi
        
        # Reset framework for next suite
        test_framework_reset
        echo
    done
    
    # Print overall summary
    print_grand_summary
    
    if [ "$overall_success" = true ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
