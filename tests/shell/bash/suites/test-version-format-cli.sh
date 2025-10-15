#!/usr/bin/env bash
# test-version-format-cli.sh - CLI tests for version-format.sh
#
# Tests the command-line interface of version-format.sh:
# - Help and usage
# - compose command
# - parse command
# - validate command
# - extract command

# CLI script path
VERSION_FORMAT_CLI="${__DAQ_TESTS_SCRIPTS_DIR}/version-format.sh"

test-cli-help-flag() {
    local result
    result=$("${VERSION_FORMAT_CLI}" --help 2>&1)
    local exit_code=$?
    
    daq_assert_success $exit_code "help should succeed" || return 1
    daq_assert_contains "Usage:" "$result" "Help should contain usage" || return 1
    return 0
}

test-cli-no-arguments() {
    local result
    result=$("${VERSION_FORMAT_CLI}" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "no arguments should fail" || return 1
    daq_assert_contains "Usage:" "$result" "Should show usage on error" || return 1
    return 0
}

test-cli-compose-basic() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Basic compose result mismatch" || return 1
    return 0
}

test-cli-compose-with-rc() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3 --suffix rc)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3-rc" "$result" "RC compose result mismatch" || return 1
    return 0
}

test-cli-compose-with-hash() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3 --hash a1b2c3d)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3-a1b2c3d" "$result" "Hash compose result mismatch" || return 1
    return 0
}

test-cli-compose-exclude-prefix() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3 --exclude-prefix)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3" "$result" "Compose without prefix result mismatch" || return 1
    return 0
}

test-cli-compose-missing-required() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail with missing arguments" || return 1
    return 0
}

test-cli-compose-invalid-suffix() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3 --suffix invalid 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail with invalid suffix" || return 1
    return 0
}

test-cli-compose-with-format() {
    local result
    result=$("${VERSION_FORMAT_CLI}" compose --major 1 --minor 2 --patch 3 --format "X.YY.Z")
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3" "$result" "Format compose result mismatch" || return 1
    return 0
}

test-cli-parse-basic() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1 2 3   v" "$result" "Parse result mismatch" || return 1
    return 0
}

test-cli-parse-extract-major() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3 --major)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1" "$result" "Major parse result mismatch" || return 1
    return 0
}

test-cli-parse-extract-minor() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3 --minor)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "2" "$result" "Minor parse result mismatch" || return 1
    return 0
}

test-cli-parse-extract-patch() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3 --patch)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "3" "$result" "Patch parse result mismatch" || return 1
    return 0
}

test-cli-parse-rc-version() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3-rc --suffix)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "rc" "$result" "RC suffix parse result mismatch" || return 1
    return 0
}

test-cli-parse-hash-version() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse v1.2.3-a1b2c3d --hash)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "a1b2c3d" "$result" "Hash parse result mismatch" || return 1
    return 0
}

test-cli-parse-invalid() {
    local result
    result=$("${VERSION_FORMAT_CLI}" parse invalid 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "parse should fail with invalid version" || return 1
    return 0
}

test-cli-validate-valid() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3 >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid version" || return 1
    return 0
}

test-cli-validate-invalid() {
    "${VERSION_FORMAT_CLI}" validate not-valid >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for invalid version" || return 1
    return 0
}

test-cli-validate-with-format-match() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3 --format "vX.YY.Z" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for matching format" || return 1
    return 0
}

test-cli-validate-with-format-mismatch() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3 --format "X.YY.Z" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for mismatching format" || return 1
    return 0
}

test-cli-validate-is-release() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3 --is-release >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for release" || return 1
    return 0
}

test-cli-validate-is-rc-true() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3-rc --is-rc >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for RC" || return 1
    return 0
}

test-cli-validate-is-dev-true() {
    "${VERSION_FORMAT_CLI}" validate v1.2.3-a1b2c3d --is-dev >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for dev version" || return 1
    return 0
}

test-cli-extract-from-text() {
    local result
    result=$("${VERSION_FORMAT_CLI}" extract "opendaq-v1.2.3-linux.tar.gz")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Extract result mismatch" || return 1
    return 0
}

test-cli-extract-no-version() {
    local result
    result=$("${VERSION_FORMAT_CLI}" extract "no-version.txt" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "extract should fail when no version" || return 1
    return 0
}

test-cli-extract-rc() {
    local result
    result=$("${VERSION_FORMAT_CLI}" extract "opendaq-v1.2.3-rc-ubuntu20.04-x86_64.deb")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3-rc" "$result" "RC extract result mismatch" || return 1
    return 0
}

test-cli-extract-hash() {
    local result
    result=$("${VERSION_FORMAT_CLI}" extract "opendaq-v1.2.3-a1b2c3d-ubuntu20.04-x86_64.deb")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3-a1b2c3d" "$result" "Hash extract result mismatch" || return 1
    return 0
}

test-cli-extract-multiple-versions() {
    local result
    result=$("${VERSION_FORMAT_CLI}" extract "v1.2.3-to-v5.6.7")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Should extract first version" || return 1
    return 0
}
