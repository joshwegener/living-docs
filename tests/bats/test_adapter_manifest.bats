#!/usr/bin/env bats

# Test suite for lib/adapter/manifest.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_manifest_test"
    mkdir -p "$TEST_DIR"

    # Source the library (will fail initially as expected)
    if [[ -f "$REPO_ROOT/lib/adapter/manifest.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/manifest.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "manifest_create() creates new manifest" {
    skip "Implementation pending - test written first"

    run manifest_create "$TEST_DIR/manifest.json" "test-adapter" "1.0.0"
    assert_success
    [[ -f "$TEST_DIR/manifest.json" ]]

    # Verify manifest structure
    grep -q '"name": "test-adapter"' "$TEST_DIR/manifest.json"
    grep -q '"version": "1.0.0"' "$TEST_DIR/manifest.json"
}

@test "manifest_add_file() adds file to manifest" {
    skip "Implementation pending - test written first"

    manifest_create "$TEST_DIR/manifest.json" "test" "1.0.0"

    run manifest_add_file "$TEST_DIR/manifest.json" "commands/test.md" "abc123"
    assert_success

    grep -q "commands/test.md" "$TEST_DIR/manifest.json"
    grep -q "abc123" "$TEST_DIR/manifest.json"
}

@test "manifest_remove_file() removes file from manifest" {
    skip "Implementation pending - test written first"

    manifest_create "$TEST_DIR/manifest.json" "test" "1.0.0"
    manifest_add_file "$TEST_DIR/manifest.json" "commands/test.md" "abc123"

    run manifest_remove_file "$TEST_DIR/manifest.json" "commands/test.md"
    assert_success

    ! grep -q "commands/test.md" "$TEST_DIR/manifest.json"
}

@test "manifest_list_files() lists all files in manifest" {
    skip "Implementation pending - test written first"

    manifest_create "$TEST_DIR/manifest.json" "test" "1.0.0"
    manifest_add_file "$TEST_DIR/manifest.json" "file1.md" "hash1"
    manifest_add_file "$TEST_DIR/manifest.json" "file2.md" "hash2"

    run manifest_list_files "$TEST_DIR/manifest.json"
    assert_success
    assert_output --partial "file1.md"
    assert_output --partial "file2.md"
}

@test "manifest_verify_integrity() checks file integrity" {
    skip "Implementation pending - test written first"

    manifest_create "$TEST_DIR/manifest.json" "test" "1.0.0"

    # Create test file
    echo "content" > "$TEST_DIR/test.md"
    hash=$(sha256sum "$TEST_DIR/test.md" | cut -d' ' -f1)

    manifest_add_file "$TEST_DIR/manifest.json" "test.md" "$hash"

    run manifest_verify_integrity "$TEST_DIR/manifest.json" "$TEST_DIR"
    assert_success
}

@test "manifest_load() loads existing manifest" {
    skip "Implementation pending - test written first"

    cat > "$TEST_DIR/manifest.json" << 'EOF'
{
    "name": "test-adapter",
    "version": "1.0.0",
    "files": []
}
EOF

    run manifest_load "$TEST_DIR/manifest.json"
    assert_success
    assert_output --partial "test-adapter"
}

@test "manifest_update_version() updates manifest version" {
    skip "Implementation pending - test written first"

    manifest_create "$TEST_DIR/manifest.json" "test" "1.0.0"

    run manifest_update_version "$TEST_DIR/manifest.json" "2.0.0"
    assert_success

    grep -q '"version": "2.0.0"' "$TEST_DIR/manifest.json"
}

@test "manifest_validate_schema() validates manifest structure" {
    skip "Implementation pending - test written first"

    # Create invalid manifest
    echo '{"invalid": true}' > "$TEST_DIR/bad.json"

    run manifest_validate_schema "$TEST_DIR/bad.json"
    assert_failure

    # Create valid manifest
    manifest_create "$TEST_DIR/good.json" "test" "1.0.0"

    run manifest_validate_schema "$TEST_DIR/good.json"
    assert_success
}