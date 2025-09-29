#!/usr/bin/env bats

# Test suite for lib/adapter/remove.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_remove_test"
    mkdir -p "$TEST_DIR"

    if [[ -f "$REPO_ROOT/lib/adapter/remove.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/remove.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "adapter_remove_using_manifest() removes files listed in manifest" {
    skip "Implementation pending - test written first"

    # Create test files
    mkdir -p "$TEST_DIR/commands"
    touch "$TEST_DIR/commands/test.md"
    
    # Create manifest
    echo '{"files": ["commands/test.md"]}' > "$TEST_DIR/.living-docs-manifest.json"

    run adapter_remove_using_manifest "$TEST_DIR"
    assert_success
    [[ ! -f "$TEST_DIR/commands/test.md" ]]
}

@test "adapter_remove_backup() backs up before removal" {
    skip "Implementation pending - test written first"

    touch "$TEST_DIR/file.txt"

    run adapter_remove_backup "$TEST_DIR" "$TEST_DIR/backup"
    assert_success
    [[ -f "$TEST_DIR/backup/file.txt" ]]
}

@test "adapter_remove_verify() verifies removal is safe" {
    skip "Implementation pending - test written first"

    echo '{"name": "test"}' > "$TEST_DIR/.living-docs-manifest.json"

    run adapter_remove_verify "$TEST_DIR"
    assert_success
}

@test "adapter_remove_clean_empty_dirs() removes empty directories" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/empty/nested/dirs"

    run adapter_remove_clean_empty_dirs "$TEST_DIR/empty"
    assert_success
    [[ ! -d "$TEST_DIR/empty" ]]
}

@test "adapter_remove_complete() performs complete removal" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/adapter"
    echo '{"files": []}' > "$TEST_DIR/adapter/.living-docs-manifest.json"

    run adapter_remove_complete "$TEST_DIR/adapter"
    assert_success
    [[ ! -f "$TEST_DIR/adapter/.living-docs-manifest.json" ]]
}
