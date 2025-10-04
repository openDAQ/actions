#!/usr/bin/env bash
#
# test-platform-format.sh - Test suite for platform-format.sh
#

set -u
if [ -n "${BASH_VERSION:-}" ]; then
    set -o pipefail
fi

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script under test
SCRIPT="./platform-format.sh"

# Check if script exists
if [ ! -f "$SCRIPT" ]; then
    echo -e "${RED}Error: $SCRIPT not found${NC}"
    exit 1
fi

# Make script executable
chmod +x "$SCRIPT"

# Test helper functions
test_start() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "  Test $TESTS_TOTAL: $1 ... "
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}FAIL${NC}"
    if [ $# -gt 0 ]; then
        echo -e "    ${RED}Reason: $1${NC}"
    fi
}

# Test exit code
test_exit_code() {
    local expected=$1
    local actual=$2
    local description=$3
    
    test_start "$description"
    if [ "$actual" -eq "$expected" ]; then
        test_pass
    else
        test_fail "Expected exit code $expected, got $actual"
    fi
}

# Test output contains string
test_output_contains() {
    local output="$1"
    local expected="$2"
    local description="$3"
    
    test_start "$description"
    if echo "$output" | grep -q "$expected"; then
        test_pass
    else
        test_fail "Expected output to contain '$expected', got: $output"
    fi
}

# Test output equals string
test_output_equals() {
    local output="$1"
    local expected="$2"
    local description="$3"
    
    test_start "$description"
    if [ "$output" = "$expected" ]; then
        test_pass
    else
        test_fail "Expected '$expected', got '$output'"
    fi
}

# Print section header
section() {
    echo ""
    echo -e "${BLUE}===${NC} $1 ${BLUE}===${NC}"
}

# Run tests
echo -e "${YELLOW}Running platform-format.sh test suite${NC}"
echo ""

# ============================================================================
section "Validate Command - Valid Platforms"
# ============================================================================

$SCRIPT validate ubuntu20.04-arm64 >/dev/null 2>&1
test_exit_code 0 $? "Valid Ubuntu platform"

$SCRIPT validate debian11-x86_64 >/dev/null 2>&1
test_exit_code 0 $? "Valid Debian platform"

$SCRIPT validate macos14-arm64 >/dev/null 2>&1
test_exit_code 0 $? "Valid macOS platform"

$SCRIPT validate win64 >/dev/null 2>&1
test_exit_code 0 $? "Valid Windows platform"

# ============================================================================
section "Validate Command - Invalid Platforms"
# ============================================================================

$SCRIPT validate ubuntu99.04-arm64 >/dev/null 2>&1
test_exit_code 1 $? "Invalid Ubuntu version"

$SCRIPT validate debian11-mips >/dev/null 2>&1
test_exit_code 1 $? "Invalid architecture"

$SCRIPT validate invalid-platform >/dev/null 2>&1
test_exit_code 1 $? "Completely invalid platform"

# ============================================================================
section "Validate Command - Type Checks (--is-*)"
# ============================================================================

$SCRIPT validate ubuntu20.04-arm64 --is-unix >/dev/null 2>&1
test_exit_code 0 $? "Ubuntu is unix"

$SCRIPT validate ubuntu20.04-arm64 --is-linux >/dev/null 2>&1
test_exit_code 0 $? "Ubuntu is linux"

$SCRIPT validate ubuntu20.04-arm64 --is-ubuntu >/dev/null 2>&1
test_exit_code 0 $? "Ubuntu is ubuntu"

$SCRIPT validate ubuntu20.04-arm64 --is-debian >/dev/null 2>&1
test_exit_code 1 $? "Ubuntu is not debian"

$SCRIPT validate debian11-x86_64 --is-linux >/dev/null 2>&1
test_exit_code 0 $? "Debian is linux"

$SCRIPT validate debian11-x86_64 --is-debian >/dev/null 2>&1
test_exit_code 0 $? "Debian is debian"

$SCRIPT validate macos14-arm64 --is-unix >/dev/null 2>&1
test_exit_code 0 $? "macOS is unix"

$SCRIPT validate macos14-arm64 --is-linux >/dev/null 2>&1
test_exit_code 1 $? "macOS is not linux"

$SCRIPT validate macos14-arm64 --is-macos >/dev/null 2>&1
test_exit_code 0 $? "macOS is macos"

$SCRIPT validate win64 --is-win >/dev/null 2>&1
test_exit_code 0 $? "Windows is win"

$SCRIPT validate win64 --is-unix >/dev/null 2>&1
test_exit_code 1 $? "Windows is not unix"

# ============================================================================
section "Parse Command - All Components"
# ============================================================================

output=$($SCRIPT parse ubuntu20.04-arm64 2>/dev/null)
test_output_equals "$output" "ubuntu 20.04 arm64" "Parse Ubuntu platform"

output=$($SCRIPT parse debian11-x86_64 2>/dev/null)
test_output_equals "$output" "debian 11 x86_64" "Parse Debian platform"

output=$($SCRIPT parse macos14-arm64 2>/dev/null)
test_output_equals "$output" "macos 14 arm64" "Parse macOS platform"

output=$($SCRIPT parse win64 2>/dev/null)
test_output_equals "$output" "win 64" "Parse Windows platform"

output=$($SCRIPT parse win32 2>/dev/null)
test_output_equals "$output" "win 32" "Parse Windows 32-bit"

# ============================================================================
section "Parse Command - Individual Components"
# ============================================================================

output=$($SCRIPT parse ubuntu20.04-arm64 --os-name 2>/dev/null)
test_output_equals "$output" "ubuntu" "Parse --os-name"

output=$($SCRIPT parse ubuntu20.04-arm64 --os-version 2>/dev/null)
test_output_equals "$output" "20.04" "Parse --os-version"

output=$($SCRIPT parse ubuntu20.04-arm64 --os-arch 2>/dev/null)
test_output_equals "$output" "arm64" "Parse --os-arch"

output=$($SCRIPT parse ubuntu20.04-arm64 --os-name --os-version 2>/dev/null)
test_output_equals "$output" "ubuntu 20.04" "Parse --os-name --os-version"

output=$($SCRIPT parse win64 --os-name --os-arch 2>/dev/null)
test_output_equals "$output" "win 64" "Parse Windows --os-name --os-arch"

output=$($SCRIPT parse macos14-arm64 --os-version --os-arch 2>/dev/null)
test_output_equals "$output" "14 arm64" "Parse --os-version --os-arch"

# ============================================================================
section "Extract Command (alias for parse)"
# ============================================================================

output=$($SCRIPT extract ubuntu22.04-x86_64 2>/dev/null)
test_output_equals "$output" "ubuntu 22.04 x86_64" "Extract all components"

output=$($SCRIPT extract debian12-arm64 --os-name 2>/dev/null)
test_output_equals "$output" "debian" "Extract --os-name"

# ============================================================================
section "Compose Command - Valid Compositions"
# ============================================================================

output=$($SCRIPT compose --os-name ubuntu --os-version 20.04 --os-arch arm64 2>/dev/null)
test_output_equals "$output" "ubuntu20.04-arm64" "Compose Ubuntu platform"

output=$($SCRIPT compose --os-name debian --os-version 11 --os-arch x86_64 2>/dev/null)
test_output_equals "$output" "debian11-x86_64" "Compose Debian platform"

output=$($SCRIPT compose --os-name macos --os-version 14 --os-arch arm64 2>/dev/null)
test_output_equals "$output" "macos14-arm64" "Compose macOS platform"

output=$($SCRIPT compose --os-name win --os-arch 64 2>/dev/null)
test_output_equals "$output" "win64" "Compose Windows platform"

output=$($SCRIPT compose --os-name win --os-arch 32 2>/dev/null)
test_output_equals "$output" "win32" "Compose Windows 32-bit"

# ============================================================================
section "Compose Command - Error Cases"
# ============================================================================

$SCRIPT compose --os-name ubuntu --os-arch arm64 >/dev/null 2>&1
test_exit_code 1 $? "Compose without version for Linux fails"

$SCRIPT compose --os-version 20.04 --os-arch arm64 >/dev/null 2>&1
test_exit_code 1 $? "Compose without os-name fails"

$SCRIPT compose --os-name ubuntu --os-version 20.04 >/dev/null 2>&1
test_exit_code 1 $? "Compose without os-arch fails"

$SCRIPT compose --os-name ubuntu --os-version 99.99 --os-arch arm64 >/dev/null 2>&1
test_exit_code 1 $? "Compose with invalid version fails"

$SCRIPT compose --os-name ubuntu --os-version 20.04 --os-arch >/dev/null 2>&1
test_exit_code 1 $? "Compose with missing arch value fails"

# ============================================================================
section "List Platforms Command"
# ============================================================================

output=$($SCRIPT --list-platforms 2>/dev/null)
test_output_contains "$output" "ubuntu20.04-arm64" "List contains Ubuntu 20.04 arm64"
test_output_contains "$output" "debian11-x86_64" "List contains Debian 11 x86_64"
test_output_contains "$output" "macos14-arm64" "List contains macOS 14 arm64"
test_output_contains "$output" "win64" "List contains win64"
test_output_contains "$output" "win32" "List contains win32"

# Count platforms
platform_count=$(echo "$output" | wc -l | tr -d ' ')
test_start "Platform count is correct (expected 32+)"
if [ "$platform_count" -ge 32 ]; then
    test_pass
else
    test_fail "Expected at least 32 platforms, got $platform_count"
fi

# ============================================================================
section "Global Flags - Verbose"
# ============================================================================

output=$($SCRIPT --verbose validate ubuntu20.04-arm64 2>&1)
test_output_contains "$output" "VERBOSE" "Verbose flag produces verbose output"

output=$($SCRIPT validate --verbose ubuntu20.04-arm64 --is-linux 2>&1)
test_output_contains "$output" "VERBOSE" "Verbose flag works in middle of command"

# ============================================================================
section "Global Flags - Debug"
# ============================================================================

output=$($SCRIPT --debug validate ubuntu20.04-arm64 2>&1)
test_output_contains "$output" "DEBUG" "Debug flag produces debug output"

output=$($SCRIPT --debug parse ubuntu20.04-arm64 2>&1)
test_output_contains "$output" "DEBUG" "Debug flag works with parse"

# ============================================================================
section "Global Flags - Quiet"
# ============================================================================

output=$($SCRIPT --quiet validate invalid-platform 2>&1)
test_output_equals "$output" "" "Quiet flag suppresses error messages"

# But should still have non-zero exit code
$SCRIPT --quiet validate invalid-platform >/dev/null 2>&1
test_exit_code 1 $? "Quiet mode still returns error exit code"

# ============================================================================
section "Edge Cases"
# ============================================================================

# Multiple platforms with different versions
output=$($SCRIPT parse ubuntu24.04-arm64 2>/dev/null)
test_output_equals "$output" "ubuntu 24.04 arm64" "Parse Ubuntu 24.04"

output=$($SCRIPT parse debian8-x86_64 2>/dev/null)
test_output_equals "$output" "debian 8 x86_64" "Parse Debian 8"

output=$($SCRIPT parse debian12-arm64 2>/dev/null)
test_output_equals "$output" "debian 12 arm64" "Parse Debian 12"

output=$($SCRIPT parse macos26-arm64 2>/dev/null)
test_output_equals "$output" "macos 26 arm64" "Parse macOS 26"

# Test all architectures
$SCRIPT validate ubuntu20.04-x86_64 >/dev/null 2>&1
test_exit_code 0 $? "x86_64 architecture is valid"

$SCRIPT validate ubuntu20.04-arm64 >/dev/null 2>&1
test_exit_code 0 $? "arm64 architecture is valid"

# ============================================================================
section "Sourcing Script (function availability)"
# ============================================================================

# Test that script can be sourced
if source "$SCRIPT" 2>/dev/null; then
    test_start "Script can be sourced"
    if type daq_platform_validate >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Function daq_platform_validate not available after sourcing"
    fi
    
    test_start "Public function daq_platform_parse exists"
    if type daq_platform_parse >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Function daq_platform_parse not found"
    fi
    
    test_start "Public function daq_platform_compose exists"
    if type daq_platform_compose >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Function daq_platform_compose not found"
    fi
else
    test_start "Script can be sourced"
    test_fail "Failed to source script"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${YELLOW}Test Summary${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "Total tests:  ${TESTS_TOTAL}"
echo -e "Passed:       ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Failed:       ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi
