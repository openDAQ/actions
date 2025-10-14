# Test Hooks Guide

## Overview

The test runner supports setup and teardown hooks that run before and after each test. These hooks allow you to:

- Prepare test environment (create files, set variables, etc.)
- Clean up after tests (remove temp files, reset state, etc.)
- Share common setup/teardown logic across all tests in a suite

## Available Hooks

### `test_setup()` - Before Each Test

Called **before each test** in the suite. Use this to:
- Create temporary files or directories
- Initialize test data
- Set up test environment variables
- Prepare any resources the test needs

### `test_teardown()` - After Each Test

Called **after each test** in the suite (even if the test fails). Use this to:
- Remove temporary files or directories
- Clean up resources
- Reset environment state
- Close connections

## Important Notes

### Execution Model

1. Each test runs in a **separate subshell**
2. `test_setup()` is called at the start of that subshell
3. The test function is executed
4. `test_teardown()` is called at the end (even if test failed)
5. Subshell exits, cleaning up everything

### Isolation

- Each test gets a **fresh environment**
- Variables set in one test don't affect other tests
- Modifications in `test_setup()` are visible only to that test

### Error Handling

- If `test_setup()` fails (returns non-zero), the test is **skipped** and marked as failed
- If the test fails, `test_teardown()` is **still called**
- If `test_teardown()` fails, a **warning is logged** but the test result is not changed

## Example: Basic Usage

```bash
#!/usr/bin/env bash
# test-example.sh

# Global variable (will be reset for each test due to subshell)
TEST_FILE=""

# Setup before each test
test_setup() {
    TEST_FILE="/tmp/test-$$-${RANDOM}.txt"
    echo "initial data" > "${TEST_FILE}"
}

# Teardown after each test
test_teardown() {
    rm -f "${TEST_FILE}"
}

# Test 1
test-example-first() {
    # TEST_FILE is created and contains "initial data"
    local content=$(cat "${TEST_FILE}")
    [[ "${content}" == "initial data" ]]
}

# Test 2
test-example-second() {
    # Fresh TEST_FILE, not affected by test 1
    local content=$(cat "${TEST_FILE}")
    [[ "${content}" == "initial data" ]]
}
```

## Example: Database Setup

```bash
#!/usr/bin/env bash
# test-database.sh

DB_FILE=""

test_setup() {
    # Create fresh database for each test
    DB_FILE="/tmp/test-db-$$.sqlite"
    sqlite3 "${DB_FILE}" "CREATE TABLE users (id INT, name TEXT);"
    sqlite3 "${DB_FILE}" "INSERT INTO users VALUES (1, 'Alice');"
    sqlite3 "${DB_FILE}" "INSERT INTO users VALUES (2, 'Bob');"
}

test_teardown() {
    # Clean up database
    rm -f "${DB_FILE}"
}

test-database-select() {
    local count
    count=$(sqlite3 "${DB_FILE}" "SELECT COUNT(*) FROM users;")
    [[ "${count}" == "2" ]]
}

test-database-insert() {
    sqlite3 "${DB_FILE}" "INSERT INTO users VALUES (3, 'Charlie');"
    local count
    count=$(sqlite3 "${DB_FILE}" "SELECT COUNT(*) FROM users;")
    [[ "${count}" == "3" ]]
}

test-database-delete() {
    # This test modifies the database, but next test will get fresh DB
    sqlite3 "${DB_FILE}" "DELETE FROM users WHERE id=1;"
    local count
    count=$(sqlite3 "${DB_FILE}" "SELECT COUNT(*) FROM users;")
    [[ "${count}" == "1" ]]
}
```

## Example: API Mock Server

```bash
#!/usr/bin/env bash
# test-api.sh

MOCK_SERVER_PID=""
MOCK_PORT=8888

test_setup() {
    # Start mock server in background
    python3 -m http.server ${MOCK_PORT} &>/dev/null &
    MOCK_SERVER_PID=$!
    
    # Wait for server to start
    sleep 0.5
    
    # Verify server is running
    if ! kill -0 ${MOCK_SERVER_PID} 2>/dev/null; then
        echo "Failed to start mock server"
        return 1
    fi
}

test_teardown() {
    # Stop mock server
    if [[ -n "${MOCK_SERVER_PID}" ]]; then
        kill ${MOCK_SERVER_PID} 2>/dev/null || true
        wait ${MOCK_SERVER_PID} 2>/dev/null || true
    fi
}

test-api-health-check() {
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${MOCK_PORT}/)
    [[ "${response}" == "200" ]]
}

test-api-timeout() {
    # Test with 1 second timeout
    timeout 1 curl -s http://localhost:${MOCK_PORT}/ >/dev/null
    [[ $? -eq 0 ]]
}
```

## Example: Environment Variables

```bash
#!/usr/bin/env bash
# test-environment.sh

ORIGINAL_PATH="${PATH}"
ORIGINAL_HOME="${HOME}"

test_setup() {
    # Modify environment for testing
    export PATH="/custom/test/path:${PATH}"
    export HOME="/tmp/test-home"
    export TEST_MODE="true"
    
    # Create test home directory
    mkdir -p "${HOME}"
}

test_teardown() {
    # Restore original environment
    export PATH="${ORIGINAL_PATH}"
    export HOME="${ORIGINAL_HOME}"
    unset TEST_MODE
    
    # Clean up test home
    rm -rf "/tmp/test-home"
}

test-environment-path() {
    [[ "${PATH}" == /custom/test/path:* ]]
}

test-environment-home() {
    [[ "${HOME}" == "/tmp/test-home" ]]
}

test-environment-test-mode() {
    [[ "${TEST_MODE}" == "true" ]]
}
```

## Example: Complex Setup with Validation

```bash
#!/usr/bin/env bash
# test-complex.sh

TEMP_DIR=""
CONFIG_FILE=""

test_setup() {
    # Create temp directory
    TEMP_DIR="/tmp/test-complex-$$"
    mkdir -p "${TEMP_DIR}"
    
    # Verify directory was created
    if [[ ! -d "${TEMP_DIR}" ]]; then
        echo "ERROR: Failed to create temp directory"
        return 1
    fi
    
    # Create config file
    CONFIG_FILE="${TEMP_DIR}/config.json"
    cat > "${CONFIG_FILE}" << 'EOF'
{
  "version": "1.0",
  "enabled": true,
  "timeout": 30
}
EOF
    
    # Verify config file was created
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        echo "ERROR: Failed to create config file"
        rm -rf "${TEMP_DIR}"
        return 1
    fi
    
    echo "Setup complete: ${TEMP_DIR}"
}

test_teardown() {
    # Clean up everything
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
        echo "Cleanup complete"
    fi
}

test-complex-config-exists() {
    [[ -f "${CONFIG_FILE}" ]]
}

test-complex-config-valid() {
    # Parse JSON and verify fields
    local version
    version=$(grep -o '"version": "[^"]*"' "${CONFIG_FILE}" | cut -d'"' -f4)
    [[ "${version}" == "1.0" ]]
}
```

## Hooks Execution Flow

```
For each test in suite:
  ┌─────────────────────────────────┐
  │ Start subshell                  │
  └───────────┬─────────────────────┘
              │
              ▼
  ┌─────────────────────────────────┐
  │ Source suite file               │
  └───────────┬─────────────────────┘
              │
              ▼
  ┌─────────────────────────────────┐
  │ test_setup() exists?            │
  └───────┬─────────────┬───────────┘
          │ YES         │ NO
          ▼             │
  ┌──────────────┐      │
  │ Run setup    │      │
  │ Success? ────┼──────┤
  └──────────────┘  NO  │
          │ YES         │
          ▼             ▼
  ┌─────────────────────────────────┐
  │ Run test function               │
  └───────────┬─────────────────────┘
              │
              ▼
  ┌─────────────────────────────────┐
  │ test_teardown() exists?         │
  └───────┬─────────────┬───────────┘
          │ YES         │ NO
          ▼             │
  ┌──────────────┐      │
  │ Run teardown │      │
  │ (warn if     │      │
  │  fails)      │      │
  └──────┬───────┘      │
         │              │
         ▼              ▼
  ┌─────────────────────────────────┐
  │ Exit subshell (auto cleanup)    │
  └─────────────────────────────────┘
```

## Best Practices

### ✅ DO

- Keep setup/teardown functions **simple and focused**
- Always clean up resources in `test_teardown()`
- Use unique names for temp files (include `$$` or `${RANDOM}`)
- Validate that setup succeeded before continuing
- Log what you're doing (helps with debugging)

### ❌ DON'T

- Don't rely on state from previous tests (each test is isolated)
- Don't use global state that persists across tests
- Don't ignore cleanup errors silently
- Don't make setup too complex (keep it fast)

## Troubleshooting

### Setup Not Running

Check if the function is named correctly:
```bash
# Correct
test_setup() { ... }

# Wrong
testSetup() { ... }      # Wrong capitalization
test-setup() { ... }     # Wrong separator
setup_test() { ... }     # Wrong order
```

### Teardown Not Cleaning Up

Make sure teardown handles errors:
```bash
test_teardown() {
    # Use || true to prevent teardown errors from failing
    rm -rf "${TEMP_DIR}" 2>/dev/null || true
    
    # Or check if resource exists first
    if [[ -n "${TEMP_FILE}" && -f "${TEMP_FILE}" ]]; then
        rm -f "${TEMP_FILE}"
    fi
}
```

### State Not Isolated

Remember: each test runs in a subshell, so state is automatically isolated:
```bash
# Test 1
test-first() {
    MY_VAR="changed"
}

# Test 2
test-second() {
    # MY_VAR is NOT "changed" here - it's a fresh environment
    echo "${MY_VAR}"  # Will be empty or initial value
}
```

## Running Tests with Hooks

```bash
# Run normally - hooks will execute automatically
./test-runner.sh --suites-dir ./suites --include-test "test-hooks*"

# Use --verbose to see when hooks are called
./test-runner.sh --suites-dir ./suites --include-test "test-hooks*" --verbose

# Output shows:
#   Running: test-name
#     Running test_setup        ← Setup called
#   ✅ test-name
#     Running test_teardown     ← Teardown called
```

## See Also

- [README.md](README.md) - Complete documentation
- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
- [Example: test-hooks.sh](suites/test-hooks.sh) - Working example with hooks
