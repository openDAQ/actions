# Quick Start Guide

## Installation

```bash
# Set scripts directory environment variable
export DAQ_TESTS_SCRIPTS_DIR="/path/to/your/scripts"

# Or pass it as argument when running tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir /path/to/your/scripts
```

## Run Tests

```bash
cd /your/project/path/tests/shell/bash

# Set scripts directory (relative to test-runner.sh)
export DAQ_TESTS_SCRIPTS_DIR="../../../scripts"

# Run all tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}"

# Run with verbose output
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --verbose

# Run specific suite
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --include-test "test-basic*"

# Exclude slow tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --exclude-test "*:test-*-slow"

# Dry run to see what would execute
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --dry-run --verbose
```

## Create New Test Suite

```bash
# Create new suite file
cat > suites/test-myfeature.sh << 'EOF'
#!/usr/bin/env bash
# Test suite for my feature

test-myfeature-basic() {
    # Access scripts via DAQ_TESTS_SCRIPTS_DIR
    source "${DAQ_TESTS_SCRIPTS_DIR}/shell/bash/my-script.sh"
    
    # Your test logic here
    if [[ "result" == "expected" ]]; then
        return 0  # Success
    else
        echo "Test failed: unexpected result"
        return 1  # Failure
    fi
}

test-myfeature-with-script() {
    # Execute script as command
    local SCRIPT="${DAQ_TESTS_SCRIPTS_DIR}/shell/bash/my-script.sh"
    local output=$($SCRIPT --arg value)
    
    # Use assertions
    assert_equals "expected" "${output}"
}
EOF

# Make it executable
chmod +x suites/test-myfeature.sh

# Run your new tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --include-test "test-myfeature*"
```

## Using Test Hooks

Add setup and teardown hooks to prepare/cleanup your tests:

```bash
# Add to your test suite file
test_setup() {
    # Runs before EACH test
    TEMP_FILE="/tmp/test-$$.txt"
    echo "test data" > "${TEMP_FILE}"
}

test_teardown() {
    # Runs after EACH test (even if test fails)
    rm -f "${TEMP_FILE}"
}

test-mytest-with-hooks() {
    # TEMP_FILE is ready to use
    local content=$(cat "${TEMP_FILE}")
    assert_equals "test data" "${content}"
}
```

**Learn more:** See [HOOKS.md](HOOKS.md) for complete guide with examples.

## Key Features

✅ **Automatic Discovery** - Just create `test-*.sh` files with `test-*()` functions
✅ **Pattern Filtering** - Include/exclude with wildcards
✅ **Test Isolation** - Each suite runs in subshell
✅ **Fail Fast** - Stop on first failure
✅ **Multiple Modes** - List, dry-run, or execute
✅ **Shell Support** - bash 3.2+ and zsh
✅ **Test Hooks** - Setup/teardown for each test

## Common Patterns

### Run integration tests only
```bash
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --include-test "test-integration*"
```

### Skip slow and flaky tests
```bash
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --exclude-test "*:test-*-slow" \
    --exclude-test "*:test-*-flaky"
```

### CI/CD friendly
```bash
# Stop on first failure for fast feedback
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --fail-fast true

# List what will run
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --list-tests-included
```

## Environment Setup

```bash
# Set scripts directory variable
export DAQ_TESTS_SCRIPTS_DIR="../../../scripts"

# Now can run with shorter commands
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}"
```

## Debugging

```bash
# Verbose discovery
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" --verbose --dry-run

# See what matches your pattern
./test-runner.sh --suites-dir ./suites --scripts-dir "${DAQ_TESTS_SCRIPTS_DIR}" \
    --include-test "test-*:test-api*" \
    --list-tests-included
```

## See Full Documentation

Read [README.md](README.md) for complete documentation.
