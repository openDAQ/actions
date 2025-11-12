#!/usr/bin/env bash
# test-api-github-gh-cli.sh - CLI tests for api-github-gh.sh
# Tests by calling the script as a separate process (real CLI testing)

# Path to script under test
SCRIPT_PATH="${__DAQ_TESTS_SCRIPTS_DIR}/api-github-gh.sh"

# Setup function called before each test
test_setup() {
    # Create temp directory for mocks
    MOCK_DIR="$__DAQ_TESTS_SCRIPTS_DIR/tmp/gh-api-test-$$"
    mkdir -p "$MOCK_DIR"

    # Create mock gh script
    cat > "$MOCK_DIR/gh" << 'EOF'
#!/usr/bin/env bash
case "$1" in
    "auth")
        [[ "$2" == "status" ]] && exit 0
        ;;
    "api")
        # Return fake JSON with releases
        echo '[{"tag_name": "v1.2.3"}, {"tag_name": "v1.2.2"}, {"tag_name": "v1.2.1"}]'
        exit 0
        ;;
esac
exit 1
EOF
    chmod +x "$MOCK_DIR/gh"

    # Create mock jq script
    cat > "$MOCK_DIR/jq" << 'EOF'
#!/usr/bin/env bash
case "$*" in
    *"tag_name"*)
        # Handle different jq queries
        if echo "$*" | grep -q "\\[0\\]"; then
            echo "v1.2.3"
        else
            echo "v1.2.3"
            echo "v1.2.2"
            echo "v1.2.1"
        fi
        ;;
    *) echo "mock-output" ;;
esac
exit 0
EOF
    chmod +x "$MOCK_DIR/jq"

    # Prepend mock directory to PATH
    export PATH="$MOCK_DIR:$PATH"
}

# Teardown function called after each test
test_teardown() {
    # Remove mock directory
    rm -rf "$MOCK_DIR"
}

test-cli-help-flag() {
    local output
    output=$("$SCRIPT_PATH" --help 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Help should succeed" || return 1
    daq_assert_contains "Usage:" "$output" "Should show usage" || return 1

    return 0
}

test-cli-no-args() {
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Should fail without args" || return 1
    daq_assert_contains "Repository not specified" "$output" "Should mention missing repo" || return 1

    return 0
}

test-cli-help-shorthand() {
    local output
    output=$("$SCRIPT_PATH" -h 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Help shorthand should succeed" || return 1
    daq_assert_contains "Usage:" "$output" "Should show usage" || return 1

    return 0
}

test-cli-unknown-option() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --unknown 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Should fail with unknown option" || return 1
    daq_assert_contains "Unknown option" "$output" "Should mention unknown option" || return 1

    return 0
}

test-cli-version-default() {
    local output
    output=$("$SCRIPT_PATH" owner/repo 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should get latest version" || return 1
    daq_assert_contains "v1.2.3" "$output" "Should output version" || return 1

    return 0
}

test-cli-version-explicit() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --version v1.0.0 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should check explicit version" || return 1

    return 0
}

test-cli-version-missing-value() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --version 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Should fail with missing value" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1

    return 0
}

test-cli-list-versions() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --list-versions 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should list versions" || return 1
    daq_assert_contains "v1.2" "$output" "Should contain version" || return 1

    return 0
}

test-cli-list-versions-limit() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --list-versions --limit 5 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should list versions with limit" || return 1

    return 0
}

test-cli-limit-numeric() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --list-versions --limit 10 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should accept numeric limit" || return 1

    return 0
}

test-cli-limit-all() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --list-versions --limit all 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Should accept 'all' limit" || return 1

    return 0
}

test-cli-limit-missing-value() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --list-versions --limit 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Should fail with missing value" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1

    return 0
}

test-cli-verbose() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --verbose 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Verbose should work" || return 1

    return 0
}

test-cli-default-action() {
    local output
    output=$("$SCRIPT_PATH" owner/repo 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Default action should work" || return 1
    daq_assert_contains "v1.2.3" "$output" "Should get latest version by default" || return 1

    return 0
}

test-cli-repo-valid() {
    local output
    output=$("$SCRIPT_PATH" owner/repo 2>&1)
    local exit_code=$?

    daq_assert_success $exit_code "Valid repo format should work" || return 1

    return 0
}

test-cli-repo-invalid() {
    local output
    output=$("$SCRIPT_PATH" invalid-repo 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Invalid repo format should fail" || return 1
    daq_assert_contains "Invalid repository format" "$output" "Should mention invalid format" || return 1

    return 0
}

test-cli-repo-missing() {
    local output
    output=$("$SCRIPT_PATH" --list-versions 2>&1)
    local exit_code=$?

    daq_assert_failure $exit_code "Missing repo should fail" || return 1
    daq_assert_contains "Repository not specified" "$output" "Should mention missing repo" || return 1

    return 0
}
