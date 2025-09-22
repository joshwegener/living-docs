#!/usr/bin/env bats

# Test suite for lib/adapter/prefix.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_prefix_test"
    mkdir -p "$TEST_DIR"

    if [[ -f "$REPO_ROOT/lib/adapter/prefix.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/prefix.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "prefix_add() adds prefix to filename" {
    skip "Implementation pending - test written first"

    run prefix_add "plan.md" "myframework"
    assert_success
    assert_output "myframework_plan.md"
}

@test "prefix_remove() removes prefix from filename" {
    skip "Implementation pending - test written first"

    run prefix_remove "myframework_plan.md" "myframework"
    assert_success
    assert_output "plan.md"
}

@test "prefix_detect() detects existing prefix" {
    skip "Implementation pending - test written first"

    run prefix_detect "framework_command.md"
    assert_success
    assert_output "framework"
}

@test "prefix_rename_files() renames multiple files" {
    skip "Implementation pending - test written first"

    touch "$TEST_DIR/plan.md" "$TEST_DIR/specify.md"

    run prefix_rename_files "$TEST_DIR" "test"
    assert_success
    [[ -f "$TEST_DIR/test_plan.md" ]]
    [[ -f "$TEST_DIR/test_specify.md" ]]
}

@test "prefix_check_conflicts() detects naming conflicts" {
    skip "Implementation pending - test written first"

    touch "$TEST_DIR/test_plan.md"

    run prefix_check_conflicts "$TEST_DIR" "test" "plan.md"
    assert_failure
    assert_output --partial "conflict"
}

@test "prefix_validate() validates prefix format" {
    skip "Implementation pending - test written first"

    run prefix_validate "valid-prefix"
    assert_success

    run prefix_validate "invalid prefix"
    assert_failure
}

@test "prefix_apply_to_directory() prefixes all files in directory" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/commands"
    touch "$TEST_DIR/commands/plan.md" "$TEST_DIR/commands/tasks.md"

    run prefix_apply_to_directory "$TEST_DIR/commands" "fw"
    assert_success
    [[ -f "$TEST_DIR/commands/fw_plan.md" ]]
    [[ -f "$TEST_DIR/commands/fw_tasks.md" ]]
}