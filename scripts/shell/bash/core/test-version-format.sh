#!/usr/bin/env bash
# test-version-format.sh - Unit tests for version-format.sh

set -u

TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

if [ -t 1 ]; then
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_RESET='\033[0m'
else
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_RESET=''
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_SCRIPT="${SCRIPT_DIR}/version-format.sh"

if [ ! -f "$VERSION_SCRIPT" ]; then
    echo "ERROR: version-format.sh not found at: $VERSION_SCRIPT"
    exit 1
fi

source "$VERSION_SCRIPT"

print_header() {
    echo ""
    echo -e "${COLOR_BLUE}=== $1 ===${COLOR_RESET}"
}

assert_success() {
    local description="$1"
    shift
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if "$@" >/dev/null 2>&1; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description"
        echo "  Command failed: $*"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_failure() {
    local description="$1"
    shift
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if "$@" >/dev/null 2>&1; then
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description"
        echo "  Command should have failed: $*"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

assert_output() {
    local description="$1"
    local expected="$2"
    shift 2
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local actual
    actual=$("$@" 2>/dev/null) || true
    if [ "$actual" = "$expected" ]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description"
        echo "  Expected: '$expected'"
        echo "  Got:      '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_compose() {
    print_header "COMPOSE Tests"
    
    assert_output "Compose basic version with prefix" \
        "v1.2.3" \
        daq_version_compose --major 1 --minor 2 --patch 3
    
    assert_output "Compose version without prefix" \
        "1.2.3" \
        daq_version_compose --major 1 --minor 2 --patch 3 --exclude-prefix
    
    assert_output "Compose RC version with prefix" \
        "v1.2.3-rc" \
        daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc
    
    assert_output "Compose version with hash" \
        "v1.2.3-a1b2c3d" \
        daq_version_compose --major 1 --minor 2 --patch 3 --hash a1b2c3d
    
    assert_output "Compose with format X.YY.Z" \
        "1.2.3" \
        daq_version_compose --major 1 --minor 2 --patch 3 --format "X.YY.Z"
    
    assert_output "Compose with format vX.YY.Z-rc" \
        "v1.2.3-rc" \
        daq_version_compose --major 1 --minor 2 --patch 3 --format "vX.YY.Z-rc"
    
    assert_output "Compose with format X.YY.Z-HASH" \
        "1.2.3-abc1234" \
        daq_version_compose --major 1 --minor 2 --patch 3 --hash abc1234 --format "X.YY.Z-HASH"
    
    assert_failure "Compose fails without major" \
        daq_version_compose --minor 2 --patch 3
    
    assert_failure "Compose fails without minor" \
        daq_version_compose --major 1 --patch 3
    
    assert_failure "Compose fails without patch" \
        daq_version_compose --major 1 --minor 2
    
    assert_failure "Compose fails with invalid hash (too short)" \
        daq_version_compose --major 1 --minor 2 --patch 3 --hash abc
    
    assert_failure "Compose fails with invalid hash (non-hex)" \
        daq_version_compose --major 1 --minor 2 --patch 3 --hash xyz1234
    
    assert_failure "Compose fails with invalid hash (uppercase)" \
        daq_version_compose --major 1 --minor 2 --patch 3 --hash ABC1234
    
    assert_failure "Compose fails when format requires hash but not provided" \
        daq_version_compose --major 1 --minor 2 --patch 3 --format "X.YY.Z-HASH"
    
    assert_failure "Compose fails with invalid suffix (not rc)" \
        daq_version_compose --major 1 --minor 2 --patch 3 --suffix beta
    
    assert_failure "Compose fails with both suffix and hash" \
        daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc --hash abc1234
}

test_parse() {
    print_header "PARSE Tests"
    
    assert_output "Parse major from v1.2.3" \
        "1" \
        daq_version_parse v1.2.3 --major
    
    assert_output "Parse minor from v1.2.3" \
        "2" \
        daq_version_parse v1.2.3 --minor
    
    assert_output "Parse patch from v1.2.3" \
        "3" \
        daq_version_parse v1.2.3 --patch
    
    assert_output "Parse prefix from v1.2.3" \
        "v" \
        daq_version_parse v1.2.3 --prefix
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    local prefix_result
    prefix_result=$(daq_version_parse 1.2.3 --prefix 2>/dev/null) || prefix_result=""
    if [ -z "$prefix_result" ]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} Parse prefix from 1.2.3 (no prefix)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} Parse prefix from 1.2.3 (no prefix)"
        echo "  Expected: ''"
        echo "  Got:      '$prefix_result'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    assert_output "Parse suffix from v1.2.3-rc" \
        "rc" \
        daq_version_parse v1.2.3-rc --suffix
    
    assert_output "Parse hash from v1.2.3-a1b2c3d" \
        "a1b2c3d" \
        daq_version_parse v1.2.3-a1b2c3d --hash
    
    assert_output "Parse all components from v1.2.3" \
        "1 2 3   v" \
        daq_version_parse v1.2.3
    
    assert_output "Parse all components from v1.2.3-rc" \
        "1 2 3 rc  v" \
        daq_version_parse v1.2.3-rc
    
    assert_output "Parse all components from 1.2.3-abc1234" \
        "1 2 3  abc1234 " \
        daq_version_parse 1.2.3-abc1234
    
    assert_failure "Parse fails on invalid version" \
        daq_version_parse invalid-version --major
    
    assert_failure "Parse fails on custom suffix (beta)" \
        daq_version_parse v1.2.3-beta --suffix
}

test_validate() {
    print_header "VALIDATE Tests"
    
    assert_success "Validate v1.2.3" \
        daq_version_validate v1.2.3
    
    assert_success "Validate 1.2.3" \
        daq_version_validate 1.2.3
    
    assert_success "Validate v1.2.3-rc" \
        daq_version_validate v1.2.3-rc
    
    assert_success "Validate v1.2.3-a1b2c3d" \
        daq_version_validate v1.2.3-a1b2c3d
    
    assert_failure "Validate fails on invalid version" \
        daq_version_validate invalid
    
    assert_failure "Validate fails on custom suffix (beta)" \
        daq_version_validate v1.2.3-beta
    
    assert_success "Validate v1.2.3 matches vX.YY.Z" \
        daq_version_validate v1.2.3 --format "vX.YY.Z"
    
    assert_success "Validate 1.2.3 matches X.YY.Z" \
        daq_version_validate 1.2.3 --format "X.YY.Z"
    
    assert_success "Validate v1.2.3-rc matches vX.YY.Z-rc" \
        daq_version_validate v1.2.3-rc --format "vX.YY.Z-rc"
    
    assert_failure "Validate v1.2.3 does not match X.YY.Z (has prefix)" \
        daq_version_validate v1.2.3 --format "X.YY.Z"
    
    assert_failure "Validate 1.2.3-rc does not match vX.YY.Z-rc (no prefix)" \
        daq_version_validate 1.2.3-rc --format "vX.YY.Z-rc"
    
    assert_success "Validate v1.2.3 is release" \
        daq_version_validate v1.2.3 --is-release
    
    assert_success "Validate 1.2.3 is release" \
        daq_version_validate 1.2.3 --is-release
    
    assert_failure "Validate v1.2.3-rc is not release" \
        daq_version_validate v1.2.3-rc --is-release
    
    assert_success "Validate v1.2.3-rc is RC" \
        daq_version_validate v1.2.3-rc --is-rc
    
    assert_success "Validate 1.2.3-rc is RC" \
        daq_version_validate 1.2.3-rc --is-rc
    
    assert_failure "Validate v1.2.3 is not RC" \
        daq_version_validate v1.2.3 --is-rc
    
    assert_success "Validate v1.2.3-abc1234 is dev" \
        daq_version_validate v1.2.3-abc1234 --is-dev
    
    assert_success "Validate 1.2.3-abc1234 is dev" \
        daq_version_validate 1.2.3-abc1234 --is-dev
    
    assert_failure "Validate v1.2.3-rc is not dev" \
        daq_version_validate v1.2.3-rc --is-dev
}

test_extract() {
    print_header "EXTRACT Tests"
    
    assert_output "Extract from filename with prefix" \
        "v1.2.3" \
        daq_version_extract "opendaq-v1.2.3-linux.tar.gz"
    
    assert_output "Extract from filename without prefix" \
        "1.2.3" \
        daq_version_extract "opendaq-1.2.3-linux.tar.gz"
    
    assert_output "Extract RC version" \
        "v1.2.3-rc" \
        daq_version_extract "opendaq-v1.2.3-rc-linux.tar.gz"
    
    assert_output "Extract version with hash" \
        "v1.2.3-abc1234" \
        daq_version_extract "opendaq-v1.2.3-abc1234-linux.tar.gz"
    
    assert_output "Extract from path" \
        "v2.5.10" \
        daq_version_extract "/releases/v2.5.10/opendaq.tar.gz"
    
    assert_output "Extract from release notes" \
        "v1.2.3" \
        daq_version_extract "Release v1.2.3 includes new features"
    
    assert_failure "Extract fails when no version found" \
        daq_version_extract "no-version-here.tar.gz"
}

test_hash_validation() {
    print_header "HASH VALIDATION Tests"
    
    assert_success "Valid 7-char hash" \
        daq_version_validate v1.2.3-abc1234
    
    assert_success "Valid 8-char hash" \
        daq_version_validate v1.2.3-abc12345
    
    assert_success "Valid 40-char hash (full git hash)" \
        daq_version_validate v1.2.3-abc1234567890abcdef1234567890abcdef1234
    
    assert_failure "Invalid hash - too short (6 chars, all hex)" \
        daq_version_validate v1.2.3-abc123
    
    assert_failure "Invalid hash - too long (41 chars, all lowercase hex)" \
        daq_version_validate v1.2.3-abc1234567890abcdef1234567890abcdef123456
    
    assert_failure "Invalid hash - contains uppercase (looks like hash)" \
        daq_version_validate v1.2.3-ABC1234
    
    assert_failure "Invalid suffix - not rc and not valid hash" \
        daq_version_validate v1.2.3-xyz1234
    
    assert_failure "Invalid suffix - contains dash (not rc)" \
        daq_version_validate v1.2.3-abc-123
}

test_edge_cases() {
    print_header "EDGE CASES Tests"
    
    assert_output "Large major version" \
        "v100.2.3" \
        daq_version_compose --major 100 --minor 2 --patch 3
    
    assert_output "Large minor version" \
        "v1.200.3" \
        daq_version_compose --major 1 --minor 200 --patch 3
    
    assert_output "Large patch version" \
        "v1.2.300" \
        daq_version_compose --major 1 --minor 2 --patch 300
    
    assert_output "Zero major version" \
        "v0.1.0" \
        daq_version_compose --major 0 --minor 1 --patch 0
    
    assert_success "Minimum valid hash (7 chars)" \
        daq_version_validate v1.2.3-abcdef0
    
    assert_success "Maximum valid hash (40 chars)" \
        daq_version_validate v1.2.3-0123456789abcdef0123456789abcdef01234567
    
    assert_failure "No custom suffixes allowed" \
        daq_version_validate v1.2.3-alpha
    
    assert_failure "No rc+hash combinations allowed" \
        daq_version_validate v1.2.3-rc-abc1234
}

test_simplified_logic() {
    print_header "SIMPLIFIED LOGIC Tests"
    
    assert_success "Only rc suffix is allowed" \
        daq_version_validate v1.2.3-rc
    
    assert_failure "Beta suffix not allowed" \
        daq_version_validate v1.2.3-beta
    
    assert_failure "Alpha suffix not allowed" \
        daq_version_validate v1.2.3-alpha
    
    assert_failure "Custom suffix not allowed" \
        daq_version_validate v1.2.3-custom
    
    assert_success "Hash without other suffix" \
        daq_version_validate v1.2.3-abc1234
    
    assert_failure "Cannot combine rc and hash" \
        daq_version_validate v1.2.3-rc-abc1234
    
    assert_output "Compose enforces mutual exclusivity" \
        "" \
        daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc --hash abc1234
}

echo -e "${COLOR_YELLOW}"
echo "=========================================="
echo "  Version Format Unit Tests"
echo "=========================================="
echo -e "${COLOR_RESET}"

test_compose
test_parse
test_validate
test_extract
test_hash_validation
test_edge_cases
test_simplified_logic

echo ""
echo -e "${COLOR_BLUE}=========================================="
echo "  Test Summary"
echo -e "==========================================${COLOR_RESET}"
echo ""
echo "Total tests:  $TESTS_TOTAL"
echo -e "${COLOR_GREEN}Passed:       $TESTS_PASSED${COLOR_RESET}"
echo -e "${COLOR_RED}Failed:       $TESTS_FAILED${COLOR_RESET}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${COLOR_GREEN}✓ All tests passed!${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}✗ Some tests failed${COLOR_RESET}"
    exit 1
fi
