#!/usr/bin/env bats

# Test suite for lib/adapter/install.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_install_test"
    mkdir -p "$TEST_DIR"

    # Source the library (will fail initially as expected)
    if [[ -f "$REPO_ROOT/lib/adapter/install.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/install.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "adapter_install_prepare() prepares installation directory" {
    skip "Implementation pending - test written first"

    run adapter_install_prepare "$TEST_DIR/target"
    assert_success
    [[ -d "$TEST_DIR/target" ]]
}

@test "adapter_install_validate() validates adapter structure" {
    skip "Implementation pending - test written first"

    # Create mock adapter
    mkdir -p "$TEST_DIR/adapter/commands"
    echo "test" > "$TEST_DIR/adapter/commands/test.md"
    echo "name: test-adapter" > "$TEST_DIR/adapter/config.yml"

    run adapter_install_validate "$TEST_DIR/adapter"
    assert_success
}

@test "adapter_install_copy_files() copies adapter files" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/source/commands"
    echo "content" > "$TEST_DIR/source/commands/test.md"

    run adapter_install_copy_files "$TEST_DIR/source" "$TEST_DIR/target"
    assert_success
    [[ -f "$TEST_DIR/target/commands/test.md" ]]
}

@test "adapter_install_prefix_commands() prefixes command files" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/commands"
    echo "test" > "$TEST_DIR/commands/plan.md"

    run adapter_install_prefix_commands "$TEST_DIR" "myframework"
    assert_success
    [[ -f "$TEST_DIR/commands/myframework_plan.md" ]]
    [[ ! -f "$TEST_DIR/commands/plan.md" ]]
}

@test "adapter_install_rewrite_paths() rewrites hardcoded paths" {
    skip "Implementation pending - test written first"

    echo '.specify/scripts/test.sh' > "$TEST_DIR/file.md"

    run adapter_install_rewrite_paths "$TEST_DIR/file.md" "{{SCRIPTS_PATH}}"
    assert_success

    content=$(<"$TEST_DIR/file.md")
    [[ "$content" == "{{SCRIPTS_PATH}}/test.sh" ]]
}

@test "adapter_install_create_manifest() creates installation manifest" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/adapter/commands"
    touch "$TEST_DIR/adapter/commands/test.md"

    run adapter_install_create_manifest "$TEST_DIR/adapter" "$TEST_DIR/manifest.json"
    assert_success
    [[ -f "$TEST_DIR/manifest.json" ]]

    # Verify manifest contains files
    grep -q "commands/test.md" "$TEST_DIR/manifest.json"
}

@test "adapter_install_with_backup() backs up existing files" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/existing"
    echo "original" > "$TEST_DIR/existing/file.txt"

    run adapter_install_with_backup "$TEST_DIR/existing" "$TEST_DIR/backup"
    assert_success
    [[ -f "$TEST_DIR/backup/file.txt" ]]
    [[ "$(<"$TEST_DIR/backup/file.txt")" == "original" ]]
}

@test "adapter_install_main() performs complete installation" {
    skip "Implementation pending - test written first"

    # Create mock adapter
    mkdir -p "$TEST_DIR/adapter/commands"
    echo "test" > "$TEST_DIR/adapter/commands/test.md"
    echo "name: test-adapter" > "$TEST_DIR/adapter/config.yml"

    run adapter_install_main "$TEST_DIR/adapter" "$TEST_DIR/target" --prefix "test"
    assert_success
    [[ -f "$TEST_DIR/target/.living-docs-manifest.json" ]]
    [[ -f "$TEST_DIR/target/commands/test_test.md" ]]
}