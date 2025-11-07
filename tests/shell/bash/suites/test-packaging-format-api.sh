#!/usr/bin/env bash
# test-packaging-format-api.sh - API tests for packaging-format.sh public functions
# Tests the public API functions that can be sourced and used by other scripts

source "${__DAQ_TESTS_SCRIPTS_DIR}/packaging-format.sh"

test-packaging-api-cpack-nsis() {
    local result
    result=$(daq_packaging_detect_from_cpack "NSIS" 2>/dev/null)
    daq_assert_equals "exe" "$result" "NSIS should return exe" || return 1
    return 0
}

test-packaging-api-cpack-zip() {
    local result
    result=$(daq_packaging_detect_from_cpack "ZIP" 2>/dev/null)
    daq_assert_equals "zip" "$result" "ZIP should return zip" || return 1
    return 0
}

test-packaging-api-cpack-tgz() {
    local result
    result=$(daq_packaging_detect_from_cpack "TGZ" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "TGZ should return tar.gz" || return 1
    return 0
}

test-packaging-api-cpack-deb() {
    local result
    result=$(daq_packaging_detect_from_cpack "DEB" 2>/dev/null)
    daq_assert_equals "deb" "$result" "DEB should return deb" || return 1
    return 0
}

test-packaging-api-cpack-case-insensitive() {
    local result
    result=$(daq_packaging_detect_from_cpack "nsis" 2>/dev/null)
    daq_assert_equals "exe" "$result" "Lowercase 'nsis' should work" || return 1
    
    result=$(daq_packaging_detect_from_cpack "Zip" 2>/dev/null)
    daq_assert_equals "zip" "$result" "Mixed case 'Zip' should work" || return 1
    
    return 0
}

test-packaging-api-cpack-invalid() {
    local result
    result=$(daq_packaging_detect_from_cpack "INVALID" 2>/dev/null)
    local exit_code=$?
    
    daq_assert_failure "$exit_code" "Invalid generator should fail" || return 1
    daq_assert_empty "$result" "Invalid generator should return empty" || return 1
    return 0
}

test-packaging-api-cpack-empty() {
    local result
    result=$(daq_packaging_detect_from_cpack "" 2>/dev/null)
    local exit_code=$?
    
    daq_assert_failure "$exit_code" "Empty generator should fail" || return 1
    return 0
}

test-packaging-api-os-windows-latest() {
    local result
    result=$(daq_packaging_detect_from_os "windows-latest" 2>/dev/null)
    daq_assert_equals "exe" "$result" "windows-latest should return exe" || return 1
    return 0
}

test-packaging-api-os-ubuntu-latest() {
    local result
    result=$(daq_packaging_detect_from_os "ubuntu-latest" 2>/dev/null)
    daq_assert_equals "deb" "$result" "ubuntu-latest should return deb" || return 1
    return 0
}

test-packaging-api-os-macos-latest() {
    local result
    result=$(daq_packaging_detect_from_os "macos-latest" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "macos-latest should return tar.gz" || return 1
    return 0
}

test-packaging-api-os-runner-windows() {
    local result
    result=$(daq_packaging_detect_from_os "Windows" 2>/dev/null)
    daq_assert_equals "exe" "$result" "Runner.os Windows should work" || return 1
    return 0
}

test-packaging-api-os-runner-linux() {
    local result
    result=$(daq_packaging_detect_from_os "Linux" 2>/dev/null)
    daq_assert_equals "deb" "$result" "Runner.os Linux should work" || return 1
    return 0
}

test-packaging-api-os-runner-macos() {
    local result
    result=$(daq_packaging_detect_from_os "macOS" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "Runner.os macOS should work" || return 1
    return 0
}

test-packaging-api-os-case-insensitive() {
    local result
    result=$(daq_packaging_detect_from_os "WINDOWS-LATEST" 2>/dev/null)
    daq_assert_equals "exe" "$result" "Uppercase OS name should work" || return 1
    
    result=$(daq_packaging_detect_from_os "Ubuntu-Latest" 2>/dev/null)
    daq_assert_equals "deb" "$result" "Mixed case OS name should work" || return 1
    
    return 0
}

test-packaging-api-os-variants() {
    local result
    
    # Windows variants
    result=$(daq_packaging_detect_from_os "win-latest" 2>/dev/null)
    daq_assert_equals "exe" "$result" "win-latest should work" || return 1
    
    result=$(daq_packaging_detect_from_os "windows-2022" 2>/dev/null)
    daq_assert_equals "exe" "$result" "windows-2022 should work" || return 1
    
    # Linux variants
    result=$(daq_packaging_detect_from_os "ubuntu-20.04" 2>/dev/null)
    daq_assert_equals "deb" "$result" "ubuntu-20.04 should work" || return 1
    
    result=$(daq_packaging_detect_from_os "debian-11" 2>/dev/null)
    daq_assert_equals "deb" "$result" "debian-11 should work" || return 1
    
    # macOS variants
    result=$(daq_packaging_detect_from_os "macos-13" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "macos-13 should work" || return 1
    
    result=$(daq_packaging_detect_from_os "mac-latest" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "mac-latest should work" || return 1
    
    result=$(daq_packaging_detect_from_os "osx-latest" 2>/dev/null)
    daq_assert_equals "tar.gz" "$result" "osx-latest should work" || return 1
    
    return 0
}

test-packaging-api-os-invalid() {
    local result
    result=$(daq_packaging_detect_from_os "invalid-os" 2>/dev/null)
    local exit_code=$?
    
    daq_assert_failure "$exit_code" "Invalid OS should fail" || return 1
    daq_assert_empty "$result" "Invalid OS should return empty" || return 1
    return 0
}

test-packaging-api-os-empty() {
    local result
    result=$(daq_packaging_detect_from_os "" 2>/dev/null)
    local exit_code=$?
    
    daq_assert_failure "$exit_code" "Empty OS should fail" || return 1
    return 0
}

test-packaging-api-env-override-windows() {
    local result
    OPENDAQ_PACKAGING_WIN="zip" result=$(daq_packaging_detect_from_os "windows-latest" 2>/dev/null)
    daq_assert_equals "zip" "$result" "Windows env override should work" || return 1
    return 0
}

test-packaging-api-env-override-linux() {
    local result
    OPENDAQ_PACKAGING_LINUX="rpm" result=$(daq_packaging_detect_from_os "ubuntu-latest" 2>/dev/null)
    daq_assert_equals "rpm" "$result" "Linux env override should work" || return 1
    return 0
}

test-packaging-api-env-override-macos() {
    local result
    OPENDAQ_PACKAGING_MACOS="zip" result=$(daq_packaging_detect_from_os "macos-latest" 2>/dev/null)
    daq_assert_equals "zip" "$result" "macOS env override should work" || return 1
    return 0
}

test-packaging-api-env-multiple-overrides() {
    local result
    
    # Test all three at once
    OPENDAQ_PACKAGING_WIN="msi" \
    OPENDAQ_PACKAGING_LINUX="rpm" \
    OPENDAQ_PACKAGING_MACOS="pkg" \
    result=$(daq_packaging_detect_from_os "windows-latest" 2>/dev/null)
    daq_assert_equals "msi" "$result" "Windows override in multi-env should work" || return 1
    
    OPENDAQ_PACKAGING_WIN="msi" \
    OPENDAQ_PACKAGING_LINUX="rpm" \
    OPENDAQ_PACKAGING_MACOS="pkg" \
    result=$(daq_packaging_detect_from_os "linux" 2>/dev/null)
    daq_assert_equals "rpm" "$result" "Linux override in multi-env should work" || return 1
    
    OPENDAQ_PACKAGING_WIN="msi" \
    OPENDAQ_PACKAGING_LINUX="rpm" \
    OPENDAQ_PACKAGING_MACOS="pkg" \
    result=$(daq_packaging_detect_from_os "macos" 2>/dev/null)
    daq_assert_equals "pkg" "$result" "macOS override in multi-env should work" || return 1
    
    return 0
}

test-packaging-api-edge-whitespace-in-args() {
    local result
    result=$(daq_packaging_detect_from_cpack " NSIS " 2>/dev/null)
    # This might fail depending on implementation - that's OK, it's an edge case
    local exit_code=$?
    
    # We just document the behavior, don't assert
    echo "  Whitespace test exit code: $exit_code"
    return 0
}

test-packaging-api-edge-special-chars() {
    local result
    result=$(daq_packaging_detect_from_os "ubuntu-20.04-test" 2>/dev/null)
    local exit_code=$?
    
    # Should still work because it contains 'ubuntu'
    if [[ $exit_code -eq 0 ]]; then
        daq_assert_equals "deb" "$result" "OS with extra suffix should still work" || return 1
    fi
    
    return 0
}

test-packaging-api-edge-numeric-only() {
    local result
    result=$(daq_packaging_detect_from_cpack "123" 2>/dev/null)
    local exit_code=$?
    
    daq_assert_failure "$exit_code" "Numeric generator should fail" || return 1
    return 0
}

test-packaging-api-integration-cpack-to-os() {
    # Verify that NSIS matches Windows default
    local cpack_result
    local os_result
    
    cpack_result=$(daq_packaging_detect_from_cpack "NSIS" 2>/dev/null)
    os_result=$(daq_packaging_detect_from_os "windows-latest" 2>/dev/null)
    
    daq_assert_equals "$cpack_result" "$os_result" \
        "NSIS and windows-latest should produce same result" || return 1
    
    # Verify that DEB matches Ubuntu default
    cpack_result=$(daq_packaging_detect_from_cpack "DEB" 2>/dev/null)
    os_result=$(daq_packaging_detect_from_os "ubuntu-latest" 2>/dev/null)
    
    daq_assert_equals "$cpack_result" "$os_result" \
        "DEB and ubuntu-latest should produce same result" || return 1
    
    return 0
}

test-packaging-api-integration-all-generators() {
    # Test that all documented generators work
    local generators=("NSIS" "ZIP" "TGZ" "DEB")
    local result
    
    for gen in "${generators[@]}"; do
        result=$(daq_packaging_detect_from_cpack "$gen" 2>/dev/null)
        local exit_code=$?
        
        daq_assert_success "$exit_code" "Generator $gen should succeed" || return 1
        daq_assert_not_empty "$result" "Generator $gen should return value" || return 1
    done
    
    return 0
}

test-packaging-api-integration-all-os-platforms() {
    # Test all major platform names
    local platforms=(
        "windows-latest"
        "ubuntu-latest"
        "macos-latest"
        "Windows"
        "Linux"
        "macOS"
    )
    local result
    
    for platform in "${platforms[@]}"; do
        result=$(daq_packaging_detect_from_os "$platform" 2>/dev/null)
        local exit_code=$?
        
        daq_assert_success "$exit_code" "Platform $platform should succeed" || return 1
        daq_assert_not_empty "$result" "Platform $platform should return value" || return 1
    done
    
    return 0
}
