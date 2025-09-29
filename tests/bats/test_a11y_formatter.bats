#!/usr/bin/env bats
# Test suite for a11y formatter module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file a11y/formatter.sh)"
}

@test "a11y formatter: can format error messages" {
    run format_a11y_error "missing-alt" "img" "10"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Missing alt attribute" ]]
}

@test "a11y formatter: can format warning messages" {
    run format_a11y_warning "low-contrast" "text" "20"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Low contrast" ]]
}

@test "a11y formatter: can colorize output" {
    run colorize_a11y_output "critical" "Test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Test message" ]]
}

@test "a11y formatter: can generate fix suggestions" {
    run suggest_a11y_fix "missing-alt"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alt=" ]]
}