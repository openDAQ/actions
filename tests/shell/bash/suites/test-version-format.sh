#!/bin/bash
################################################################################
# Test Suite: version-format
# Version: 2.0.0
# Description: Comprehensive test suite for version-format.sh script
#
# This suite tests all functionality of version-format.sh including:
# - Query commands (list formats, types, defaults)
# - Detection (type and format detection)
# - Validation (basic and format-specific)
# - Parsing (component extraction)
# - Composition (building versions from components)
# - Extraction (finding versions in text)
# - Edge cases and error handling
#
# Usage:
#   This script is sourced by test-runner.sh
#   test-runner.sh version-format
#
# BREAKING CHANGES in v2.0:
#   - Removed test_name parameter from all assertions
#   - Tests are now auto-discovered (test_* functions)
#   - Removed explicit function calls at end of file
#   - Filtering by function name, not string descriptions
################################################################################

################################################################################
# SUITE SETUP/TEARDOWN (optional)
################################################################################

# Suite setup - called once before all tests
test_suite_setup() {
    # Add any suite-level setup here if needed
    return 0
}

# Suite teardown - called once after all tests
test_suite_teardown() {
    # Add any suite-level cleanup here if needed
    return 0
}

################################################################################
# TEST-LEVEL SETUP/TEARDOWN (optional)
################################################################################

# Test setup - called before each test (optional)
# test_setup() {
#     return 0
# }

# Test teardown - called after each test (optional)
# test_teardown() {
#     return 0
# }

################################################################################
# TESTS: Basic Info and Query Commands
################################################################################

test_version_output() {
    daq_testing_assert_no_input_contains 0 "version-format v" --version
}

test_help_short() {
    daq_testing_assert_no_input_contains 0 "USAGE:" ""
}

test_help_full() {
    daq_testing_assert_no_input_contains 0 "DESCRIPTION:" --help
}

test_list_formats() {
    daq_testing_assert_no_input_contains 0 "vX.YY.Z" --list-formats
}

test_list_formats_verbose() {
    daq_testing_assert_no_input_contains 0 "prefix=" --list-formats --verbose
}

test_list_formats_prefix_only() {
    daq_testing_assert_no_input_contains 0 "vX.YY.Z" --list-formats --prefix-only
}

test_list_types() {
    daq_testing_assert_no_input_contains 0 "release" --list-types
}

test_list_types_verbose() {
    daq_testing_assert_no_input_contains 0 "Release version" --list-types --verbose
}

test_default_format() {
    daq_testing_assert_no_input 0 --default-format
}

test_default_prefix() {
    daq_testing_assert_no_input 0 --default-prefix
}

test_default_suffix() {
    daq_testing_assert_no_input 0 --default-suffix
}

################################################################################
# TESTS: Type Detection
################################################################################

test_detect_type_release() {
    daq_testing_assert_equals 0 "v3.14.2" --detect-type
}

test_detect_type_rc() {
    daq_testing_assert_equals 0 "v3.14.2-rc" --detect-type
}

test_detect_type_dev() {
    daq_testing_assert_equals 0 "v3.14.2-abc123f" --detect-type
}

test_detect_type_rc_dev() {
    daq_testing_assert_equals 0 "v3.14.2-rc-abc123f" --detect-type
}

test_detect_type_custom() {
    daq_testing_assert_equals 0 "v3.14.2-beta" --detect-type
}

test_detect_type_custom_dev() {
    daq_testing_assert_equals 0 "v3.14.2-beta-abc123f" --detect-type
}

################################################################################
# TESTS: Format Detection
################################################################################

test_detect_format_vX_YY_Z() {
    daq_testing_assert_equals 0 "v3.14.2" --detect-format
}

test_detect_format_vX_YY_Z_rc() {
    daq_testing_assert_equals 0 "v3.14.2-rc" --detect-format
}

test_detect_format_vX_YY_Z_HASH() {
    daq_testing_assert_equals 0 "v3.14.2-abc123f" --detect-format
}

test_detect_format_X_YY_Z() {
    daq_testing_assert_equals 0 "3.14.2" --detect-format
}

test_detect_format_X_YY_Z_rc_HASH() {
    daq_testing_assert_equals 0 "3.14.2-rc-abc123f" --detect-format
}

################################################################################
# TESTS: Basic Validation
################################################################################

test_validate_release() {
    daq_testing_assert_exit_code 0 "v3.14.2" validate
}

test_validate_rc() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc" validate
}

test_validate_dev() {
    daq_testing_assert_exit_code 0 "v3.14.2-abc123f" validate
}

test_validate_rc_dev() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc-abc123f" validate
}

test_validate_without_prefix() {
    daq_testing_assert_exit_code 0 "3.14.2" validate
}

test_validate_fails_incomplete() {
    daq_testing_assert_exit_code 1 "3.14" validate
}

test_validate_fails_invalid_chars() {
    daq_testing_assert_exit_code 1 "3.14.2x" validate
}

test_validate_fails_empty() {
    daq_testing_assert_exit_code 1 "" validate
}

################################################################################
# TESTS: Validation Checks
################################################################################

test_check_is_release_true() {
    daq_testing_assert_exit_code 0 "v3.14.2" validate --is-release
}

test_check_is_release_false_for_rc() {
    daq_testing_assert_exit_code 1 "v3.14.2-rc" validate --is-release
}

test_check_is_rc_true() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc" validate --is-rc
}

test_check_is_rc_false() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --is-rc
}

test_check_is_dev_true() {
    daq_testing_assert_exit_code 0 "v3.14.2-abc123f" validate --is-dev
}

test_check_is_dev_false() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --is-dev
}

test_check_has_prefix_true() {
    daq_testing_assert_exit_code 0 "v3.14.2" validate --has-prefix
}

test_check_has_prefix_false() {
    daq_testing_assert_exit_code 1 "3.14.2" validate --has-prefix
}

test_check_has_suffix_true() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc" validate --has-suffix
}

test_check_has_suffix_false() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --has-suffix
}

test_check_has_hash_true() {
    daq_testing_assert_exit_code 0 "v3.14.2-abc123f" validate --has-hash
}

test_check_has_hash_false() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --has-hash
}

################################################################################
# TESTS: Format-Specific Validation
################################################################################

test_format_X_YY_Z_matches() {
    daq_testing_assert_exit_code 0 "3.14.2" validate --format "X.YY.Z"
}

test_format_vX_YY_Z_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2" validate --format "vX.YY.Z"
}

test_format_X_YY_Z_rc_matches() {
    daq_testing_assert_exit_code 0 "3.14.2-rc" validate --format "X.YY.Z-rc"
}

test_format_vX_YY_Z_rc_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc" validate --format "vX.YY.Z-rc"
}

test_format_X_YY_Z_HASH_matches() {
    daq_testing_assert_exit_code 0 "3.14.2-abc123f" validate --format "X.YY.Z-HASH"
}

test_format_vX_YY_Z_HASH_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2-abc123f" validate --format "vX.YY.Z-HASH"
}

test_format_mismatch_release_vs_rc() {
    daq_testing_assert_exit_code 1 "3.14.2-rc" validate --format "X.YY.Z"
}

test_format_mismatch_with_v_vs_without() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --format "X.YY.Z"
}

test_format_mismatch_without_v_vs_with() {
    daq_testing_assert_exit_code 1 "3.14.2" validate --format "vX.YY.Z"
}

################################################################################
# TESTS: Type-Specific Validation
################################################################################

test_type_release_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2" validate --type release
}

test_type_rc_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc" validate --type rc
}

test_type_dev_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2-abc123f" validate --type dev
}

test_type_rc_dev_matches() {
    daq_testing_assert_exit_code 0 "v3.14.2-rc-abc123f" validate --type rc-dev
}

test_type_mismatch_release_vs_rc() {
    daq_testing_assert_exit_code 1 "v3.14.2" validate --type rc
}

test_type_mismatch_rc_vs_dev() {
    daq_testing_assert_exit_code 1 "v3.14.2-rc" validate --type dev
}

################################################################################
# TESTS: Parsing - All Components
################################################################################

test_parse_all_has_major() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_MAJOR=3" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_minor() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_MINOR=14" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_patch() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_PATCH=2" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_prefix() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_PREFIX=v" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_suffix() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_SUFFIX=rc" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_hash() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_HASH=abc123f" "v3.14.2-rc-abc123f" parse
}

test_parse_all_has_type() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_TYPE=rc-dev" "v3.14.2-rc-abc123f" parse
}

################################################################################
# TESTS: Parsing - Single Components
################################################################################

test_parse_single_major() {
    daq_testing_assert_equals 0 "v3.14.2" parse --major
}

test_parse_single_minor() {
    daq_testing_assert_equals 0 "v3.14.2" parse --minor
}

test_parse_single_patch() {
    daq_testing_assert_equals 0 "v3.14.2" parse --patch
}

test_parse_single_type() {
    daq_testing_assert_equals 0 "v3.14.2-rc" parse --type
}

test_parse_single_prefix() {
    daq_testing_assert_equals 0 "v3.14.2" parse --prefix
}

test_parse_single_hash() {
    daq_testing_assert_equals 0 "v3.14.2-abc123f" parse --hash
}

################################################################################
# TESTS: Parsing - Multiple Components
################################################################################

test_parse_multiple_has_major() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_MAJOR=3" "v3.14.2" parse --major --minor --type
}

test_parse_multiple_has_minor() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_MINOR=14" "v3.14.2" parse --major --minor --type
}

test_parse_multiple_has_type() {
    daq_testing_assert_contains 0 "OPENDAQ_VERSION_PARSED_TYPE=release" "v3.14.2" parse --major --minor --type
}

################################################################################
# TESTS: Parsing - Empty Components
################################################################################

test_parse_empty_prefix() {
    daq_testing_assert_equals 0 "3.14.2" parse --prefix
}

test_parse_empty_suffix() {
    daq_testing_assert_equals 0 "3.14.2" parse --suffix
}

test_parse_empty_hash() {
    daq_testing_assert_equals 0 "3.14.2" parse --hash
}

################################################################################
# TESTS: Composition
################################################################################

test_compose_simple_release() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2
}

test_compose_rc_version() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --suffix rc
}

test_compose_dev_with_hash() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --hash abc123f
}

test_compose_without_prefix() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --no-prefix
}

test_compose_format_X_YY_Z() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --format "X.YY.Z"
}

test_compose_format_vX_YY_Z_rc() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --format "vX.YY.Z-rc"
}

test_compose_format_vX_YY_Z_rc_HASH() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --format "vX.YY.Z-rc-HASH" --hash abc123f
}

test_compose_type_release() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --type release
}

test_compose_type_rc() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --type rc
}

test_compose_type_dev() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --type dev --hash abc123f
}

test_compose_custom_suffix_beta() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --suffix beta
}

test_compose_custom_suffix_alpha() {
    daq_testing_assert_no_input 0 compose --major 3 --minor 14 --patch 2 --suffix alpha
}

################################################################################
# TESTS: Extraction
################################################################################

test_extract_simple() {
    daq_testing_assert_equals 0 "Release v3.14.2 is available" extract
}

test_extract_rc() {
    daq_testing_assert_equals 0 "Testing v3.14.2-rc build" extract
}

test_extract_dev() {
    daq_testing_assert_equals 0 "Build v3.14.2-abc123f completed" extract
}

test_extract_rc_dev() {
    daq_testing_assert_equals 0 "CI: v3.14.2-rc-abc123f passed" extract
}

test_extract_without_prefix() {
    daq_testing_assert_equals 0 "Version 3.14.2 deployed" extract
}

test_extract_from_filename() {
    daq_testing_assert_equals 0 "opendaq-v3.14.2-rc.tar.gz" extract
}

test_extract_first_version() {
    daq_testing_assert_equals 0 "Version 3.14.2 and 3.15.0 available" extract
}

test_extract_with_other_numbers() {
    daq_testing_assert_equals 0 "Port 8080 version 3.14.2 on 192.168.1.1" extract
}

test_extract_no_version_found() {
    daq_testing_assert_exit_code 1 "No version here" extract
}

################################################################################
# TESTS: Edge Cases
################################################################################

test_edge_large_version_numbers() {
    daq_testing_assert_equals 0 "999.999.999"
}

test_edge_single_digit_versions() {
    daq_testing_assert_equals 0 "1.2.3"
}

test_edge_zero_version() {
    daq_testing_assert_equals 0 "0.0.0"
}

test_edge_parse_large_major() {
    daq_testing_assert_equals 0 "999.14.2" parse --major
}

test_edge_long_hash() {
    daq_testing_assert_equals 0 "3.14.2-abcdef123456789" parse --hash
}

test_edge_short_hash() {
    daq_testing_assert_equals 0 "3.14.2-abc" parse --hash
}

test_edge_suffix_with_numbers() {
    daq_testing_assert_equals 0 "v3.14.2-beta-1" parse --suffix
}

test_edge_suffix_with_hyphens() {
    daq_testing_assert_equals 0 "v3.14.2-pre-release" parse --suffix
}

################################################################################
# TESTS: Error Handling
################################################################################

test_error_compose_missing_major() {
    daq_testing_assert_exit_code 1 "" compose --minor 14 --patch 2
}

test_error_compose_missing_minor() {
    daq_testing_assert_exit_code 1 "" compose --major 3 --patch 2
}

test_error_compose_missing_patch() {
    daq_testing_assert_exit_code 1 "" compose --major 3 --minor 14
}

test_error_parse_invalid_version() {
    daq_testing_assert_exit_code 1 "not-a-version" parse
}

test_error_validate_malformed() {
    daq_testing_assert_exit_code 1 "v3.14.2.1" validate
}

################################################################################
# END OF TEST SUITE
# Note: No explicit function calls needed - tests are auto-discovered
################################################################################
