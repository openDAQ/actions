#!/usr/bin/env bash
# test-version-format-api.sh - API tests for version-format.sh public functions
#
# Tests all public API functions (daq_version_*):
# - daq_version_compose
# - daq_version_parse
# - daq_version_validate
# - daq_version_extract

# Source the script under test
source "${__DAQ_TESTS_SCRIPTS_DIR}/version-format.sh"

test-compose-basic-release() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Basic release version mismatch" || return 1
    return 0
}

test-compose-release-without-prefix() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --exclude-prefix)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3" "$result" "Release without prefix mismatch" || return 1
    return 0
}

test-compose-rc-with-prefix() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3-rc" "$result" "RC with prefix mismatch" || return 1
    return 0
}

test-compose-rc-without-prefix() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc --exclude-prefix)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3-rc" "$result" "RC without prefix mismatch" || return 1
    return 0
}

test-compose-hash-with-prefix() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --hash a1b2c3d)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3-a1b2c3d" "$result" "Hash with prefix mismatch" || return 1
    return 0
}

test-compose-hash-without-prefix() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --hash a1b2c3d --exclude-prefix)
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3-a1b2c3d" "$result" "Hash without prefix mismatch" || return 1
    return 0
}

test-compose-with-format-release() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --format "vX.YY.Z")
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Format release mismatch" || return 1
    return 0
}

test-compose-with-format-rc() {
    local result
    result=$(daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc --format "X.YY.Z-rc")
    local exit_code=$?
    
    daq_assert_success $exit_code "compose should succeed" || return 1
    daq_assert_equals "1.2.3-rc" "$result" "Format RC mismatch" || return 1
    return 0
}

test-compose-missing-major() {
    local result
    result=$(daq_version_compose --minor 2 --patch 3 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "compose should fail with missing major" || return 1
    return 0
}

test-parse-basic-release() {
    local result
    result=$(daq_version_parse "v1.2.3")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1 2 3   v" "$result" "Parsed components mismatch" || return 1
    return 0
}

test-parse-release-without-prefix() {
    local result
    result=$(daq_version_parse "1.2.3")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1 2 3   " "$result" "Parsed components without prefix mismatch" || return 1
    return 0
}

test-parse-rc-version() {
    local result
    result=$(daq_version_parse "v1.2.3-rc")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1 2 3 rc  v" "$result" "Parsed RC components mismatch" || return 1
    return 0
}

test-parse-hash-version() {
    local result
    result=$(daq_version_parse "v1.2.3-a1b2c3d")
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1 2 3  a1b2c3d v" "$result" "Parsed hash components mismatch" || return 1
    return 0
}

test-parse-extract-major() {
    local result
    result=$(daq_version_parse "v1.2.3" --major)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "1" "$result" "Major version mismatch" || return 1
    return 0
}

test-parse-extract-minor() {
    local result
    result=$(daq_version_parse "v1.2.3" --minor)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "2" "$result" "Minor version mismatch" || return 1
    return 0
}

test-parse-extract-patch() {
    local result
    result=$(daq_version_parse "v1.2.3" --patch)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "3" "$result" "Patch version mismatch" || return 1
    return 0
}

test-parse-extract-suffix() {
    local result
    result=$(daq_version_parse "v1.2.3-rc" --suffix)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "rc" "$result" "Suffix mismatch" || return 1
    return 0
}

test-parse-extract-hash() {
    local result
    result=$(daq_version_parse "v1.2.3-a1b2c3d" --hash)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "a1b2c3d" "$result" "Hash mismatch" || return 1
    return 0
}

test-parse-extract-prefix() {
    local result
    result=$(daq_version_parse "v1.2.3" --prefix)
    local exit_code=$?
    
    daq_assert_success $exit_code "parse should succeed" || return 1
    daq_assert_equals "v" "$result" "Prefix mismatch" || return 1
    return 0
}

test-parse-invalid-version() {
    local result
    result=$(daq_version_parse "invalid-version" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "parse should fail with invalid version" || return 1
    return 0
}

test-validate-basic-release() {
    daq_version_validate "v1.2.3" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for basic release" || return 1
    return 0
}

test-validate-release-without-prefix() {
    daq_version_validate "1.2.3" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for release without prefix" || return 1
    return 0
}

test-validate-rc() {
    daq_version_validate "v1.2.3-rc" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for RC" || return 1
    return 0
}

test-validate-hash() {
    daq_version_validate "v1.2.3-a1b2c3d" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for hash version" || return 1
    return 0
}

test-validate-with-format-match() {
    daq_version_validate "v1.2.3" --format "vX.YY.Z" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for matching format" || return 1
    return 0
}

test-validate-with-format-mismatch() {
    daq_version_validate "v1.2.3" --format "X.YY.Z" >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for mismatching format" || return 1
    return 0
}

test-validate-is-release-true() {
    daq_version_validate "v1.2.3" --is-release >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for release check" || return 1
    return 0
}

test-validate-is-release-false() {
    daq_version_validate "v1.2.3-rc" --is-release >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for non-release" || return 1
    return 0
}

test-validate-is-rc-true() {
    daq_version_validate "v1.2.3-rc" --is-rc >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for RC check" || return 1
    return 0
}

test-validate-is-rc-false() {
    daq_version_validate "v1.2.3" --is-rc >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for non-RC" || return 1
    return 0
}

test-validate-is-dev-true() {
    daq_version_validate "v1.2.3-a1b2c3d" --is-dev >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_success $exit_code "validate should succeed for dev check" || return 1
    return 0
}

test-validate-is-dev-false() {
    daq_version_validate "v1.2.3" --is-dev >/dev/null 2>&1
    local exit_code=$?
    
    daq_assert_failure $exit_code "validate should fail for non-dev" || return 1
    return 0
}

test-extract-from-filename() {
    local result
    result=$(daq_version_extract "opendaq-v1.2.3-ubuntu20.04-x86_64.deb")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3" "$result" "Extracted version mismatch" || return 1
    return 0
}

test-extract-without-prefix() {
    local result
    result=$(daq_version_extract "package-1.2.3.zip")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "1.2.3" "$result" "Extracted version without prefix mismatch" || return 1
    return 0
}

test-extract-rc-version() {
    local result
    result=$(daq_version_extract "build-v1.2.3-rc-artifact.tar")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3-rc" "$result" "Extracted RC version mismatch" || return 1
    return 0
}

test-extract-hash-version() {
    local result
    result=$(daq_version_extract "commit-v1.2.3-a1b2c3d.log")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.2.3-a1b2c3d" "$result" "Extracted hash version mismatch" || return 1
    return 0
}

test-extract-multiple-versions() {
    local result
    result=$(daq_version_extract "v1.0.0-to-v2.0.0-migration")
    local exit_code=$?
    
    daq_assert_success $exit_code "extract should succeed" || return 1
    daq_assert_equals "v1.0.0" "$result" "Should extract first version" || return 1
    return 0
}

test-extract-no-version() {
    local result
    result=$(daq_version_extract "no-version-here.txt" 2>&1)
    local exit_code=$?
    
    daq_assert_failure $exit_code "extract should fail when no version found" || return 1
    return 0
}
