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
        # Return fake JSON
        echo '{"tag_name": "v1.2.3", "assets": [], "workflow_runs": [], "artifacts": []}'
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
    *"tag_name"*) echo "v1.2.3" ;;
    *"name"*) echo "test-asset.tar.gz" ;;
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
    
    daq_assert_failure $exit_code "Should fail with no args" || return 1
    daq_assert_contains "Repository not specified" "$output" "Should show error" || return 1
    
    return 0
}

test-cli-help-shorthand() {
    local output
    output=$("$SCRIPT_PATH" -h 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "-h should succeed" || return 1
    daq_assert_contains "Usage:" "$output" "Should show usage" || return 1
    
    return 0
}

test-cli-unknown-option() {
    local output
    output=$("$SCRIPT_PATH" owner/repo --invalid-option 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Unknown option should fail" || return 1
    daq_assert_contains "Unknown option" "$output" "Should mention unknown option" || return 1
    
    return 0
}

test-cli-version-default() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should resolve version" || return 1
    daq_assert_contains "v1.2.3" "$output" "Should output version" || return 1
    
    return 0
}

test-cli-version-explicit() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --version v1.2.3 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept explicit version" || return 1
    
    return 0
}

test-cli-version-missing-value() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --version 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail with missing version" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1
    
    return 0
}

test-cli-list-versions() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-versions 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list versions" || return 1
    
    return 0
}

test-cli-list-versions-limit() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-versions --limit 5 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept limit" || return 1
    
    return 0
}

test-cli-pattern-with-assets() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-assets --pattern "*.tar.gz" 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should filter by pattern" || return 1
    
    return 0
}

test-cli-pattern-missing-value() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --pattern 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail with missing pattern" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1
    
    return 0
}

test-cli-pattern-wildcards() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-assets --pattern "*linux*" 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept wildcards" || return 1
    
    return 0
}

test-cli-list-assets-no-pattern() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-assets 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list all assets" || return 1
    
    return 0
}

test-cli-download-missing-output() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-asset 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail without output-dir" || return 1
    daq_assert_contains "output-dir is required" "$output" "Should mention required output-dir" || return 1
    
    return 0
}

test-cli-output-missing-value() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --output-dir 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail with missing value" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1
    
    return 0
}

test-cli-download-with-output() {
    local temp_dir="$__DAQ_TESTS_SCRIPTS_DIR/tmp/test-$$"
    mkdir -p "$temp_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-asset --output-dir "$temp_dir" 2>&1)
    
    rm -rf "$temp_dir"
    
    daq_assert_not_contains "output-dir is required" "$output" "Should not complain about output-dir" || return 1
    
    return 0
}

test-cli-output-relative() {
    local rel_dir="./test-$$"
    mkdir -p "$rel_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-asset --output-dir "$rel_dir" 2>&1)
    
    rm -rf "$rel_dir"
    
    daq_assert_not_contains "output-dir is required" "$output" "Should accept relative path" || return 1
    
    return 0
}

test-cli-artifact-missing-output() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-artifact --run-id 123 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail without output-dir" || return 1
    daq_assert_contains "output-dir is required" "$output" "Should mention required output-dir" || return 1
    
    return 0
}

test-cli-limit-numeric() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-versions --limit 10 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept numeric limit" || return 1
    
    return 0
}

test-cli-limit-all() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-versions --limit all 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept 'all'" || return 1
    
    return 0
}

test-cli-limit-missing-value() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-versions --limit 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail with missing limit" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1
    
    return 0
}

test-cli-artifacts-missing-run-id() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-artifacts 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail without run-id" || return 1
    daq_assert_contains "run-id is required" "$output" "Should mention required run-id" || return 1
    
    return 0
}

test-cli-run-id-missing-value() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --run-id 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail with missing value" || return 1
    daq_assert_contains "requires an argument" "$output" "Should mention missing argument" || return 1
    
    return 0
}

test-cli-list-artifacts() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-artifacts --run-id 123 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list artifacts" || return 1
    
    return 0
}

test-cli-download-artifact-no-run() {
    local temp_dir="$__DAQ_TESTS_SCRIPTS_DIR/tmp/test-$$"
    mkdir -p "$temp_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-artifact --output-dir "$temp_dir" 2>&1)
    local exit_code=$?
    
    rm -rf "$temp_dir"
    
    daq_assert_failure $exit_code "Should fail without run-id" || return 1
    daq_assert_contains "run-id is required" "$output" "Should mention required run-id" || return 1
    
    return 0
}

test-cli-verbose() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --verbose 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept verbose" || return 1
    
    return 0
}

test-cli-extract() {
    local temp_dir="$__DAQ_TESTS_SCRIPTS_DIR/tmp/test-$$"
    mkdir -p "$temp_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-artifact --run-id 123 --output-dir "$temp_dir" --extract 2>&1)
    
    rm -rf "$temp_dir"
    
    daq_assert_not_contains "Unknown option" "$output" "Should accept extract" || return 1
    
    return 0
}

test-cli-list-runs() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-runs 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list runs" || return 1
    
    return 0
}

test-cli-default-action() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Default action should work" || return 1
    
    return 0
}

test-cli-list-assets() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-assets 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list assets" || return 1
    
    return 0
}

test-cli-list-assets-version() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --list-assets --version v1.0.0 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should list assets for version" || return 1
    
    return 0
}

test-cli-download-asset() {
    local temp_dir="$__DAQ_TESTS_SCRIPTS_DIR/tmp/test-$$"
    mkdir -p "$temp_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-asset --output-dir "$temp_dir" 2>&1)
    
    rm -rf "$temp_dir"
    
    daq_assert_not_contains "Unknown option" "$output" "Should recognize download-asset" || return 1
    
    return 0
}

test-cli-download-artifact() {
    local temp_dir="$__DAQ_TESTS_SCRIPTS_DIR/tmp/test-$$"
    mkdir -p "$temp_dir"
    
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ --download-artifact --run-id 123 --output-dir "$temp_dir" 2>&1)
    
    rm -rf "$temp_dir"
    
    daq_assert_not_contains "Unknown option" "$output" "Should recognize download-artifact" || return 1
    
    return 0
}

test-cli-repo-valid() {
    local output
    output=$("$SCRIPT_PATH" openDAQ/openDAQ 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "Should accept valid repo" || return 1
    
    return 0
}

test-cli-repo-invalid() {
    local output
    output=$("$SCRIPT_PATH" invalidrepo 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should reject invalid repo" || return 1
    daq_assert_contains "Invalid repository format" "$output" "Should mention invalid format" || return 1
    
    return 0
}

test-cli-repo-missing() {
    local output
    output=$("$SCRIPT_PATH" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should fail without repo" || return 1
    daq_assert_contains "Repository not specified" "$output" "Should mention missing repo" || return 1
    
    return 0
}
