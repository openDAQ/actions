#!/bin/bash

# test-runner.sh - Enhanced test runner for openDAQ scripts with hierarchical filtering
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

# Global filtering options
GLOBAL_EXCLUDED_SUITES=""
GLOBAL_EXCLUDED_TESTS=""
GLOBAL_REGEX_FILTER=""

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
    test-runner.sh - Enhanced test runner for openDAQ scripts with hierarchical filtering

SYNOPSIS
    test-runner.sh [OPTIONS] [SUITE[:TESTS]...]

DESCRIPTION
    Run test suites for openDAQ scripts with advanced filtering capabilities.
    Supports hierarchical filtering: positive specification → exclusions → regex filter.

FILTERING HIERARCHY (by priority):
    1. Positive specification: suite:test1,test2 (highest priority)
    2. Exclusions: --exclude-suite, --exclude-test  
    3. Regex filter: --filter "pattern" (lowest priority)

OPTIONS
    -h, --help              Show this help message
    -l, --list              List available test suites
    -v, --verbose           Verbose output
    --scripts-dir DIR       Directory containing scripts to test (default: parent dir)
    --continue-on-fail      Continue running suites even if one fails
    --filter PATTERN        Run only tests matching regex pattern
    --exclude-suite SUITE   Exclude specific test suite(s) - comma separated
    --exclude-test TEST     Exclude specific test(s) from all suites - comma separated
    --list-tests [SUITE]    List all tests in suite(s) or all suites if none specified

ARGUMENTS
    SUITE[:TESTS]           Test suite with optional specific tests
                           SUITE - run all tests in suite
                           SUITE:test1,test2 - run only specified tests in suite
                           If no suites specified, runs all available suites

EXAMPLES
    # Basic usage
    test-runner.sh
        Run all available test suites

    test-runner.sh opendaq-version-parse
        Run all tests in opendaq-version-parse suite

    # Positive specification (highest priority)
    test-runner.sh opendaq-version-parse:major,validation
        Run only "major" and "validation" tests in opendaq-version-parse suite

    test-runner.sh version-parse:basic,format version-compose:simple
        Run specific tests from multiple suites

    # Exclusions (second priority)  
    test-runner.sh --exclude-suite opendaq-version-compose
        Run all suites except opendaq-version-compose

    test-runner.sh --exclude-test "flaky-test,slow-test"
        Run all tests except those named "flaky-test" or "slow-test"

    test-runner.sh opendaq-version-parse --exclude-test "edge-case"
        Run opendaq-version-parse suite excluding "edge-case" test

    # Regex filtering (lowest priority)
    test-runner.sh --filter "extract.*format"
        Run tests matching regex pattern in all suites

    test-runner.sh opendaq-version-parse --filter "validation|verbose"
        Run tests matching "validation" OR "verbose" in opendaq-version-parse

    # Combined filtering (follows hierarchy)
    test-runner.sh version-parse:validation,format version-compose \
      --exclude-test "slow-test" \
      --filter "verbose"
        1. Include only "validation,format" from version-parse + all from version-compose
        2. Exclude any tests named "slow-test"  
        3. From remaining, only run tests matching "verbose"

    # Investigation and debugging
    test-runner.sh --list-tests
        List all test names in all suites

    test-runner.sh --list-tests opendaq-version-parse
        List all test names in specific suite

    test-runner.sh --list
        List all available test suites

FILTERING LOGIC:
    1. If SUITE:TESTS specified → only those tests from that suite are candidates
    2. Apply --exclude-test → remove excluded tests from candidates  
    3. Apply --filter regex → keep only tests matching pattern
    4. Show warning if final list is empty

DIRECTORY STRUCTURE
    tests/
    ├── test-runner.sh              # This script
    ├── lib/
    │   └── test-framework.sh       # Enhanced test framework library
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

# Extract test names from a suite file
extract_test_names_from_suite() {
    local suite_file="$1"
    
    if [ ! -f "$suite_file" ]; then
        return 1
    fi
    
    # Extract test names from run_test* function calls
    grep -E '^\s*run_test[^"]*"[^"]*"' "$suite_file" | \
        sed -E 's/.*run_test[^"]*"([^"]*)".*$/\1/' | \
        sort | uniq
}

# List tests in specific suite(s) or all suites
list_tests_in_suites() {
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
                extract_test_names_from_suite "$suite_file" | sed 's/^/  /'
            fi
        done
        return 0
    fi
    
    # List tests for specified suites
    for suite_spec in "${target_suites[@]}"; do
        # Clean suite name - remove test- prefix if present
        local suite_name=$(basename "$suite_spec")
        if ! echo "$suite_name" | grep -q "^test-"; then
            suite_name="test-${suite_name}"
        fi
        
        local suite_file="$SUITES_DIR/${suite_name}.sh"
        
        if [ ! -f "$suite_file" ]; then
            echo "Error: Test suite not found: $suite_file"
            continue
        fi
        
        echo "Tests in suite '${suite_name#test-}':"
        extract_test_names_from_suite "$suite_file" | sed 's/^/  /'
        echo
    done
}

# Parse suite specification (suite:test1,test2)
parse_suite_spec() {
    local suite_spec="$1"
    local suite_name=""
    local test_list=""
    
    if echo "$suite_spec" | grep -q ":"; then
        suite_name=$(echo "$suite_spec" | cut -d: -f1)
        test_list=$(echo "$suite_spec" | cut -d: -f2-)
    else
        suite_name="$suite_spec"
        test_list=""
    fi
    
    echo "$suite_name|$test_list"
}

# Check if suite should be excluded
is_suite_excluded() {
    local suite_name="$1"
    
    if [ -z "$GLOBAL_EXCLUDED_SUITES" ]; then
        return 1  # Not excluded
    fi
    
    local old_ifs="$IFS"
    IFS=','
    for excluded_suite in $GLOBAL_EXCLUDED_SUITES; do
        excluded_suite=$(echo "$excluded_suite" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        if [ "$excluded_suite" = "$suite_name" ]; then
            IFS="$old_ifs"
            return 0  # Excluded
        fi
    done
    IFS="$old_ifs"
    
    return 1  # Not excluded
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

# Run a single test suite with filtering
run_suite() {
    local suite_spec="$1"
    local scripts_dir="$2"
    local verbose="$3"
    
    # Parse suite specification
    local parsed
    parsed=$(parse_suite_spec "$suite_spec")
    local suite_name=$(echo "$parsed" | cut -d'|' -f1)
    local positive_tests=$(echo "$parsed" | cut -d'|' -f2)
    
    # Clean suite name - remove any path prefixes
    suite_name=$(basename "$suite_name")
    
    # Check if suite is excluded
    if is_suite_excluded "$suite_name"; then
        echo "${YELLOW}Skipping excluded suite: $suite_name${RESET}"
        return 0
    fi
    
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
    
    # Initialize test framework for this suite with hierarchical filtering
    if ! test_framework_init "$script_path" "$suite_name" "$positive_tests" "$GLOBAL_EXCLUDED_TESTS" "$GLOBAL_REGEX_FILTER"; then
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
            
            # Provide helpful hints about why no tests ran
            if [ -n "$GLOBAL_EXCLUDED_SUITES" ] || [ -n "$GLOBAL_EXCLUDED_TESTS" ] || [ -n "$GLOBAL_REGEX_FILTER" ]; then
                echo "${YELLOW}This might be due to filtering:${RESET}"
                if [ -n "$GLOBAL_EXCLUDED_SUITES" ]; then
                    echo "${YELLOW}  - Excluded suites: $GLOBAL_EXCLUDED_SUITES${RESET}"
                fi
                if [ -n "$GLOBAL_EXCLUDED_TESTS" ]; then
                    echo "${YELLOW}  - Excluded tests: $GLOBAL_EXCLUDED_TESTS${RESET}"
                fi
                if [ -n "$GLOBAL_REGEX_FILTER" ]; then
                    echo "${YELLOW}  - Regex filter: $GLOBAL_REGEX_FILTER${RESET}"
                fi
                echo "${YELLOW}Try running with --list-tests to see available tests${RESET}"
            fi
        fi
    fi
}

# Main function
main() {
    local scripts_dir="$SCRIPT_DIR/.."
    local verbose=false
    local continue_on_fail=false
    local list_tests_suites=()
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
                GLOBAL_REGEX_FILTER="$2"
                shift 2
                ;;
            --exclude-suite)
                if [ $# -lt 2 ]; then
                    echo "Error: --exclude-suite requires suite name(s)"
                    exit 2
                fi
                GLOBAL_EXCLUDED_SUITES="$2"
                shift 2
                ;;
            --exclude-test)
                if [ $# -lt 2 ]; then
                    echo "Error: --exclude-test requires test name(s)"
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
    if [ ${#list_tests_suites[@]} -gt 0 ] || [[ " $* " == *" --list-tests "* ]]; then
        list_tests_in_suites "${list_tests_suites[@]}"
        exit $?
    fi
    
    # If no suites specified, find all available suites
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        for suite_file in "$SUITES_DIR"/test-*.sh; do
            if [ -f "$suite_file" ]; then
                local suite_name=$(basename "$suite_file" .sh)
                suite_name=${suite_name#test-}
                
                # Check if suite is excluded
                if ! is_suite_excluded "$suite_name"; then
                    suites_to_run+=("$suite_name")
                fi
            fi
        done
    fi
    
    if [ ${#suites_to_run[@]} -eq 0 ]; then
        echo "No test suites found in $SUITES_DIR"
        if [ -n "$GLOBAL_EXCLUDED_SUITES" ]; then
            echo "Note: Some suites may have been excluded: $GLOBAL_EXCLUDED_SUITES"
        fi
        echo "Use --list to see available suites"
        exit 2
    fi
    
    echo "${BLUE}===========================================${RESET}"
    echo "${BLUE}         openDAQ Test Runner              ${RESET}"
    echo "${BLUE}===========================================${RESET}"
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
    
    if [ "$filters_active" = true ]; then
        echo "${YELLOW}Filtering is active - some tests may be skipped${RESET}"
    fi
    echo
    
    # Run each suite
    TOTAL_SUITES=${#suites_to_run[@]}
    local overall_success=true
    
    for suite in "${suites_to_run[@]}"; do
        if run_suite "$suite" "$scripts_dir" "$verbose"; then
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
