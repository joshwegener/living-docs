#!/usr/bin/env bats
# Test suite for a11y rule engine module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file a11y/engine.sh)"
}

@test "a11y engine: can check missing alt attributes" {
    local html='<img src="test.jpg">'

    run check_missing_alt "$html"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "missing-alt" ]]
}

@test "a11y engine: passes with alt attribute present" {
    local html='<img src="test.jpg" alt="Test image">'

    run check_missing_alt "$html"
    [ "$status" -eq 0 ]
    [[ -z "$output" ]]
}

@test "a11y engine: can check missing labels" {
    local html='<input type="text" name="username">'

    run check_missing_labels "$html"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "missing-label" ]]
}

@test "a11y engine: can run all checks" {
    local html='<img src="test.jpg"><input type="text">'

    run run_all_a11y_checks "$html"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "missing-alt" ]]
    [[ "$output" =~ "missing-label" ]]
}