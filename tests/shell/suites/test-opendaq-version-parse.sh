#!/bin/bash

# test-opendaq-version-parse.sh - Test suite for opendaq-version-parse.sh
# This is a modular test suite that uses the test framework

# This script is meant to be sourced by test-runner.sh
# The test framework should already be loaded

# Test suite sections
test_help_and_info() {
    test_section "Testing Help and Info"
    
    run_test_no_input "Help short flag" 0 "" --help
    run_test_no_input "Help long flag" 0 "" -h
    run_test_no_input "List formats" 0 "" --list-formats
    run_test_no_input_contains "List formats verbose" 0 "Supported version formats" --list-formats --verbose
    run_test_no_input "No arguments shows help" 1 ""
}

test_basic_parsing() {
    test_section "Testing Basic Version Parsing"
    
    # Basic release versions
    run_test "Parse release version" 0 "3.14.2" "3.14.2"
    run_test "Parse release with v prefix" 0 "3.14.2" "v3.14.2"
    
    # RC versions
    run_test "Parse RC version" 0 "3.14.2" "3.14.2-rc"
    run_test "Parse RC with v prefix" 0 "3.14.2" "v3.14.2-rc"
    
    # Dev versions
    run_test "Parse dev version" 0 "3.14.2" "3.14.2-abc123f"
    run_test "Parse dev with v prefix" 0 "3.14.2" "v3.14.2-abc123f"
    
    # RC-dev versions
    run_test "Parse RC-dev version" 0 "3.14.2" "3.14.2-rc-abc123f"
    run_test "Parse RC-dev with v prefix" 0 "3.14.2" "v3.14.2-rc-abc123f"
}

test_parameter_extraction() {
    test_section "Testing Parameter Extraction"
    
    # Single parameters
    run_test "Extract major" 0 "3" "v3.14.2-rc-abc123f" --major
    run_test "Extract minor" 0 "14" "v3.14.2-rc-abc123f" --minor
    run_test "Extract patch" 0 "2" "v3.14.2-rc-abc123f" --patch
    run_test "Extract hash" 0 "abc123f" "v3.14.2-rc-abc123f" --hash
    run_test "Extract type rc-dev" 0 "rc-dev" "v3.14.2-rc-abc123f" --type
    run_test "Extract type release" 0 "release" "3.14.2" --type
    run_test "Extract type rc" 0 "rc" "3.14.2-rc" --type
    run_test "Extract type dev" 0 "dev" "3.14.2-abc123f" --type
    
    # Boolean parameters
    run_test "Check is-rc true" 0 "true" "3.14.2-rc" --is-rc
    run_test "Check is-rc false" 0 "false" "3.14.2" --is-rc
    run_test "Check is-dev true" 0 "true" "3.14.2-abc123f" --is-dev
    run_test "Check is-dev false" 0 "false" "3.14.2" --is-dev
    run_test "Check is-release true" 0 "true" "3.14.2" --is-release
    run_test "Check is-release false" 0 "false" "3.14.2-rc" --is-release
    run_test "Check is-rc-dev true" 0 "true" "3.14.2-rc-abc123f" --is-rc-dev
    run_test "Check is-rc-dev false" 0 "false" "3.14.2-rc" --is-rc-dev
    run_test "Check has-v true" 0 "true" "v3.14.2" --has-v
    run_test "Check has-v false" 0 "false" "3.14.2" --has-v
    
    # Empty hash
    run_test "Extract empty hash" 0 "" "3.14.2" --hash
}

test_multiple_parameters() {
    test_section "Testing Multiple Parameters"
    
    run_test_multiline "Extract major and minor" 0 "v3.14.2" --major --minor
    run_test_multiline "Extract all version parts" 0 "v3.14.2-rc-abc123f" --major --minor --patch --hash
    run_test_multiline "Extract type and booleans" 0 "v3.14.2-rc-abc123f" --type --is-rc --is-dev --has-v
}

test_validation() {
    test_section "Testing Validation"
    
    # Valid versions
    run_test "Validate release" 0 "" "3.14.2" --validate
    run_test "Validate RC" 0 "" "3.14.2-rc" --validate
    run_test "Validate dev" 0 "" "3.14.2-abc123f" --validate
    run_test "Validate RC-dev" 0 "" "3.14.2-rc-abc123f" --validate
    run_test "Validate with v prefix" 0 "" "v3.14.2" --validate
    
    # Invalid versions
    run_test "Invalid version format" 1 "" "3.14" --validate
    run_test "Invalid version characters" 1 "" "3.14.2x" --validate
    run_test "Invalid RC format" 1 "" "3.14.2-rc-" --validate
    run_test "Empty version" 1 "" "" --validate
    
    # Verbose validation
    run_test_contains "Validate verbose success" 0 "Valid version" "3.14.2" --validate --verbose
    run_test_contains "Validate verbose failure" 1 "Invalid version" "3.14" --validate --verbose
}

test_format_validation() {
    test_section "Testing Format-Specific Validation"
    
    # Correct format matches
    run_test "Format X.YY.Z match" 0 "" "3.14.2" --validate --format "X.YY.Z"
    run_test "Format vX.YY.Z match" 0 "" "v3.14.2" --validate --format "vX.YY.Z"
    run_test "Format X.YY.Z-rc match" 0 "" "3.14.2-rc" --validate --format "X.YY.Z-rc"
    run_test "Format vX.YY.Z-rc match" 0 "" "v3.14.2-rc" --validate --format "vX.YY.Z-rc"
    run_test "Format X.YY.Z-HASH match" 0 "" "3.14.2-abc123f" --validate --format "X.YY.Z-HASH"
    run_test "Format vX.YY.Z-HASH match" 0 "" "v3.14.2-abc123f" --validate --format "vX.YY.Z-HASH"
    run_test "Format X.YY.Z-rc-HASH match" 0 "" "3.14.2-rc-abc123f" --validate --format "X.YY.Z-rc-HASH"
    run_test "Format vX.YY.Z-rc-HASH match" 0 "" "v3.14.2-rc-abc123f" --validate --format "vX.YY.Z-rc-HASH"
    
    # Format mismatches
    run_test "Format mismatch: release vs rc" 1 "" "3.14.2-rc" --validate --format "X.YY.Z"
    run_test "Format mismatch: with v vs without v" 1 "" "v3.14.2" --validate --format "X.YY.Z"
    run_test "Format mismatch: without v vs with v" 1 "" "3.14.2" --validate --format "vX.YY.Z"
    run_test "Format mismatch: dev vs release" 1 "" "3.14.2-abc123f" --validate --format "X.YY.Z"
    
    # Unknown format
    run_test "Unknown format" 1 "" "3.14.2" --validate --format "unknown"
    
    # Format validation with verbose
    run_test_contains "Format match verbose" 0 "matches format" "3.14.2" --validate --format "X.YY.Z" --verbose
    run_test_contains "Format mismatch verbose" 1 "does not match format" "v3.14.2" --validate --format "X.YY.Z" --verbose
}

test_extraction() {
    test_section "Testing Version Extraction"
    
    # Extract from text
    run_test "Extract from simple text" 0 "3.14.2" "Release 3.14.2 is ready" --extract
    run_test "Extract with v prefix" 0 "v3.14.2" "Version v3.14.2 released" --extract
    run_test "Extract RC version" 0 "3.14.2-rc" "Testing 3.14.2-rc build" --extract
    run_test "Extract dev version" 0 "3.14.2-abc123f" "Build 3.14.2-abc123f completed" --extract
    run_test "Extract from complex text" 0 "v3.14.2-rc-abc123f" "CI: Build v3.14.2-rc-abc123f passed all tests" --extract
    
    # Extract and validate
    run_test "Extract and validate success" 0 "" "Release 3.14.2 ready" --extract --validate
    run_test "Extract and validate with format" 0 "" "Release 3.14.2 ready" --extract --validate --format "X.YY.Z"
    
    # Extract failures
    run_test "Extract from text without version" 1 "" "No version here" --extract
    run_test "Extract and validate mismatch" 1 "" "Release v3.14.2 ready" --extract --validate --format "X.YY.Z"
    
    # Extract with parameters
    run_test "Extract and get major" 0 "3" "Release 3.14.2 ready" --extract --major
    run_test "Extract and get type" 0 "rc-dev" "Build v3.14.2-rc-abc123f ready" --extract --type
}

test_verbose_output() {
    test_section "Testing Verbose Output"
    
    run_test_contains "Verbose contains version info" 0 "Version: v3.14.2-rc-abc123f" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains major" 0 "Major: 3" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains minor" 0 "Minor: 14" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains patch" 0 "Patch: 2" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains hash" 0 "Hash: abc123f" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains type" 0 "Type: rc-dev" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains RC yes" 0 "RC: yes" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains Dev yes" 0 "Dev: yes" "v3.14.2-rc-abc123f" --verbose
    run_test_contains "Verbose contains has v prefix yes" 0 "Has v prefix: yes" "v3.14.2-rc-abc123f" --verbose
    
    # Verbose with extraction
    run_test_contains "Verbose extract" 0 "Version: 3.14.2" "Release 3.14.2 ready" --extract --verbose
}

test_edge_cases() {
    test_section "Testing Edge Cases"
    
    # Large numbers
    run_test "Large version numbers" 0 "999.999.999" "999.999.999"
    run_test "Single digit versions" 0 "1.2.3" "1.2.3"
    
    # Long hashes
    run_test "Long hash" 0 "3" "3.14.2-abcdef123456789" --major
    run_test "Short hash" 0 "abc" "3.14.2-abc" --hash
    
    # Multiple versions in text (should get first)
    run_test "Multiple versions in text" 0 "3.14.2" "Version 3.14.2 and 3.15.0 available" --extract
    
    # Version at different positions
    run_test "Version at end of text" 0 "3.14.2" "Build completed: 3.14.2" --extract
    run_test "Version at beginning" 0 "3.14.2" "3.14.2 release notes" --extract
    
    # Mixed with other numbers
    run_test "Version mixed with other numbers" 0 "3.14.2" "Port 8080 version 3.14.2 on server 192.168.1.1" --extract
}

test_error_handling() {
    test_section "Testing Error Handling"
    
    # Missing arguments
    run_test "Missing format argument" 1 "" "3.14.2" --format
    run_test "Unknown parameter" 1 "" "3.14.2" --unknown
    run_test "Unknown extraction parameter" 1 "" "3.14.2" --unknown-param
    
    # Invalid format combinations
    run_test_no_input "Missing input for validation" 1 "" --validate
    run_test_no_input "Missing input for extraction" 1 "" --extract
    run_test_no_input "Missing input for parameters" 1 "" --major
}

test_performance() {
    test_section "Testing Performance and Stress"
    
    # Large text extraction
    local large_text="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Version 3.14.2 is embedded. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    run_test "Extract from large text" 0 "3.14.2" "$large_text" --extract
    
    # Multiple rapid calls
    run_test "Rapid validation 1" 0 "" "3.14.2" --validate
    run_test "Rapid validation 2" 0 "" "v3.14.2-rc" --validate
    run_test "Rapid validation 3" 0 "" "3.14.2-abc123f" --validate
}

# Main test execution function
run_opendaq_version_parse_tests() {
    test_help_and_info
    test_basic_parsing
    test_parameter_extraction
    test_multiple_parameters
    test_validation
    test_format_validation
    test_extraction
    test_verbose_output
    test_edge_cases
    test_error_handling
    test_performance
}

# Execute tests if this script is run directly
if [ "${0##*/}" = "test-opendaq-version-parse.sh" ]; then
    echo "This test suite should be run via test-runner.sh"
    echo "Usage: test-runner.sh opendaq-version-parse"
    exit 1
fi

# Run tests when sourced by test runner
run_opendaq_version_parse_tests
