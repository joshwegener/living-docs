#!/usr/bin/env bats
# Test suite for adapter updater module
# TDD: Test written BEFORE implementation

setup() {
    load test_helper
    source "$(find_lib_file adapter/updater.sh)"
}

@test "adapter updater: can check for updates" {
    run check_adapter_updates "test-adapter"
    [ "$status" -eq 0 ]
}

@test "adapter updater: can compare versions" {
    run compare_versions "1.2.3" "1.2.4"
    [ "$status" -eq 1 ]  # 1.2.3 < 1.2.4
}

@test "adapter updater: can backup current version" {
    local test_dir=$(mktemp -d)
    run backup_adapter_version "test-adapter" "$test_dir"
    [ "$status" -eq 0 ]
    rm -rf "$test_dir"
}

@test "adapter updater: can apply updates safely" {
    local test_dir=$(mktemp -d)
    run apply_adapter_update "test-adapter" "$test_dir"
    [ "$status" -eq 0 ]
    rm -rf "$test_dir"
}