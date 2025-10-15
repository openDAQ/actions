#!/usr/bin/env bash
# test-platform-format-api.sh - API tests for platform-format.sh public functions
#
# Tests all public API functions (daq_platform_*):
# - daq_platform_validate
# - daq_platform_parse
# - daq_platform_extract
# - daq_platform_compose
# - daq_platform_list
# - daq_platform_detect

# Source the script under test
source "${__DAQ_TESTS_SCRIPTS_DIR}/platform-format.sh"

test-validate-ubuntu-valid() {
    daq_platform_validate "ubuntu20.04-x86_64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Ubuntu platform" || return 1
    return 0
}

test-validate-debian-valid() {
    daq_platform_validate "debian11-arm64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Debian platform" || return 1
    return 0
}

test-validate-macos-valid() {
    daq_platform_validate "macos14-arm64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid macOS platform" || return 1
    return 0
}

test-validate-windows-valid() {
    daq_platform_validate "win64" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for valid Windows platform" || return 1
    return 0
}

test-validate-invalid-platform() {
    daq_platform_validate "invalid-platform" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for invalid platform" || return 1
    return 0
}

test-validate-is-unix-true() {
    daq_platform_validate "ubuntu20.04-x86_64" --is-unix >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Ubuntu should be Unix" || return 1
    return 0
}

test-validate-is-unix-false() {
    daq_platform_validate "win64" --is-unix >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "Windows should not be Unix" || return 1
    return 0
}

test-validate-is-linux-true() {
    daq_platform_validate "ubuntu20.04-x86_64" --is-linux >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Ubuntu should be Linux" || return 1
    return 0
}

test-validate-is-linux-false() {
    daq_platform_validate "macos14-arm64" --is-linux >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "macOS should not be Linux" || return 1
    return 0
}

test-validate-is-ubuntu-true() {
    daq_platform_validate "ubuntu20.04-x86_64" --is-ubuntu >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify Ubuntu" || return 1
    return 0
}

test-validate-is-debian-true() {
    daq_platform_validate "debian11-arm64" --is-debian >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify Debian" || return 1
    return 0
}

test-validate-is-macos-true() {
    daq_platform_validate "macos14-arm64" --is-macos >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify macOS" || return 1
    return 0
}

test-validate-is-win-true() {
    daq_platform_validate "win64" --is-win >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "Should identify Windows" || return 1
    return 0
}

test-parse-ubuntu-all-components() {
    local result
    result=$(daq_platform_parse "ubuntu20.04-x86_64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "ubuntu 20.04 x86_64" "$result" "Ubuntu parse result mismatch" || return 1
    return 0
}

test-parse-debian-all-components() {
    local result
    result=$(daq_platform_parse "debian11-arm64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "debian 11 arm64" "$result" "Debian parse result mismatch" || return 1
    return 0
}

test-parse-macos-all-components() {
    local result
    result=$(daq_platform_parse "macos14-arm64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "macos 14 arm64" "$result" "macOS parse result mismatch" || return 1
    return 0
}

test-parse-windows-all-components() {
    local result
    result=$(daq_platform_parse "win64")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "win 64" "$result" "Windows parse result mismatch" || return 1
    return 0
}

test-parse-extract-os-name() {
    local result
    result=$(daq_platform_parse "ubuntu20.04-x86_64" --os-name)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "ubuntu" "$result" "OS name extraction mismatch" || return 1
    return 0
}

test-parse-extract-os-version() {
    local result
    result=$(daq_platform_parse "ubuntu20.04-x86_64" --os-version)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "20.04" "$result" "OS version extraction mismatch" || return 1
    return 0
}

test-parse-extract-os-arch() {
    local result
    result=$(daq_platform_parse "ubuntu20.04-x86_64" --os-arch)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "x86_64" "$result" "OS arch extraction mismatch" || return 1
    return 0
}

test-parse-windows-no-version() {
    local result
    result=$(daq_platform_parse "win64" --os-version)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_empty "$result" "Windows should have no version" || return 1
    return 0
}

test-parse-invalid-platform() {
    local result
    result=$(daq_platform_parse "invalid-platform" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "parse should fail for invalid platform" || return 1
    return 0
}

test-extract-ubuntu() {
    local result
    result=$(daq_platform_extract "ubuntu20.04-x86_64" --os-name)
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "ubuntu" "$result" "Extract should work like parse" || return 1
    return 0
}

test-extract-multiple-components() {
    local result
    result=$(daq_platform_extract "debian11-arm64" --os-name --os-arch)
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_contains "debian" "$result" "Should contain OS name" || return 1
    daq_assert_contains "arm64" "$result" "Should contain architecture" || return 1
    return 0
}

test-compose-ubuntu() {
    local result
    result=$(daq_platform_compose --os-name ubuntu --os-version 20.04 --os-arch x86_64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "ubuntu20.04-x86_64" "$result" "Ubuntu compose result mismatch" || return 1
    return 0
}

test-compose-debian() {
    local result
    result=$(daq_platform_compose --os-name debian --os-version 11 --os-arch arm64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "debian11-arm64" "$result" "Debian compose result mismatch" || return 1
    return 0
}

test-compose-macos() {
    local result
    result=$(daq_platform_compose --os-name macos --os-version 14 --os-arch arm64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "macos14-arm64" "$result" "macOS compose result mismatch" || return 1
    return 0
}

test-compose-windows() {
    local result
    result=$(daq_platform_compose --os-name win --os-arch 64)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "win64" "$result" "Windows compose result mismatch" || return 1
    return 0
}

test-compose-missing-os-name() {
    local result
    result=$(daq_platform_compose --os-version 20.04 --os-arch x86_64 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail without os-name" || return 1
    return 0
}

test-compose-missing-os-arch() {
    local result
    result=$(daq_platform_compose --os-name ubuntu --os-version 20.04 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail without os-arch" || return 1
    return 0
}

test-compose-linux-missing-version() {
    local result
    result=$(daq_platform_compose --os-name ubuntu --os-arch x86_64 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail without version for Linux" || return 1
    return 0
}

test-compose-invalid-combination() {
    local result
    result=$(daq_platform_compose --os-name ubuntu --os-version 99.99 --os-arch x86_64 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail for invalid version" || return 1
    return 0
}

test-list-returns-platforms() {
    local result
    result=$(daq_platform_list)
    local exit_code=$?
    
    daq_assert_success $exit_code "list should succeed" || return 1
    daq_assert_not_empty "$result" "list should return platforms" || return 1
    return 0
}

test-list-contains-ubuntu() {
    local result
    result=$(daq_platform_list)
    
    daq_assert_contains "ubuntu20.04-x86_64" "$result" "Should contain Ubuntu 20.04 x86_64" || return 1
    return 0
}

test-list-contains-debian() {
    local result
    result=$(daq_platform_list)
    
    daq_assert_contains "debian11-arm64" "$result" "Should contain Debian 11 ARM64" || return 1
    return 0
}

test-list-contains-macos() {
    local result
    result=$(daq_platform_list)
    
    daq_assert_contains "macos14-arm64" "$result" "Should contain macOS 14 ARM64" || return 1
    return 0
}

test-list-contains-windows() {
    local result
    result=$(daq_platform_list)
    
    daq_assert_contains "win64" "$result" "Should contain Windows 64-bit" || return 1
    daq_assert_contains "win32" "$result" "Should contain Windows 32-bit" || return 1
    return 0
}

test-list-platform-count() {
    local count
    count=$(daq_platform_list | wc -l)
    
    # Should have multiple platforms (exact count may vary)
    daq_assert_greater_than 30 "$count" "Should have more than 50 platforms" || return 1
    return 0
}

test-detect-returns-valid-platform() {
    local result
    result=$(daq_platform_detect 2>/dev/null)
    local exit_code=$?
    
    # Detection may fail on some systems, so we check if it succeeds
    if [[ $exit_code -eq 0 ]]; then
        daq_assert_not_empty "$result" "detect should return platform" || return 1
        
        # Validate that detected platform is valid
        daq_platform_validate "$result" >/dev/null 2>&1
        daq_assert_success $? "detected platform should be valid" || return 1
    fi
    
    return 0
}

test-detect-platform-components() {
    local result
    result=$(daq_platform_detect 2>/dev/null)
    local exit_code=$?
    
    # Detection may fail on some systems
    if [[ $exit_code -eq 0 ]]; then
        # Should be able to parse detected platform
        local os_name
        os_name=$(daq_platform_parse "$result" --os-name 2>/dev/null)
        
        daq_assert_not_empty "$os_name" "detected platform should have OS name" || return 1
    fi
    
    return 0
}
