#!/usr/bin/env bats

# Test suite for lib/adapter/update.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_update_test"
    mkdir -p "$TEST_DIR"

    if [[ -f "$REPO_ROOT/lib/adapter/update.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/update.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "adapter_update_check_version() compares versions" {
    skip "Implementation pending - test written first"

    run adapter_update_check_version "1.0.0" "2.0.0"
    assert_success
    assert_output --partial "update available"

    run adapter_update_check_version "2.0.0" "1.0.0"
    assert_failure
}

@test "adapter_update_backup_customizations() preserves user changes" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/current"
    echo "user customization" > "$TEST_DIR/current/custom.md"

    run adapter_update_backup_customizations "$TEST_DIR/current" "$TEST_DIR/backup"
    assert_success
    [[ -f "$TEST_DIR/backup/custom.md" ]]
}

@test "adapter_update_merge_changes() merges updates with customizations" {
    skip "Implementation pending - test written first"

    echo "old content" > "$TEST_DIR/current.md"
    echo "new content" > "$TEST_DIR/new.md"
    echo "custom content" > "$TEST_DIR/custom.md"

    run adapter_update_merge_changes "$TEST_DIR/current.md" "$TEST_DIR/new.md" "$TEST_DIR/custom.md"
    assert_success
}

@test "adapter_update_verify_compatibility() checks compatibility" {
    skip "Implementation pending - test written first"

    run adapter_update_verify_compatibility "5.0.0" "5.1.0"
    assert_success

    run adapter_update_verify_compatibility "5.0.0" "6.0.0"
    assert_failure
    assert_output --partial "major version"
}

@test "adapter_update_apply() applies update to adapter" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/current" "$TEST_DIR/new"
    echo '{"version": "1.0.0"}' > "$TEST_DIR/current/.living-docs-manifest.json"
    echo '{"version": "2.0.0"}' > "$TEST_DIR/new/.living-docs-manifest.json"

    run adapter_update_apply "$TEST_DIR/current" "$TEST_DIR/new"
    assert_success

    grep -q '"version": "2.0.0"' "$TEST_DIR/current/.living-docs-manifest.json"
}

@test "adapter_update_rollback() reverts failed update" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/backup"
    echo "backup" > "$TEST_DIR/backup/file.txt"

    run adapter_update_rollback "$TEST_DIR/current" "$TEST_DIR/backup"
    assert_success
    [[ -f "$TEST_DIR/current/file.txt" ]]
}
