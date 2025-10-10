#!/bin/bash
# test-packaging-format.sh - Test suite for packaging-format.sh
#
# This script tests all functionality of packaging-format.sh including:
# - CPack generator detection
# - OS name detection (GitHub runner names and ${{ runner.os }} values)
# - Environment variable overrides
# - CLI and library usage modes
# - Error handling
#
# Compatible with bash 3.2+ and zsh

set -u

# =============================================================================
# Test Configuration
# =============================================================================

__TEST_PACKAGING_SCRIPT_PATH="./packaging-format.sh"
__TEST_PACKAGING_PASSED=0
__TEST_PACKAGING_FAILED=0
__TEST_PACKAGING_VERBOSE=0

# Colors for output (disabled if NO_COLOR is set or not a TTY)
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    __TEST_COLOR_GREEN="\033[0;32m"
    __TEST_COLOR_RED="\033[0;31m"
    __TEST_COLOR_YELLOW="\033[0;33m"
    __TEST_COLOR_BLUE="\033[0;34m"
    __TEST_COLOR_RESET="\033[0m"
else
    __TEST_COLOR_GREEN=""
    __TEST_COLOR_RED=""
    __TEST_COLOR_YELLOW=""
    __TEST_COLOR_BLUE=""
    __TEST_COLOR_RESET=""
fi

# =============================================================================
# Test Utilities
# =============================================================================

# Print test section header
__test_section() {
    echo ""
    echo -e "${__TEST_COLOR_BLUE}========================================${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}$1${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}========================================${__TEST_COLOR_RESET}"
}

# Print test case name
__test_case() {
    if [[ "${__TEST_PACKAGING_VERBOSE}" -eq 1 ]]; then
        echo -e "${__TEST_COLOR_YELLOW}Testing: $1${__TEST_COLOR_RESET}"
    fi
}

# Assert that command output equals expected value
# Arguments:
#   $1 - Test description
#   $2 - Expected value
#   $3 - Actual value
__test_assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    
    if [[ "${actual}" == "${expected}" ]]; then
        __TEST_PACKAGING_PASSED=$((__TEST_PACKAGING_PASSED + 1))
        echo -e "${__TEST_COLOR_GREEN}✓${__TEST_COLOR_RESET} ${description}"
        return 0
    else
        __TEST_PACKAGING_FAILED=$((__TEST_PACKAGING_FAILED + 1))
        echo -e "${__TEST_COLOR_RED}✗${__TEST_COLOR_RESET} ${description}"
        echo -e "  Expected: ${__TEST_COLOR_GREEN}${expected}${__TEST_COLOR_RESET}"
        echo -e "  Got:      ${__TEST_COLOR_RED}${actual}${__TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that command fails (returns non-zero exit code)
# Arguments:
#   $1 - Test description
#   $2 - Command to run
__test_assert_fails() {
    local description="$1"
    shift
    local output
    
    if output=$("$@" 2>&1); then
        __TEST_PACKAGING_FAILED=$((__TEST_PACKAGING_FAILED + 1))
        echo -e "${__TEST_COLOR_RED}✗${__TEST_COLOR_RESET} ${description}"
        echo -e "  Expected: command to fail"
        echo -e "  Got:      command succeeded with output: ${output}"
        return 1
    else
        __TEST_PACKAGING_PASSED=$((__TEST_PACKAGING_PASSED + 1))
        echo -e "${__TEST_COLOR_GREEN}✓${__TEST_COLOR_RESET} ${description}"
        return 0
    fi
}

# =============================================================================
# Test Cases
# =============================================================================

# Test CPack generator detection
test_cpack_generators() {
    __test_section "CPack Generator Detection"
    
    local result
    
    __test_case "NSIS generator"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator NSIS)
    __test_assert_equals "NSIS → exe" "exe" "${result}"
    
    __test_case "NSIS generator (lowercase)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator nsis)
    __test_assert_equals "nsis → exe" "exe" "${result}"
    
    __test_case "ZIP generator"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator ZIP)
    __test_assert_equals "ZIP → zip" "zip" "${result}"
    
    __test_case "TGZ generator"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator TGZ)
    __test_assert_equals "TGZ → tar.gz" "tar.gz" "${result}"
    
    __test_case "DEB generator"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator DEB)
    __test_assert_equals "DEB → deb" "deb" "${result}"
    
    __test_case "Unsupported generator"
    __test_assert_fails "RPM should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator RPM
}

# Test OS name detection with GitHub runner names
test_os_runner_names() {
    __test_section "OS Detection - GitHub Runner Names"
    
    local result
    
    __test_case "windows-latest"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name windows-latest)
    __test_assert_equals "windows-latest → exe" "exe" "${result}"
    
    __test_case "windows-2022"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name windows-2022)
    __test_assert_equals "windows-2022 → exe" "exe" "${result}"
    
    __test_case "ubuntu-latest"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name ubuntu-latest)
    __test_assert_equals "ubuntu-latest → deb" "deb" "${result}"
    
    __test_case "ubuntu-22.04"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name ubuntu-22.04)
    __test_assert_equals "ubuntu-22.04 → deb" "deb" "${result}"
    
    __test_case "macos-latest"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name macos-latest)
    __test_assert_equals "macos-latest → tar.gz" "tar.gz" "${result}"
    
    __test_case "macos-13"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name macos-13)
    __test_assert_equals "macos-13 → tar.gz" "tar.gz" "${result}"
}

# Test OS name detection with runner.os values
test_os_runner_variables() {
    __test_section "OS Detection - \${{ runner.os }} Values"
    
    local result
    
    __test_case "Windows (from runner.os)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name Windows)
    __test_assert_equals "Windows → exe" "exe" "${result}"
    
    __test_case "Linux (from runner.os)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name Linux)
    __test_assert_equals "Linux → deb" "deb" "${result}"
    
    __test_case "macOS (from runner.os)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name macOS)
    __test_assert_equals "macOS → tar.gz" "tar.gz" "${result}"
}

# Test OS name detection with generic names
test_os_generic_names() {
    __test_section "OS Detection - Generic Names"
    
    local result
    
    __test_case "windows (lowercase)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name windows)
    __test_assert_equals "windows → exe" "exe" "${result}"
    
    __test_case "linux (lowercase)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name linux)
    __test_assert_equals "linux → deb" "deb" "${result}"
    
    __test_case "macos (lowercase)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name macos)
    __test_assert_equals "macos → tar.gz" "tar.gz" "${result}"
    
    __test_case "win (short form)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name win)
    __test_assert_equals "win → exe" "exe" "${result}"
    
    __test_case "osx (alternative)"
    result=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name osx)
    __test_assert_equals "osx → tar.gz" "tar.gz" "${result}"
    
    __test_case "Unknown OS"
    __test_assert_fails "freebsd should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name freebsd
}

# Test environment variable overrides
test_env_overrides() {
    __test_section "Environment Variable Overrides"
    
    local result
    
    __test_case "Override Windows packaging"
    result=$(OPENDAQ_PACKAGING_WIN=zip "${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name Windows)
    __test_assert_equals "Windows with OPENDAQ_PACKAGING_WIN=zip → zip" "zip" "${result}"
    
    __test_case "Override Linux packaging"
    result=$(OPENDAQ_PACKAGING_LINUX=rpm "${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name Linux)
    __test_assert_equals "Linux with OPENDAQ_PACKAGING_LINUX=rpm → rpm" "rpm" "${result}"
    
    __test_case "Override macOS packaging"
    result=$(OPENDAQ_PACKAGING_MACOS=dmg "${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name macOS)
    __test_assert_equals "macOS with OPENDAQ_PACKAGING_MACOS=dmg → dmg" "dmg" "${result}"
}

# Test library usage (sourcing)
test_library_usage() {
    __test_section "Library Usage (Source Mode)"
    
    local result
    
    # Source the script
    # shellcheck source=/dev/null
    source "${__TEST_PACKAGING_SCRIPT_PATH}"
    
    __test_case "daq_packaging_detect_from_cpack function"
    result=$(daq_packaging_detect_from_cpack "NSIS")
    __test_assert_equals "Function call: NSIS → exe" "exe" "${result}"
    
    __test_case "daq_packaging_detect_from_os function"
    result=$(daq_packaging_detect_from_os "ubuntu-latest")
    __test_assert_equals "Function call: ubuntu-latest → deb" "deb" "${result}"
    
    __test_case "daq_packaging_detect_from_os with runner.os value"
    result=$(daq_packaging_detect_from_os "Linux")
    __test_assert_equals "Function call: Linux → deb" "deb" "${result}"
    
    __test_case "Environment variable override in library mode"
    result=$(OPENDAQ_PACKAGING_WIN=msi daq_packaging_detect_from_os "Windows")
    __test_assert_equals "Windows with override → msi" "msi" "${result}"
}

# Test error handling
test_error_handling() {
    __test_section "Error Handling"
    
    __test_case "Missing command"
    __test_assert_fails "No command should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}"
    
    __test_case "Invalid command"
    __test_assert_fails "Invalid command should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" invalid
    
    __test_case "Missing --cpack-generator value"
    __test_assert_fails "Missing generator value should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator
    
    __test_case "Missing --os-name value"
    __test_assert_fails "Missing OS name value should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" detect --os-name
    
    __test_case "No arguments to detect"
    __test_assert_fails "detect without arguments should fail" \
        "${__TEST_PACKAGING_SCRIPT_PATH}" detect
}

# Test verbose mode
test_verbose_mode() {
    __test_section "Verbose Mode"
    
    local output
    
    __test_case "Verbose output for CPack"
    output=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator NSIS --verbose 2>&1)
    if echo "${output}" | grep -q "\[INFO\]"; then
        __test_assert_equals "Verbose mode shows INFO logs" "0" "0"
    else
        __test_assert_equals "Verbose mode shows INFO logs" "has INFO" "no INFO"
    fi
    
    __test_case "Non-verbose output"
    output=$("${__TEST_PACKAGING_SCRIPT_PATH}" detect --cpack-generator NSIS 2>&1)
    if echo "${output}" | grep -q "\[INFO\]"; then
        __test_assert_equals "Non-verbose mode hides INFO logs" "no INFO" "has INFO"
    else
        __test_assert_equals "Non-verbose mode hides INFO logs" "0" "0"
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

run_all_tests() {
    echo -e "${__TEST_COLOR_BLUE}=====================================${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}Packaging Format Script Test Suite${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}=====================================${__TEST_COLOR_RESET}"
    
    # Check if script exists
    if [[ ! -f "${__TEST_PACKAGING_SCRIPT_PATH}" ]]; then
        echo -e "${__TEST_COLOR_RED}Error: ${__TEST_PACKAGING_SCRIPT_PATH} not found${__TEST_COLOR_RESET}"
        exit 1
    fi
    
    # Make sure script is executable
    if [[ ! -x "${__TEST_PACKAGING_SCRIPT_PATH}" ]]; then
        echo -e "${__TEST_COLOR_YELLOW}Warning: Making ${__TEST_PACKAGING_SCRIPT_PATH} executable${__TEST_COLOR_RESET}"
        chmod +x "${__TEST_PACKAGING_SCRIPT_PATH}"
    fi
    
    # Run all test suites
    test_cpack_generators
    test_os_runner_names
    test_os_runner_variables
    test_os_generic_names
    test_env_overrides
    test_library_usage
    test_error_handling
    test_verbose_mode
    
    # Print summary
    echo ""
    echo -e "${__TEST_COLOR_BLUE}=====================================${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}Test Summary${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_BLUE}=====================================${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_GREEN}Passed: ${__TEST_PACKAGING_PASSED}${__TEST_COLOR_RESET}"
    echo -e "${__TEST_COLOR_RED}Failed: ${__TEST_PACKAGING_FAILED}${__TEST_COLOR_RESET}"
    echo -e "Total:  $((__TEST_PACKAGING_PASSED + __TEST_PACKAGING_FAILED))"
    echo ""
    
    # Exit with appropriate code
    if [[ "${__TEST_PACKAGING_FAILED}" -eq 0 ]]; then
        echo -e "${__TEST_COLOR_GREEN}All tests passed!${__TEST_COLOR_RESET}"
        exit 0
    else
        echo -e "${__TEST_COLOR_RED}Some tests failed!${__TEST_COLOR_RESET}"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            __TEST_PACKAGING_VERBOSE=1
            shift
            ;;
        --script)
            __TEST_PACKAGING_SCRIPT_PATH="$2"
            shift 2
            ;;
        --help|-h)
            cat << EOF
Usage: $0 [OPTIONS]

Test suite for packaging-format.sh

Options:
    --verbose, -v          Enable verbose test output
    --script <path>        Path to packaging-format.sh (default: ./packaging-format.sh)
    --help, -h            Show this help message

Examples:
    $0
    $0 --verbose
    $0 --script /path/to/packaging-format.sh
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Run tests
run_all_tests
