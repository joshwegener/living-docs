#!/usr/bin/env bats

# Test suite for lib/adapter/rewrite.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/adapter_rewrite_test"
    mkdir -p "$TEST_DIR"

    if [[ -f "$REPO_ROOT/lib/adapter/rewrite.sh" ]]; then
        source "$REPO_ROOT/lib/adapter/rewrite.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "rewrite_path() replaces hardcoded paths with variables" {
    skip "Implementation pending - test written first"

    echo '.specify/scripts/test.sh' > "$TEST_DIR/file.md"

    run rewrite_path "$TEST_DIR/file.md" ".specify/scripts" "{{SCRIPTS_PATH}}"
    assert_success

    content=$(<"$TEST_DIR/file.md")
    [[ "$content" == "{{SCRIPTS_PATH}}/test.sh" ]]
}

@test "rewrite_detect_paths() finds hardcoded paths" {
    skip "Implementation pending - test written first"

    echo '.specify/templates/test.md' > "$TEST_DIR/file.md"

    run rewrite_detect_paths "$TEST_DIR/file.md"
    assert_success
    assert_output --partial ".specify/templates"
}

@test "rewrite_apply_mappings() applies multiple path mappings" {
    skip "Implementation pending - test written first"

    cat > "$TEST_DIR/file.md" << 'CONTENT'
.specify/scripts/test.sh
.specify/templates/plan.md
CONTENT

    run rewrite_apply_mappings "$TEST_DIR/file.md"
    assert_success

    content=$(<"$TEST_DIR/file.md")
    [[ "$content" =~ "{{SCRIPTS_PATH}}" ]]
    [[ "$content" =~ "{{TEMPLATES_PATH}}" ]]
}

@test "rewrite_validate_variables() checks variable syntax" {
    skip "Implementation pending - test written first"

    run rewrite_validate_variables "{{VALID_VAR}}"
    assert_success

    run rewrite_validate_variables "{INVALID}"
    assert_failure
}

@test "rewrite_directory() rewrites all files in directory" {
    skip "Implementation pending - test written first"

    echo '.specify/scripts/test.sh' > "$TEST_DIR/file1.md"
    echo '.specify/templates/test.md' > "$TEST_DIR/file2.md"

    run rewrite_directory "$TEST_DIR"
    assert_success

    grep -q "{{SCRIPTS_PATH}}" "$TEST_DIR/file1.md"
    grep -q "{{TEMPLATES_PATH}}" "$TEST_DIR/file2.md"
}
