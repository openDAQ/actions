#!/bin/bash

################################################################################
# Test Suite: version-format (new style)
# Demonstration of new execute/assert architecture
################################################################################

test_version_format_detect_format() {    
    local script="core/version-format.sh"
    local test_result=0

    daq_testing_execute_script $script "v1.20.4" --detect-format
    local script_ec=$?
    local script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z version format should succeed" || test_result=1
    daq_testing_assert_equals "vX.YY.Z" "$script_out" "Detected vX.YY.Z version format mismatches" || test_result=1

    daq_testing_execute_script $script "v1.20.4-rc" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc version format should succeed" || test_result=1
    daq_testing_assert_equals "vX.YY.Z-rc" "$script_out" "Detected vX.YY.Z-rc version format mismatches" || test_result=1

    daq_testing_execute_script $script "v1.20.4-1a2b3e4f" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-HASH version format should succeed" || test_result=1
    daq_testing_assert_equals "vX.YY.Z-HASH" "$script_out" "Detected vX.YY.Z-HASH version format mismatches" || test_result=1

    daq_testing_execute_script $script "v1.20.4-rc-1a2b3e4f" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc-HASH version format should succeed" || test_result=1
    daq_testing_assert_equals "vX.YY.Z-rc-HASH" "$script_out" "Detected vX.YY.Z-rc-HASH version format mismatches" || test_result=1
    
    daq_testing_execute_script $script "1.20.4" --detect-format
    local script_ec=$?
    local script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect X.YY.Z version format should succeed" || test_result=1
    daq_testing_assert_equals "X.YY.Z" "$script_out" "Detected vX.YY.Z version format mismatches" || test_result=1

    daq_testing_execute_script $script "1.20.4-rc" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc version format should succeed" || test_result=1
    daq_testing_assert_equals "X.YY.Z-rc" "$script_out" "Detected vX.YY.Z-rc version format mismatches" || test_result=1

    daq_testing_execute_script $script "1.20.4-1a2b3c4f" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-HASH version format should succeed" || test_result=1
    daq_testing_assert_equals "X.YY.Z-HASH" "$script_out" "Detected vX.YY.Z-HASH version format mismatches" || test_result=1

    daq_testing_execute_script $script "1.20.4-rc-1a2b3c4f" --detect-format
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc-HASH version format should succeed" || test_result=1
    daq_testing_assert_equals "X.YY.Z-rc-HASH" "$script_out" "Detected vX.YY.Z-rc-HASH version format mismatches" || test_result=1

    return $test_result
}

test_version_format_detect_type() {
    local test_rc=0
    local script="core/version-format.sh"
    local script_ec=0
    local script_out=

    daq_testing_execute_script $script "1.20.4" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect X.YY.Z version type should succeed" || test_rc=1
    daq_testing_assert_equals "release" "$script_out" "Detected X.YY.Z version type mismatches" || test_rc=1

    daq_testing_execute_script $script "1.20.4-rc" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect X.YY.Z-rc version type should succeed" || test_rc=1
    daq_testing_assert_equals "rc" "$script_out" "Detected X.YY.Z-rc version type mismatches" || test_rc=1

    daq_testing_execute_script $script "1.20.4-1a2b3c4d" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect X.YY.Z-hash version type should succeed" || test_rc=1
    daq_testing_assert_equals "dev" "$script_out" "Detected X.YY.Z-hash version type mismatches" || test_rc=1

    daq_testing_execute_script $script "1.20.4-rc-1a2b3c4d" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect X.YY.Z-rc-hash version type should succeed" || test_rc=1
    daq_testing_assert_equals "rc-dev" "$script_out" "Detected X.YY.Z-rc-hash version type mismatches" || test_rc=1

    daq_testing_execute_script $script "v1.20.4" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z version type should succeed" || test_rc=1
    daq_testing_assert_equals "release" "$script_out" "Detected vX.YY.Z version type mismatches" || test_rc=1

    daq_testing_execute_script $script "v1.20.4-rc" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc version type should succeed" || test_rc=1
    daq_testing_assert_equals "rc" "$script_out" "Detected vX.YY.Z-rc version type mismatches" || test_rc=1

    daq_testing_execute_script $script "v1.20.4-1a2b3c4d" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-hash version type should succeed" || test_rc=1
    daq_testing_assert_equals "dev" "$script_out" "Detected vX.YY.Z-hash version type mismatches" || test_rc=1

    daq_testing_execute_script $script "v1.20.4-rc-1a2b3c4d" --detect-type
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Detect vX.YY.Z-rc-hash version type should succeed" || test_rc=1
    daq_testing_assert_equals "rc-dev" "$script_out" "Detect vX.YY.Z-rc-hash version type mismatches" || test_rc=1

    return $test_rc
}

test_version_format_validate() {
    local test_rc=0
    local script="core/version-format.sh"
    local script_ec=0
    local script_out=

    daq_testing_execute_script $script validate "1.20.4"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate release version should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate release version should succeed (preffixed)" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-rc"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate rc version should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate rc version should succeed (preffixed)" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-1a2b3d4e"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate dev version should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-1a2b3d4e"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate dev version should succeed (preffixed)" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-rc-1a2b3d4e"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate rc-dev version should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc-1a2b3d4e"
    script_ec=$?
    script_out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $script_ec "Validate rc-dev version should succeed (preffixed)" || test_rc=1

    return $test_rc
}

test_version_format_validate_format() {
    local test_rc=0
    local script="core/version-format.sh"

    daq_testing_execute_script $script validate "1.20.4" --format "X.YY.Z"
    daq_testing_assert_success $? "Validate X.YY.Z version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4" --format "vX.YY.Z"
    daq_testing_assert_success $? "Validate vX.YY.Z version format should succeed" || test_rc=1
    
    daq_testing_execute_script $script validate "1.20.4-rc" --format "X.YY.Z-rc"
    daq_testing_assert_success $? "Validate X.YY.Z-rc version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc" --format "vX.YY.Z-rc"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-1a2b3c4e" --format "X.YY.Z-HASH"
    daq_testing_assert_success $? "Validate X.YY.Z-HASH version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-1a2b3c4e" --format "vX.YY.Z-HASH"
    daq_testing_assert_success $? "Validate vX.YY.Z-HASH version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-rc-1a2b3c4e" --format "X.YY.Z-rc-HASH"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc-HASH version format should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc-1a2b3c4e" --format "vX.YY.Z-rc-HASH"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc-HASH version format should succeed" || test_rc=1

    return $test_rc
}

test_version_format_validate_type() {
    local test_rc=0
    local script="core/version-format.sh"

    daq_testing_execute_script $script validate "1.20.4" --type "release"
    daq_testing_assert_success $? "Validate X.YY.Z version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4" --type "release"
    daq_testing_assert_success $? "Validate vX.YY.Z version type should succeed" || test_rc=1
    
    daq_testing_execute_script $script validate "1.20.4-rc" --type "rc"
    daq_testing_assert_success $? "Validate X.YY.Z-rc version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc" --type "rc"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-1a2b3c4e" --type "dev"
    daq_testing_assert_success $? "Validate X.YY.Z-HASH version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-1a2b3c4e" --type "dev"
    daq_testing_assert_success $? "Validate vX.YY.Z-HASH version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "1.20.4-rc-1a2b3c4e" --type "rc-dev"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc-HASH version type should succeed" || test_rc=1

    daq_testing_execute_script $script validate "v1.20.4-rc-1a2b3c4e" --type "rc-dev"
    daq_testing_assert_success $? "Validate vX.YY.Z-rc-HASH version type should succeed" || test_rc=1

    return $test_rc
}

test_version_format_parse_vX_YY_Z() {
    local test_rc=0
    local script="core/version-format.sh"
    local out=

    daq_testing_execute_script $script parse "v3.14.2"
    out=$(daq_testing_execute_get_last_script_out)
    daq_testing_assert_success $? "Parse vX.YY.Z-HASH version type should succeed" || test_rc=1
    daq_testing_assert_contains "$out" "PARSED"
}