#!/usr/bin/env bats
# Test suite for a11y reporter module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file a11y/reporter.sh)"
}

@test "a11y reporter: can generate text report" {
    local test_data="missing-alt:img:line-10
missing-label:input:line-20
low-contrast:text:line-30"

    run generate_a11y_report "$test_data"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Accessibility Report" ]]
    [[ "$output" =~ "missing-alt" ]]
}

@test "a11y reporter: can generate JSON report" {
    local test_data="missing-alt:img:line-10"

    run generate_a11y_report_json "$test_data"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "{" ]]
    [[ "$output" =~ "\"issue\"" ]]
}

@test "a11y reporter: handles empty data" {
    run generate_a11y_report ""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No accessibility issues found" ]]
}

@test "a11y reporter: categorizes by severity" {
    local test_data="missing-alt:img:line-10:critical
low-contrast:text:line-20:warning"

    run generate_a11y_report "$test_data"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Critical" ]]
    [[ "$output" =~ "Warning" ]]
}