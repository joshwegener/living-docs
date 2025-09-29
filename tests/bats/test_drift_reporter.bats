#!/usr/bin/env bats
# Test suite for drift reporter module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file drift/reporter.sh)"
}

@test "drift reporter: can generate text report" {
    local test_data="file1.md:CREATED
file2.sh:MODIFIED
file3.txt:DELETED"

    run generate_drift_report "$test_data"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Drift Report" ]]
    [[ "$output" =~ "file1.md" ]]
}

@test "drift reporter: can generate JSON report" {
    local test_data="file1.md:CREATED"

    run generate_drift_report_json "$test_data"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "{" ]]
    [[ "$output" =~ "\"file\"" ]]
}

@test "drift reporter: handles empty drift data" {
    run generate_drift_report ""
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No drift detected" ]]
}