#!/bin/bash
################################################################################
# Test Suite for version-format.sh
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test results
TEST_RESULTS=()

################################################################################
# Test Helper Functions
################################################################################

test_start() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}TEST: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TEST_RESULTS+=("PASS: $1")
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TEST_RESULTS+=("FAIL: $1")
}

test_command() {
    local description="$1"
    local command="$2"
    local expected_output="$3"
    local expected_exit_code="${4:-0}"
    
    echo -e "${YELLOW}Running:${NC} $command"
    
    # Execute command and capture output and exit code
    set +e
    actual_output=$(eval "$command" 2>&1)
    actual_exit_code=$?
    set -e
    
    # Check exit code
    if [ $actual_exit_code -ne $expected_exit_code ]; then
        test_fail "$description - Exit code mismatch (expected: $expected_exit_code, got: $actual_exit_code)"
        echo -e "${YELLOW}Output:${NC} $actual_output"
        return 1
    fi
    
    # Check output if expected output is provided
    if [ -n "$expected_output" ]; then
        if echo "$actual_output" | grep -q "$expected_output"; then
            test_pass "$description"
            echo -e "${YELLOW}Output:${NC} $actual_output"
        else
            test_fail "$description - Output mismatch"
            echo -e "${YELLOW}Expected:${NC} $expected_output"
            echo -e "${YELLOW}Got:${NC} $actual_output"
            return 1
        fi
    else
        test_pass "$description"
        echo -e "${YELLOW}Output:${NC} $actual_output"
    fi
    
    echo ""
}

################################################################################
# Setup
################################################################################

SCRIPT_PATH="./version-format.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}ERROR: version-format.sh not found at $SCRIPT_PATH${NC}"
    exit 1
fi

chmod +x "$SCRIPT_PATH"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         version-format.sh Test Suite                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# TEST SECTION: Basic Info
################################################################################

test_start "Basic Info - Version"
test_command "Show version" \
    "$SCRIPT_PATH --version" \
    "version-format v1.0.0"

test_start "Basic Info - Help (short)"
test_command "Show short help" \
    "$SCRIPT_PATH" \
    "USAGE:"

test_start "Basic Info - Help (full)"
test_command "Show full help" \
    "$SCRIPT_PATH --help" \
    "DESCRIPTION:"

################################################################################
# TEST SECTION: Query Commands
################################################################################

test_start "Query - List Formats"
test_command "List all formats" \
    "$SCRIPT_PATH --list-formats" \
    "vX.YY.Z"

test_start "Query - List Formats (verbose)"
test_command "List formats with details" \
    "$SCRIPT_PATH --list-formats --verbose" \
    "prefix="

test_start "Query - List Formats (prefix-only)"
test_command "List formats with prefix only" \
    "$SCRIPT_PATH --list-formats --prefix-only" \
    "vX.YY.Z"

test_start "Query - List Types"
test_command "List all types" \
    "$SCRIPT_PATH --list-types" \
    "release"

test_start "Query - List Types (verbose)"
test_command "List types with details" \
    "$SCRIPT_PATH --list-types --verbose" \
    "Release version"

test_start "Query - Default Format"
test_command "Get default format" \
    "$SCRIPT_PATH --default-format" \
    "vX.YY.Z"

test_start "Query - Default Prefix"
test_command "Get default prefix" \
    "$SCRIPT_PATH --default-prefix" \
    "v"

test_start "Query - Default Suffix"
test_command "Get default suffix" \
    "$SCRIPT_PATH --default-suffix" \
    "rc"

################################################################################
# TEST SECTION: Detection
################################################################################

test_start "Detection - Detect Type (release)"
test_command "Detect release type" \
    "$SCRIPT_PATH v3.14.2 --detect-type" \
    "release"

test_start "Detection - Detect Type (rc)"
test_command "Detect RC type" \
    "$SCRIPT_PATH v3.14.2-rc --detect-type" \
    "rc"

test_start "Detection - Detect Type (dev)"
test_command "Detect dev type" \
    "$SCRIPT_PATH v3.14.2-abc123f --detect-type" \
    "dev"

test_start "Detection - Detect Type (rc-dev)"
test_command "Detect RC-dev type" \
    "$SCRIPT_PATH v3.14.2-rc-abc123f --detect-type" \
    "rc-dev"

test_start "Detection - Detect Type (custom)"
test_command "Detect custom type" \
    "$SCRIPT_PATH v3.14.2-beta --detect-type" \
    "custom"

test_start "Detection - Detect Type (custom-dev)"
test_command "Detect custom-dev type" \
    "$SCRIPT_PATH v3.14.2-beta-abc123f --detect-type" \
    "custom-dev"

test_start "Detection - Detect Format (vX.YY.Z)"
test_command "Detect format vX.YY.Z" \
    "$SCRIPT_PATH v3.14.2 --detect-format" \
    "vX.YY.Z"

test_start "Detection - Detect Format (vX.YY.Z-rc)"
test_command "Detect format vX.YY.Z-rc" \
    "$SCRIPT_PATH v3.14.2-rc --detect-format" \
    "vX.YY.Z-rc"

test_start "Detection - Detect Format (vX.YY.Z-HASH)"
test_command "Detect format vX.YY.Z-HASH" \
    "$SCRIPT_PATH v3.14.2-abc123f --detect-format" \
    "vX.YY.Z-HASH"

test_start "Detection - Detect Format (X.YY.Z)"
test_command "Detect format X.YY.Z (no prefix)" \
    "$SCRIPT_PATH 3.14.2 --detect-format" \
    "X.YY.Z"

################################################################################
# TEST SECTION: Validation
################################################################################

test_start "Validation - Valid Release"
test_command "Validate release version" \
    "$SCRIPT_PATH validate v3.14.2" \
    "" \
    0

test_start "Validation - Valid RC"
test_command "Validate RC version" \
    "$SCRIPT_PATH validate v3.14.2-rc" \
    "" \
    0

test_start "Validation - Invalid Format"
test_command "Validate invalid format" \
    "$SCRIPT_PATH validate invalid-version" \
    "" \
    1

test_start "Validation - Check is-release"
test_command "Check if version is release" \
    "$SCRIPT_PATH validate v3.14.2 --is-release" \
    "" \
    0

test_start "Validation - Check is-rc (positive)"
test_command "Check if version is RC (positive)" \
    "$SCRIPT_PATH validate v3.14.2-rc --is-rc" \
    "" \
    0

test_start "Validation - Check is-rc (negative)"
test_command "Check if version is RC (negative)" \
    "$SCRIPT_PATH validate v3.14.2 --is-rc" \
    "" \
    1

test_start "Validation - Check has-prefix (positive)"
test_command "Check if version has prefix (positive)" \
    "$SCRIPT_PATH validate v3.14.2 --has-prefix" \
    "" \
    0

test_start "Validation - Check has-prefix (negative)"
test_command "Check if version has prefix (negative)" \
    "$SCRIPT_PATH validate 3.14.2 --has-prefix" \
    "" \
    1

test_start "Validation - Check has-suffix (positive)"
test_command "Check if version has suffix (positive)" \
    "$SCRIPT_PATH validate v3.14.2-rc --has-suffix" \
    "" \
    0

test_start "Validation - Check has-hash (positive)"
test_command "Check if version has hash (positive)" \
    "$SCRIPT_PATH validate v3.14.2-abc123f --has-hash" \
    "" \
    0

test_start "Validation - Format vX.YY.Z"
test_command "Validate against format vX.YY.Z" \
    "$SCRIPT_PATH validate v3.14.2 --format vX.YY.Z" \
    "" \
    0

test_start "Validation - Format mismatch"
test_command "Validate against wrong format" \
    "$SCRIPT_PATH validate v3.14.2 --format X.YY.Z" \
    "" \
    1

test_start "Validation - Type release"
test_command "Validate against type release" \
    "$SCRIPT_PATH validate v3.14.2 --type release" \
    "" \
    0

test_start "Validation - Type mismatch"
test_command "Validate against wrong type" \
    "$SCRIPT_PATH validate v3.14.2 --type rc" \
    "" \
    1

################################################################################
# TEST SECTION: Parse
################################################################################

test_start "Parse - All Components"
test_command "Parse all components" \
    "$SCRIPT_PATH parse v3.14.2-rc-abc123f" \
    "OPENDAQ_VERSION_PARSED_MAJOR=3"

test_start "Parse - Single Component (major)"
test_command "Parse single component (value only)" \
    "$SCRIPT_PATH parse v3.14.2 --major" \
    "^3$"

test_start "Parse - Single Component (type)"
test_command "Parse single component type" \
    "$SCRIPT_PATH parse v3.14.2-rc --type" \
    "^rc$"

test_start "Parse - Multiple Components"
test_command "Parse multiple components (KEY=VALUE)" \
    "$SCRIPT_PATH parse v3.14.2 --major --minor --type" \
    "OPENDAQ_VERSION_PARSED_MAJOR=3"

test_start "Parse - Version without prefix"
test_command "Parse version without prefix" \
    "$SCRIPT_PATH parse 3.14.2 --prefix" \
    "^$"

test_start "Parse - Version with hash"
test_command "Parse version with hash" \
    "$SCRIPT_PATH parse v3.14.2-abc123f --hash" \
    "abc123f"

################################################################################
# TEST SECTION: Compose
################################################################################

test_start "Compose - Simple Release"
test_command "Compose simple release version" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2" \
    "v3.14.2"

test_start "Compose - RC Version"
test_command "Compose RC version" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --suffix rc" \
    "v3.14.2-rc"

test_start "Compose - Dev Version with Hash"
test_command "Compose dev version with hash" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --hash abc123f" \
    "v3.14.2-abc123f"

test_start "Compose - Without Prefix"
test_command "Compose without prefix" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --no-prefix" \
    "3.14.2"

test_start "Compose - Custom Suffix"
test_command "Compose with custom suffix" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --suffix beta" \
    "v3.14.2-beta"

test_start "Compose - Explicit Format X.YY.Z"
test_command "Compose with explicit format X.YY.Z" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --format X.YY.Z" \
    "^3.14.2$"

test_start "Compose - Explicit Format vX.YY.Z-rc-HASH"
test_command "Compose with explicit format vX.YY.Z-rc-HASH" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --format vX.YY.Z-rc-HASH --hash abc123f" \
    "v3.14.2-rc-abc123f"

test_start "Compose - Type RC"
test_command "Compose with type RC" \
    "$SCRIPT_PATH compose --major 3 --minor 14 --patch 2 --type rc" \
    "v3.14.2-rc"

test_start "Compose - From Environment"
test_command "Compose from environment variables" \
    "export OPENDAQ_VERSION_COMPOSED_MAJOR=3 OPENDAQ_VERSION_COMPOSED_MINOR=14 OPENDAQ_VERSION_COMPOSED_PATCH=2 OPENDAQ_VERSION_COMPOSED_SUFFIX=rc && $SCRIPT_PATH compose --from-env" \
    "v3.14.2-rc"

################################################################################
# TEST SECTION: Extract
################################################################################

test_start "Extract - From Text"
test_command "Extract version from text" \
    "$SCRIPT_PATH extract 'Release v3.14.2 is available'" \
    "v3.14.2"

test_start "Extract - Complex Text"
test_command "Extract from complex text" \
    "$SCRIPT_PATH extract 'opendaq-v3.14.2-rc-abc123f.tar.gz'" \
    "v3.14.2-rc-abc123f"

test_start "Extract - From Stdin"
test_command "Extract from stdin" \
    "echo 'Version: v3.14.2' | $SCRIPT_PATH extract -" \
    "v3.14.2"

test_start "Extract - No Version Found"
test_command "Extract when no version found" \
    "$SCRIPT_PATH extract 'No version here'" \
    "" \
    1

################################################################################
# TEST SECTION: Edge Cases
################################################################################

test_start "Edge Case - Large Version Numbers"
test_command "Handle large version numbers" \
    "$SCRIPT_PATH parse v123.456.789 --major --minor --patch" \
    "OPENDAQ_VERSION_PARSED_MAJOR=123"

test_start "Edge Case - Long Hash"
test_command "Handle long hash" \
    "$SCRIPT_PATH parse v3.14.2-1a2b3c4d5e6f7890 --hash" \
    "1a2b3c4d5e6f7890"

test_start "Edge Case - Custom Suffix with Hyphens"
test_command "Handle custom suffix with hyphens" \
    "$SCRIPT_PATH parse v3.14.2-beta-1 --suffix" \
    "beta-1"

test_start "Edge Case - Zero Version"
test_command "Handle zero version" \
    "$SCRIPT_PATH parse v0.0.0 --major --minor --patch" \
    "OPENDAQ_VERSION_PARSED_MAJOR=0"

################################################################################
# TEST SECTION: Error Cases
################################################################################

test_start "Error - Invalid Version Format"
test_command "Reject invalid version format" \
    "$SCRIPT_PATH validate v1.2" \
    "" \
    1

test_start "Error - Compose Without Required Args"
test_command "Reject compose without required args" \
    "$SCRIPT_PATH compose --major 3" \
    "" \
    1

test_start "Error - Parse Invalid Version"
test_command "Reject parsing invalid version" \
    "$SCRIPT_PATH parse not-a-version" \
    "" \
    1

################################################################################
# Test Summary
################################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     TEST SUMMARY                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Total Tests:  ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    echo ""
    echo "Failed tests:"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == FAIL:* ]]; then
            echo -e "  ${RED}✗${NC} ${result#FAIL: }"
        fi
    done
    exit 1
fi
