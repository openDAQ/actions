#!/bin/bash

# test-opendaq-version-parse.sh - Enhanced test suite for opendaq-version-parse.sh
# This is a modular test suite that uses the enhanced test framework with hierarchical filtering

# This script is meant to be sourced by test-runner.sh
# The test framework should already be loaded

# Test suite sections - organized for better filtering
test_help_and_info() {
    test_section "Testing Help and Info"
    
    run_test_no_input "help short flag" 0 "" --help
    run_test_no_input "help long flag" 0 "" -h
    run_test_no_input "list formats" 0 "" --list-formats
    run_test_no_input_contains "list formats verbose" 0 "Supported version formats" --list-formats --verbose
    run_test_no_input "no arguments shows help" 1 ""
}

test_basic_parsing() {
    test_section "Testing Basic Version Parsing"
    
    # Basic release versions
    run_test "basic release version" 0 "3.14.2" "3.14.2"
    run_test "basic release with v prefix" 0 "3.14.2" "v3.14.2"
    
    # RC versions
    run_test "basic rc version" 0 "3.14.2" "3.14.2-rc"
    run_test "basic rc with v prefix" 0 "3.14.2" "v3.14.2-rc"
    
    # Dev versions
    run_test "basic dev version" 0 "3.14.2" "3.14.2-abc123f"
    run_test "basic dev with v prefix" 0 "3.14.2" "v3.14.2-abc123f"
    
    # RC-dev versions
    run_test "basic rc-dev version" 0 "3.14.2" "3.14.2-rc-abc123f"
    run_test "basic rc-dev with v prefix" 0 "3.14.2" "v3.14.2-rc-abc123f"
}

test_parameter_extraction() {
    test_section "Testing Parameter Extraction"
    
    # Single parameters - major
    run_test "extract major simple" 0 "3" "v3.14.2-rc-abc123f" --major
    run_test "extract major from release" 0 "3" "3.14.2" --major
    run_test "extract major large number" 0 "999" "999.14.2" --major
    
    # Single parameters - minor  
    run_test "extract minor simple" 0 "14" "v3.14.2-rc-abc123f" --minor
    run_test "extract minor from release" 0 "14" "3.14.2" --minor
    run_test "extract minor large number" 0 "999" "3.999.2" --minor
    
    # Single parameters - patch
    run_test "extract patch simple" 0 "2" "v3.14.2-rc-abc123f" --patch
    run_test "extract patch from release" 0 "2" "3.14.2" --patch
    run_test "extract patch large number" 0 "999" "3.14.999" --patch
    
    # Hash extraction
    run_test "extract hash from dev" 0 "abc123f" "v3.14.2-rc-abc123f" --hash
    run_test "extract hash from simple dev" 0 "abc123f" "3.14.2-abc123f" --hash
    run_test "extract empty hash from release" 0 "" "3.14.2" --hash
    run_test "extract empty hash from rc" 0 "" "3.14.2-rc" --hash
    
    # Type extraction
    run_test "extract type rc-dev" 0 "rc-dev" "v3.14.2-rc-abc123f" --type
    run_test "extract type release" 0 "release" "3.14.2" --type
    run_test "extract type rc" 0 "rc" "3.14.2-rc" --type
    run_test "extract type dev" 0 "dev" "3.14.2-abc123f" --type
    
    # Boolean parameters - is-rc
    run_test "check is-rc true for rc" 0 "true" "3.14.2-rc" --is-rc
    run_test "check is-rc true for rc-dev" 0 "true" "3.14.2-rc-abc123f" --is-rc
    run_test "check is-rc false for release" 0 "false" "3.14.2" --is-rc
    run_test "check is-rc false for dev" 0 "false" "3.14.2-abc123f" --is-rc
    
    # Boolean parameters - is-dev
    run_test "check is-dev true for dev" 0 "true" "3.14.2-abc123f" --is-dev
    run_test "check is-dev true for rc-dev" 0 "true" "3.14.2-rc-abc123f" --is-dev
    run_test "check is-dev false for release" 0 "false" "3.14.2" --is-dev
    run_test "check is-dev false for rc" 0 "false" "3.14.2-rc" --is-dev
    
    # Boolean parameters - is-release
    run_test "check is-release true for release" 0 "true" "3.14.2" --is-release
    run_test "check is-release false for rc" 0 "false" "3.14.2-rc" --is-release
    run_test "check is-release false for dev" 0 "false" "3.14.2-abc123f" --is-release
    run_test "check is-release false for rc-dev" 0 "false" "3.14.2-rc-abc123f" --is-release
    
    # Boolean parameters - is-rc-dev
    run_test "check is-rc-dev true for rc-dev" 0 "true" "3.14.2-rc-abc123f" --is-rc-dev
    run_test "check is-rc-dev false for rc" 0 "false" "3.14.2-rc" --is-rc-dev
    run_test "check is-rc-dev false for dev" 0 "false" "3.14.2-abc123f" --is-rc-dev
    run_test "check is-rc-dev false for release" 0 "false" "3.14.2" --is-rc-dev
    
    # Boolean parameters - has-v
    run_test "check has-v true for v prefix" 0 "true" "v3.14.2" --has-v
    run_test "check has-v true for v prefix rc-dev" 0 "true" "v3.14.2-rc-abc123f" --has-v
    run_test "check has-v false for no prefix" 0 "false" "3.14.2" --has-v
    run_test "check has-v false for no prefix rc-dev" 0 "false" "3.14.2-rc-abc123f" --has-v
}

test_multiple_parameters() {
    test_section "Testing Multiple Parameters"
    
    run_test_multiline "extract major and minor" 0 "v3.14.2" --major --minor
    run_test_multiline "extract all version parts" 0 "v3.14.2-rc-abc123f" --major --minor --patch --hash
    run_test_multiline "extract type and booleans" 0 "v3.14.2-rc-abc123f" --type --is-rc --is-dev --has-v
    run_test_multiline "extract complex combination" 0 "3.14.2-abc123f" --major --patch --type --is-dev --is-release
}

test_validation_basic() {
    test_section "Testing Basic Validation"
    
    # Valid versions
    run_test "validate release version" 0 "" "3.14.2" --validate
    run_test "validate rc version" 0 "" "3.14.2-rc" --validate
    run_test "validate dev version" 0 "" "3.14.2-abc123f" --validate
    run_test "validate rc-dev version" 0 "" "3.14.2-rc-abc123f" --validate
    run_test "validate with v prefix" 0 "" "v3.14.2" --validate
    run_test "validate v prefix rc-dev" 0 "" "v3.14.2-rc-abc123f" --validate
    
    # Invalid versions
    run_test "validation fails for incomplete version" 1 "" "3.14" --validate
    run_test "validation fails for invalid characters" 1 "" "3.14.2x" --validate
    run_test "validation fails for invalid rc format" 1 "" "3.14.2-rc-" --validate
    run_test "validation fails for empty version" 1 "" "" --validate
    run_test "validation fails for malformed version" 1 "" "v3.14.2.1" --validate
}

test_validation_verbose() {
    test_section "Testing Verbose Validation"
    
    # Verbose validation success
    run_test_contains "validate verbose success for release" 0 "Valid version" "3.14.2" --validate --verbose
    run_test_contains "validate verbose success for rc" 0 "Valid version" "3.14.2-rc" --validate --verbose
    run_test_contains "validate verbose success for dev" 0 "Valid version" "3.14.2-abc123f" --validate --verbose
    
    # Verbose validation failure
    run_test_contains "validate verbose failure incomplete" 1 "Invalid version" "3.14" --validate --verbose
    run_test_contains "validate verbose failure malformed" 1 "Invalid version" "3.14.2x" --validate --verbose
}

test_format_validation_basic() {
    test_section "Testing Format-Specific Validation"
    
    # Release format matches
    run_test "format X.YY.Z matches release" 0 "" "3.14.2" --validate --format "X.YY.Z"
    run_test "format vX.YY.Z matches v-release" 0 "" "v3.14.2" --validate --format "vX.YY.Z"
    
    # RC format matches
    run_test "format X.YY.Z-rc matches rc" 0 "" "3.14.2-rc" --validate --format "X.YY.Z-rc"
    run_test "format vX.YY.Z-rc matches v-rc" 0 "" "v3.14.2-rc" --validate --format "vX.YY.Z-rc"
    
    # Dev format matches
    run_test "format X.YY.Z-HASH matches dev" 0 "" "3.14.2-abc123f" --validate --format "X.YY.Z-HASH"
    run_test "format vX.YY.Z-HASH matches v-dev" 0 "" "v3.14.2-abc123f" --validate --format "vX.YY.Z-HASH"
    
    # RC-dev format matches
    run_test "format X.YY.Z-rc-HASH matches rc-dev" 0 "" "3.14.2-rc-abc123f" --validate --format "X.YY.Z-rc-HASH"
    run_test "format vX.YY.Z-rc-HASH matches v-rc-dev" 0 "" "v3.14.2-rc-abc123f" --validate --format "vX.YY.Z-rc-HASH"
}

test_format_validation_mismatches() {
    test_section "Testing Format Validation Mismatches"
    
    # Format mismatches
    run_test "format mismatch release vs rc" 1 "" "3.14.2-rc" --validate --format "X.YY.Z"
    run_test "format mismatch with v vs without v" 1 "" "v3.14.2" --validate --format "X.YY.Z"
    run_test "format mismatch without v vs with v" 1 "" "3.14.2" --validate --format "vX.YY.Z"
    run_test "format mismatch dev vs release" 1 "" "3.14.2-abc123f" --validate --format "X.YY.Z"
    run_test "format mismatch rc vs dev" 1 "" "3.14.2-rc" --validate --format "X.YY.Z-HASH"
    
    # Unknown format
    run_test "unknown format error" 1 "" "3.14.2" --validate --format "unknown"
    
    # Format validation with verbose
    run_test_contains "format match verbose success" 0 "matches format" "3.14.2" --validate --format "X.YY.Z" --verbose
    run_test_contains "format mismatch verbose failure" 1 "does not match format" "v3.14.2" --validate --format "X.YY.Z" --verbose
}

test_extraction_basic() {
    test_section "Testing Basic Version Extraction"
    
    # Extract from simple text
    run_test "extract from simple text" 0 "3.14.2" "Release 3.14.2 is ready" --extract
    run_test "extract with v prefix" 0 "v3.14.2" "Version v3.14.2 released" --extract
    run_test "extract rc version" 0 "3.14.2-rc" "Testing 3.14.2-rc build" --extract
    run_test "extract dev version" 0 "3.14.2-abc123f" "Build 3.14.2-abc123f completed" --extract
    run_test "extract rc-dev version" 0 "v3.14.2-rc-abc123f" "CI: Build v3.14.2-rc-abc123f passed all tests" --extract
}

test_extraction_advanced() {
    test_section "Testing Advanced Version Extraction"
    
    # Extract and validate
    run_test "extract and validate success" 0 "" "Release 3.14.2 ready" --extract --validate
    run_test "extract and validate with format" 0 "" "Release 3.14.2 ready" --extract --validate --format "X.YY.Z"
    
    # Extract failures
    run_test "extract from text without version" 1 "" "No version here" --extract
    run_test "extract and validate format mismatch" 1 "" "Release v3.14.2 ready" --extract --validate --format "X.YY.Z"
    
    # Extract with parameters
    run_test "extract and get major" 0 "3" "Release 3.14.2 ready" --extract --major
    run_test "extract and get type" 0 "rc-dev" "Build v3.14.2-rc-abc123f ready" --extract --type
    run_test "extract and get hash" 0 "abc123f" "Version 3.14.2-abc123f deployed" --extract --hash
}

test_verbose_output() {
    test_section "Testing Verbose Output"
    
    run_test_contains "verbose contains version info" 0 "Version: v3.14.2-rc-abc123f" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains major" 0 "Major: 3" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains minor" 0 "Minor: 14" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains patch" 0 "Patch: 2" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains hash" 0 "Hash: abc123f" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains type" 0 "Type: rc-dev" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains rc yes" 0 "RC: yes" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains dev yes" 0 "Dev: yes" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "verbose contains has v prefix yes" 0 "Has v prefix: yes" "v3.14.2-rc-abc123f" --verbose
    
    # Verbose with extraction
    run_test_contains "verbose extract success" 0 "Version: 3.14.2" "Release 3.14.2 ready" --extract --verbose
}

test_edge_cases() {
    test_section "Testing Edge Cases"
    
    # Large numbers
    run_test "large version numbers" 0 "999.999.999" "999.999.999"
    run_test "single digit versions" 0 "1.2.3" "1.2.3"
    
    # Long hashes
    run_test "long hash extraction" 0 "3" "3.14.2-abcdef123456789" --major
    run_test "short hash extraction" 0 "abc" "3.14.2-abc" --hash
    
    # Multiple versions in text (should get first)
    run_test "multiple versions in text" 0 "3.14.2" "Version 3.14.2 and 3.15.0 available" --extract
    
    # Version at different positions
    run_test "version at end of text" 0 "3.14.2" "Build completed: 3.14.2" --extract
    run_test "version at beginning" 0 "3.14.2" "3.14.2 release notes" --extract
    
    # Mixed with other numbers
    run_test "version mixed with other numbers" 0 "3.14.2" "Port 8080 version 3.14.2 on server 192.168.1.1" --extract
}

test_error_handling() {
    test_section "Testing Error Handling"
    
    # Missing arguments
    run_test "missing format argument" 1 "" "3.14.2" --format
    run_test "unknown parameter" 1 "" "3.14.2" --unknown
    run_test "unknown extraction parameter" 1 "" "3.14.2" --unknown-param
    
    # Invalid format combinations
    run_test_no_input "missing input for validation" 1 "" --validate
    run_test_no_input "missing input for extraction" 1 "" --extract
    run_test_no_input "missing input for parameters" 1 "" --major
}

test_performance() {
    test_section "Testing Performance and Stress"
    
    # Large text extraction
    local large_text="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Version 3.14.2 is embedded. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    run_test "extract from large text" 0 "3.14.2" "$large_text" --extract
    
    # Multiple rapid calls
    run_test "rapid validation 1" 0 "" "3.14.2" --validate
    run_test "rapid validation 2" 0 "" "v3.14.2-rc" --validate
    run_test "rapid validation 3" 0 "" "3.14.2-abc123f" --validate
}

# Test functions that might be flaky or slow (useful for exclusion testing)
test_slow_operations() {
    test_section "Testing Slow Operations"
    
    # These tests can be excluded with --exclude-test "slow-*"
    run_test "slow-comprehensive-validation" 0 "" "3.14.2" --validate --verbose
    run_test_contains "slow-complex-extraction" 0 "Version: 3.14.2" "Very long text with version 3.14.2 embedded" --extract --verbose
}

test_flaky_edge_cases() {
    test_section "Testing Potentially Flaky Cases"
    
    # These tests might be flaky and can be excluded
    run_test "flaky-timing-test" 0 "3" "3.14.2" --major
    run_test "flaky-memory-test" 0 "3.14.2" "3.14.2" 
}

# Main test execution function
run_opendaq_version_parse_tests() {
    test_help_and_info
    test_basic_parsing
    test_parameter_extraction
    test_multiple_parameters
    test_validation_basic
    test_validation_verbose
    test_format_validation_basic
    test_format_validation_mismatches
    test_extraction_basic
    test_extraction_advanced
    test_verbose_output
    test_edge_cases
    test_error_handling
    test_performance
    test_slow_operations
    test_flaky_edge_cases
}

# Execute tests if this script is run directly
if [ "${0##*/}" = "test-opendaq-version-parse.sh" ]; then
    echo "This test suite should be run via test-runner.sh"
    echo "Usage: test-runner.sh opendaq-version-parse"
    exit 1
fi

# Run tests when sourced by test runner
run_opendaq_version_parse_tests
