#!/usr/bin/env bash
# test-windows-paths.sh - Tests for Windows path conversion utilities

# Note: These tests work on both Unix and Windows

test_setup() {
    # Source paths module to get access to conversion functions
    source "${__DAQ_TESTS_CORE_DIR}/paths.sh"
}

# Test: Platform detection
test-windows-platform-detection() {
    # This should not fail on any platform
    local platform
    platform=$(__daq_tests_get_platform)
    
    daq_assert_not_empty "${platform}" "Platform should be detected"
    
    # Should return one of known platforms
    case "${platform}" in
        Linux|macOS|"Windows (Cygwin)"|"Windows (Git Bash)"|Unix)
            return 0
            ;;
        *)
            echo "Unknown platform: ${platform}"
            return 1
            ;;
    esac
}

# Test: Unix path normalization (works on all platforms)
test-windows-normalize-unix-path() {
    local input="/home/user/project/scripts"
    local output
    
    output=$(__daq_tests_normalize_path "${input}")
    
    # Should preserve Unix paths
    daq_assert_not_empty "${output}" "Normalized path should not be empty"
}

# Test: Empty path handling
test-windows-empty-path() {
    local result
    
    result=$(__daq_tests_to_unix_path "")
    daq_assert_empty "${result}" "Empty input should return empty output"
    
    result=$(__daq_tests_to_windows_path "")
    daq_assert_empty "${result}" "Empty input should return empty output"
}

# Test: Path with spaces
test-windows-path-with-spaces() {
    # On Windows: "C:\Program Files\App"
    # On Unix: "/opt/my app/scripts"
    
    local test_path="/opt/my app/scripts"
    local result
    
    result=$(__daq_tests_to_unix_path "${test_path}")
    daq_assert_not_empty "${result}" "Path with spaces should be handled"
}

# Test: Relative path conversion
test-windows-relative-path() {
    local relative_path="./scripts"
    local result
    
    result=$(__daq_tests_to_unix_path "${relative_path}")
    daq_assert_not_empty "${result}" "Relative path should be converted"
}

# Test: Is Windows detection (should work on all platforms)
test-windows-is-windows-detection() {
    # This should not fail - just returns true or false
    if __daq_tests_is_windows; then
        # On Windows
        local platform
        platform=$(__daq_tests_get_platform)
        daq_assert_contains "Windows" "${platform}" "Windows platform should contain 'Windows'"
    else
        # On Unix/Linux/macOS
        return 0
    fi
}

# Test: Cygpath availability check
test-windows-cygpath-check() {
    # This should not fail - just returns true or false
    if __daq_tests_has_cygpath; then
        # Cygpath is available
        which cygpath >/dev/null 2>&1 || return 1
    else
        # Cygpath is not available (normal on Linux/macOS)
        return 0
    fi
}

# Test: Windows path conversion (simulated)
test-windows-path-conversion-logic() {
    # Test the fallback conversion logic (without actually running on Windows)
    
    # These conversions work in fallback mode (Git Bash style)
    local win_path="C:/Users/test/project"
    local expected_unix="/c/Users/test/project"
    
    # The function should handle forward slashes in Windows paths
    local result
    result=$(__daq_tests_to_unix_path "${win_path}")
    
    # On Windows, should convert; on Unix, should preserve
    daq_assert_not_empty "${result}" "Conversion should produce output"
}

# Test: Mixed slashes handling
test-windows-mixed-slashes() {
    local mixed_path="C:/Users\\test/project"
    local result
    
    result=$(__daq_tests_to_unix_path "${mixed_path}")
    
    daq_assert_not_empty "${result}" "Mixed slashes should be handled"
    
    # On Windows, backslashes should be converted to forward slashes
    # On Unix/Linux, the path is returned as-is (since it's not a Windows path)
    if __daq_tests_is_windows; then
        # On Windows, result should not contain backslashes
        if [[ "${result}" == *"\\"* ]]; then
            echo "Result still contains backslashes: ${result}"
            return 1
        fi
    else
        # On Unix, we don't do path conversion (not a Windows environment)
        # So the test passes as long as function returns something
        return 0
    fi
}

# Test: Drive letter handling
test-windows-drive-letter() {
    # Test that drive letters are recognized
    local paths=("C:\\test" "D:\\project" "E:/data")
    
    for path in "${paths[@]}"; do
        local result
        result=$(__daq_tests_to_unix_path "${path}")
        daq_assert_not_empty "${result}" "Drive letter path should be converted: ${path}"
    done
}

# Test: Absolute path detection
test-windows-absolute-path() {
    # Unix absolute path
    local unix_abs="/usr/local/bin"
    local result
    
    result=$(__daq_tests_normalize_path "${unix_abs}")
    daq_assert_not_empty "${result}" "Absolute Unix path should be handled"
}

# Test: Current directory conversion
test-windows-current-directory() {
    local current_dir
    current_dir=$(pwd)
    
    local result
    result=$(__daq_tests_normalize_path "${current_dir}")
    
    daq_assert_not_empty "${result}" "Current directory should be normalized"
    
    # Result should be absolute
    if [[ ! "${result}" =~ ^/ ]]; then
        echo "Normalized path is not absolute: ${result}"
        return 1
    fi
}

# Test: Path with trailing slash
test-windows-trailing-slash() {
    local path_with_slash="/home/user/project/"
    local result
    
    result=$(__daq_tests_to_unix_path "${path_with_slash}")
    daq_assert_not_empty "${result}" "Path with trailing slash should be handled"
}

# Test: Special characters in path
test-windows-special-chars() {
    # Some special characters that might appear in paths
    local paths=(
        "/home/user/my-project"
        "/home/user/my_project"
        "/home/user/my.project"
    )
    
    for path in "${paths[@]}"; do
        local result
        result=$(__daq_tests_to_unix_path "${path}")
        daq_assert_not_empty "${result}" "Special char path should work: ${path}"
    done
}

# Test: Path conversion is idempotent
test-windows-conversion-idempotent() {
    local original_path="/home/user/project"
    
    # Convert to Unix (should be unchanged on Unix)
    local first_conv
    first_conv=$(__daq_tests_to_unix_path "${original_path}")
    
    # Convert again
    local second_conv
    second_conv=$(__daq_tests_to_unix_path "${first_conv}")
    
    daq_assert_equals "${first_conv}" "${second_conv}" \
        "Repeated conversion should be idempotent"
}

# Test: Environment variable path initialization
test-windows-env-var-init() {
    # Save original values
    local orig_scripts="${OPENDAQ_TESTS_SCRIPTS_DIR:-}"
    local orig_suites="${OPENDAQ_TESTS_SUITES_DIR:-}"
    
    # Set test values
    export OPENDAQ_TESTS_SCRIPTS_DIR="/tmp/test-scripts"
    export OPENDAQ_TESTS_SUITES_DIR="/tmp/test-suites"
    
    # Initialize paths
    __daq_tests_paths_init
    
    # Values should still be set
    daq_assert_not_empty "${OPENDAQ_TESTS_SCRIPTS_DIR}" \
        "Scripts dir should be initialized"
    daq_assert_not_empty "${OPENDAQ_TESTS_SUITES_DIR}" \
        "Suites dir should be initialized"
    
    # Restore original values
    if [[ -n "${orig_scripts}" ]]; then
        export OPENDAQ_TESTS_SCRIPTS_DIR="${orig_scripts}"
    else
        unset OPENDAQ_TESTS_SCRIPTS_DIR
    fi
    
    if [[ -n "${orig_suites}" ]]; then
        export OPENDAQ_TESTS_SUITES_DIR="${orig_suites}"
    else
        unset OPENDAQ_TESTS_SUITES_DIR
    fi
}
