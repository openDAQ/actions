# Test Runner for Shell Scripts

A flexible and powerful test runner for bash and zsh scripts with support for filtering, isolation, and detailed reporting.

## Features

- ✅ **Shell Compatibility**: Supports bash 3.2+ and zsh
- 🎯 **Smart Filtering**: Include/exclude tests with wildcard patterns
- 🔒 **Test Isolation**: Each test suite runs in a subshell for clean context
- 📊 **Detailed Statistics**: Track passed, failed, included, and excluded tests
- 🚀 **Fail-Fast Mode**: Stop on first failure for faster feedback
- 🔍 **Discovery Modes**: List suites, tests, and see what will run
- 📝 **Verbose Logging**: Optional detailed output for debugging
- 🪝 **Test Hooks**: Setup and teardown functions for each test

## Requirements

- bash 3.2 or higher, OR
- zsh (any recent version)

## Installation

### Setting Up Environment

The test runner requires access to scripts being tested via the `SCRIPTS_DIR` environment variable:

```bash
# Set scripts directory environment variable
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)" # "path/to/scripts"

# Or pass as command-line argument
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --scripts-dir /path/to/scripts
```

### Using Scripts in Tests

```bash
#!/usr/bin/env bash
# test-example.sh

test-example-with-script() {
    # Option 1: Source the script
    source "${__DAQ_TESTS_SCRIPTS_DIR}/shell/bash/math-utils.sh"
    local result=$(add 2 3)
    assert_equals "5" "${result}"
    
    # Option 2: Execute as command
    local SCRIPT="${__DAQ_TESTS_SCRIPTS_DIR}/shell/bash/version-format.sh"
    local output=$($SCRIPT --version "1.2.3")
    assert_contains "1.2.3" "${output}"
}
```

### Directory Structure

Place test runner in your project:

```bash
your-project/
├── scripts/shell/bash/         # Production scripts to be tested
│   └── production-scripts.sh
├── scripts-demo/shell/bash/    # Framework scripts to parform self-tests
│   └── math-utils.sh
└── tests/shell/bash/           # Test framework
    ├── core/                   # Framework modules
    │   ├── compat.sh
    │   ├── filter.sh
    │   ├── log.sh
    │   ├── assert.sh
    │   └── paths.sh
    ├── suites/                 # Production test suites
    │   └── test-*.sh
    ├── suites-demo/            # Test suites for self-tests
    │   └── test-*.sh
    └── test-runner.sh
```

## Writing Tests

### Test Suite Format

Create a file named `test-<suite-name>.sh` in the suites directory:

```bash
#!/usr/bin/env bash
# test-example.sh

# Each test is a function starting with "test-"
test-example-simple() {
    # Test logic here
    # Return 0 for success, non-zero for failure
    
    if [[ "hello" == "hello" ]]; then
        return 0
    else
        echo "Test failed: strings don't match"
        return 1
    fi
}

test-example-another() {
    local result=$((2 + 2))
    
    if [[ ${result} -eq 4 ]]; then
        return 0
    else
        echo "Math is broken: 2+2=${result}"
        return 1
    fi
}
```

### Test Naming Convention

- **Suite file**: `test-<suite-name>.sh`
- **Test function**: `test-<test-name>()`

Examples:
- Suite: `test-integration.sh` → Tests: `test-api-call()`, `test-database-connection()`
- Suite: `test-unit.sh` → Tests: `test-parse-json()`, `test-validate-input()`

### Using Test Hooks

Add optional setup and teardown hooks to your test suite:

```bash
#!/usr/bin/env bash
# test-example.sh

# Runs before EACH test
test_setup() {
    TEMP_FILE="/tmp/test-$$.txt"
    echo "test data" > "${TEMP_FILE}"
}

# Runs after EACH test (even if test fails)
test_teardown() {
    rm -f "${TEMP_FILE}"
}

test-example-with-hooks() {
    # TEMP_FILE is created by test_setup
    local content=$(cat "${TEMP_FILE}")
    [[ "${content}" == "test data" ]]
}
```

**Key points:**
- `test_setup()` runs before each test (optional)
- `test_teardown()` runs after each test, even if it fails (optional)
- Setup failure causes test to be skipped
- Each test gets fresh environment (subshell isolation)

**Learn more:** See [HOOKS.md](HOOKS.md) for complete guide with examples.

## Usage

### Basic Usage

```bash
# Set scripts directory
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

# Run all tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"

# Run with verbose output
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --verbose

# Stop on first failure
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --fail-fast true
```

### Filtering Tests

```bash
# Set scripts directory
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

# Run only specific suite
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --include-test "test-basic"

# Run specific test in a suite
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --include-test "test-basic:test-basic-pass"

# Run multiple patterns
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --include-test "test-basic*" \
    --include-test "test-integration:test-integration-files"

# Exclude tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --exclude-test "*:test-*-slow"

# Combine include and exclude (exclude has priority)
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --include-test "test-integration*" \
    --exclude-test "*:test-integration-fail"
```

### Pattern Syntax

- `test-<suite>` - Match entire suite (all tests in it)
- `test-<suite>:test-<test>` - Match specific test
- `test-*` - Wildcard for any characters
- `*:test-*-slow` - All tests ending with "-slow" in any suite

### Discovery Modes

```bash
# Set scripts directory
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

# List all discovered suites
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --list-suites

# List all discovered tests
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --list-tests

# List tests that will run (after filtering)
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --include-test "test-basic*" \
    --list-tests-included

# List tests that will be skipped
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --exclude-test "*:test-*-slow" \
    --list-tests-excluded
```

### Dry Run

```bash
# Set scripts directory
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

# See what would run without executing
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --dry-run

# Dry run with verbose output (human-readable)
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --dry-run --verbose

# Output format (non-verbose):
# +test-basic:test-basic-pass     (will run)
# -test-basic:test-basic-skip     (will skip)

# Output format (verbose):
# test-basic
#   ✅ test-basic-pass
#   ⚫ test-basic-skip
```

## Environment Variables

```bash
# Set default directories
export OPENDAQ_TESTS_SUITES_DIR="/path/to/suites"
export OPENDAQ_TESTS_SCRIPTS_DIR="/path/to/scripts"

# Run without --suites-dir flag
./test-runner.sh

# Command line flags override environment variables
./test-runner.sh --suites-dir ./other-suites
```

## Examples

### Example 1: Run All Tests

```bash
export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

$ ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"

Running tests...

Running suite: test-basic
Running suite: test-integration
Running suite: test-advanced

============================================
Test Results
============================================
Total suites:    3
Total tests:     13
Included tests:  13
Excluded tests:  0

Passed:  12
Failed:  1
============================================
```

### Example 2: Verbose Output

```bash
$ export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

$ ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --verbose

Discovering test suites in: ./suites
  Found suite: test-basic
  Found suite: test-integration
  Found suite: test-advanced
Total suites discovered: 3

Discovering tests in all suites...
  Discovering tests in: test-basic
    Found test: test-basic-pass
    Found test: test-basic-simple
...
```

### Example 3: Filtered Tests

```bash
$ export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

$ ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" \
    --include-test "test-basic*" \
    --exclude-test "*:test-basic-arrays"

Running tests...

Running suite: test-basic
  Running: test-basic-pass
  Running: test-basic-simple
  Running: test-basic-strings
  Skipping: test-basic-arrays (excluded)

============================================
Test Results
============================================
Total suites:    3
Total tests:     13
Included tests:  3
Excluded tests:  10

Passed:  3
Failed:  0
============================================
```

### Example 4: Fail Fast

```bash
$ export SCRIPTS_DIR="$(cd ../../../scripts/shell/bash && pwd)"

$ ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --fail-fast true

Running tests...

Running suite: test-integration
❌     test-integration-fail FAILED
❌ Stopping due to --fail-fast

============================================
Test Results
============================================
Total suites:    3
Total tests:     13
Included tests:  13
Excluded tests:  0

Passed:  2
Failed:  1
============================================
```

## Advanced Usage

### Accessing Scripts from Tests

If you have helper scripts in a separate directory:

```bash
# Set scripts directory
export OPENDAQ_TESTS_SCRIPTS_DIR="/path/to/scripts"

# Or use flag
./test-runner.sh \
    --scripts-dir ./scripts \
    --suites-dir ./suites
```

In your test suite:

```bash
test-example-with-script() {
    # Access scripts via environment variable
    source "${__DAQ_TESTS_SCRIPTS_DIR}/helper.sh"
    
    # Use functions from helper script
    local result=$(helper_function)
    
    if [[ "${result}" == "expected" ]]; then
        return 0
    else
        return 1
    fi
}
```

### Test Isolation

Each test suite runs in a subshell, providing automatic context isolation:

```bash
# test-isolation.sh
export MY_VAR="suite_value"

test-isolation-first() {
    export MY_VAR="test1_value"
    return 0
}

test-isolation-second() {
    # MY_VAR is "suite_value" here, not "test1_value"
    # Each test gets a fresh copy of the suite environment
    echo "MY_VAR is: ${MY_VAR}"
    return 0
}
```

## API Reference

### Public Functions

These functions are available for use in test suites:

#### Filter Functions

- `daq_tests_filter_include_test "pattern"` - Add include pattern
- `daq_tests_filter_exclude_test "pattern"` - Add exclude pattern
- `daq_tests_filter_include_suite "pattern"` - Include entire suite
- `daq_tests_filter_exclude_suite "pattern"` - Exclude entire suite
- `daq_tests_filter_should_run_test "suite" "test"` - Check if test should run

### Environment Variables

#### Public Variables

- `OPENDAQ_TESTS_SCRIPTS_DIR` - Path to scripts directory
- `OPENDAQ_TESTS_SUITES_DIR` - Path to suites directory

### Naming Conventions

- **Private variables**: `__DAQ_TESTS_*` (double underscore prefix)
- **Public variables**: `OPENDAQ_TESTS_*`
- **Private functions**: `__daq_tests_*` (double underscore prefix)
- **Public functions**: `daq_tests_*`

## Troubleshooting

### Tests Not Discovered

**Problem**: No tests are found

**Solution**:
- Ensure suite files are named `test-*.sh`
- Ensure test functions are named `test-*()`
- Check that files have execute permissions
- Use `--verbose` to see discovery process

### Pattern Not Matching

**Problem**: Filter patterns don't work as expected

**Solution**:
- Use `--list-tests-included` to see what matches
- Remember that exclude has priority over include
- Use `--dry-run --verbose` to debug filters
- Check pattern syntax: `suite:test` not `suite.test`

### Shell Compatibility Issues

**Problem**: Script fails on older bash or zsh

**Solution**:
- Check bash version: `bash --version` (need 3.2+)
- Try running in bash explicitly: `bash ./test-runner.sh ...`
- Check for bash-specific syntax in your tests

## See Also

- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and design
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Implementation details and status
- [HOOKS.md](HOOKS.md) - Test hooks guide (setup/teardown)
- [WINDOWS.md](WINDOWS.md) - Windows support and path conversion
- [CI.md](CI.md) - CI/CD integration guide
- [INDEX.md](INDEX.md) - Documentation index

## Contributing

When adding new features:

1. Follow naming conventions (private/public prefixes)
2. Add comments in English
3. Test with both bash 3.2+ and zsh
4. Use compatibility layer functions from `core/compat.sh`
5. Update documentation

## License

Apache License 2.0 © openDAQ

## Credits

Developed for OpenDAQ project test automation.
