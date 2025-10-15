#!/usr/bin/env bash
# test-platform-format-cli.sh - CLI tests for platform-format.sh
#
# Tests the command-line interface of platform-format.sh:
# - Help and usage
# - detect command
# - validate command
# - parse/extract command
# - compose command
# - --list-platforms flag

# CLI script path
PLATFORM_FORMAT_CLI="${__DAQ_TESTS_SCRIPTS_DIR}/platform-format.sh"

test-cli-help-global() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" 2>&1)  # No command
    local exit_code=$?
    
    daq_assert_failure $exit_code "Should exit with error"
    daq_assert_contains "Usage:" "$result" "Should show usage"
    daq_assert_contains "Commands:" "$result" "Should show commands"
}

test-cli-detect-current-platform() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" detect 2>/dev/null)
    local exit_code=$?
    
    # Detection may fail on some systems
    if [[ $exit_code -eq 0 ]]; then
        daq_assert_not_empty "$result" "detect should return platform" || return 1
    fi
    
    return 0
}

test-cli-validate-ubuntu-valid() {
    "${PLATFORM_FORMAT_CLI}" validate "ubuntu20.04-x86_64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Ubuntu" || return 1
    return 0
}

test-cli-validate-debian-valid() {
    "${PLATFORM_FORMAT_CLI}" validate "debian11-arm64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Debian" || return 1
    return 0
}

test-cli-validate-macos-valid() {
    "${PLATFORM_FORMAT_CLI}" validate "macos14-arm64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid macOS" || return 1
    return 0
}

test-cli-validate-windows-valid() {
    "${PLATFORM_FORMAT_CLI}" validate "win64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Windows" || return 1
    return 0
}

test-cli-validate-invalid() {
    "${PLATFORM_FORMAT_CLI}" validate "invalid-platform" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for invalid platform" || return 1
    return 0
}

test-cli-validate-is-unix() {
    "${PLATFORM_FORMAT_CLI}" validate "ubuntu20.04-x86_64" --is-unix >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Ubuntu should be Unix" || return 1
    return 0
}

test-cli-validate-is-linux() {
    "${PLATFORM_FORMAT_CLI}" validate "debian11-arm64" --is-linux >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Debian should be Linux" || return 1
    return 0
}

test-cli-validate-is-macos() {
    "${PLATFORM_FORMAT_CLI}" validate "macos14-arm64" --is-macos >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify macOS" || return 1
    return 0
}

test-cli-validate-is-win() {
    "${PLATFORM_FORMAT_CLI}" validate "win64" --is-win >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify Windows" || return 1
    return 0
}

test-cli-parse-ubuntu() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "ubuntu20.04-x86_64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "ubuntu 20.04 x86_64" "$result" "Ubuntu parse result mismatch" || return 1
    return 0
}

test-cli-parse-debian() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "debian11-arm64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "debian 11 arm64" "$result" "Debian parse result mismatch" || return 1
    return 0
}

test-cli-parse-macos() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "macos14-arm64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "macos 14 arm64" "$result" "macOS parse result mismatch" || return 1
    return 0
}

test-cli-parse-windows() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "win64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "win 64" "$result" "Windows parse result mismatch" || return 1
    return 0
}

test-cli-parse-extract-os-name() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "ubuntu20.04-x86_64" --os-name)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "ubuntu" "$result" "OS name extraction mismatch" || return 1
    return 0
}

test-cli-parse-extract-os-version() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "ubuntu20.04-x86_64" --os-version)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "20.04" "$result" "OS version extraction mismatch" || return 1
    return 0
}

test-cli-parse-extract-os-arch() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "ubuntu20.04-x86_64" --os-arch)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "x86_64" "$result" "OS arch extraction mismatch" || return 1
    return 0
}

test-cli-parse-invalid() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" parse "invalid-platform" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "parse should fail for invalid platform" || return 1
    return 0
}

test-cli-extract-os-name() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" extract "debian11-arm64" --os-name)
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "debian" "$result" "Extract OS name mismatch" || return 1
    return 0
}

test-cli-extract-multiple-components() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" extract "macos14-arm64" --os-name --os-arch)
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_contains "macos" "$result" "Should contain OS name" || return 1
    daq_assert_contains "arm64" "$result" "Should contain architecture" || return 1
    return 0
}

test-cli-compose-ubuntu() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name ubuntu --os-version 20.04 --os-arch x86_64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "ubuntu20.04-x86_64" "$result" "Ubuntu compose result mismatch" || return 1
    return 0
}

test-cli-compose-debian() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name debian --os-version 11 --os-arch arm64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "debian11-arm64" "$result" "Debian compose result mismatch" || return 1
    return 0
}

test-cli-compose-macos() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name macos --os-version 14 --os-arch arm64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "macos14-arm64" "$result" "macOS compose result mismatch" || return 1
    return 0
}

test-cli-compose-windows() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name win --os-arch 64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "win64" "$result" "Windows compose result mismatch" || return 1
    return 0
}

test-cli-compose-missing-os-name() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-version 20.04 --os-arch x86_64 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail without os-name" || return 1
    return 0
}

test-cli-compose-missing-os-arch() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name ubuntu --os-version 20.04 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail without os-arch" || return 1
    return 0
}

test-cli-compose-invalid-combination() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" compose --os-name ubuntu --os-version 99.99 --os-arch x86_64 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail for invalid version" || return 1
    return 0
}

test-cli-list-platforms() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" --list-platforms)
    local exit_code=$?
    
    daq_assert_success $exit_code "list-platforms should succeed" || return 1
    daq_assert_not_empty "$result" "Should return platforms" || return 1
    return 0
}

test-cli-list-platforms-contains-ubuntu() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" --list-platforms)
    
    daq_assert_contains "ubuntu20.04-x86_64" "$result" "Should contain Ubuntu" || return 1
    return 0
}

test-cli-list-platforms-contains-windows() {
    local result
    result=$("${PLATFORM_FORMAT_CLI}" --list-platforms)
    
    daq_assert_contains "win64" "$result" "Should contain Windows 64-bit" || return 1
    return 0
}

test-cli-list-platforms-count() {
    local count
    count=$("${PLATFORM_FORMAT_CLI}" --list-platforms | wc -l)
    
    # Expected: 32 platforms
    # Ubuntu: 3 versions × 2 archs = 6
    # Debian: 5 versions × 2 archs = 10
    # macOS: 7 versions × 2 archs = 14
    # Windows: 2 archs = 2
    # Total: 32
    daq_assert_num_equals 32 "$count" "Should have exactly 32 platforms" || return 1
    return 0
}
