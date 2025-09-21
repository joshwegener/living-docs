#!/usr/bin/env bash
# Bats test helper for living-docs
# Common setup and teardown functions for all tests

# Set up test environment
setup() {
    export TEST_DIR="$(mktemp -d)"
    export LIVING_DOCS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    export PATH="$LIVING_DOCS_ROOT/lib:$PATH"

    # Source security library if it exists
    if [[ -f "$LIVING_DOCS_ROOT/lib/security/paths.sh" ]]; then
        source "$LIVING_DOCS_ROOT/lib/security/paths.sh"
    fi

    # Create test working directory
    cd "$TEST_DIR" || exit 1
}

# Clean up after tests
teardown() {
    # Return to original directory
    cd "$LIVING_DOCS_ROOT" || exit 1

    # Clean up test directory if it exists
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper to run wizard.sh with test parameters
run_wizard() {
    run bash "$LIVING_DOCS_ROOT/wizard.sh" "$@"
}

# Helper to create test files
create_test_file() {
    local file="$1"
    local content="${2:-test content}"
    # Create parent directory if needed
    local dir
    dir=$(dirname "$file")
    [[ "$dir" != "." ]] && mkdir -p "$dir"
    echo "$content" > "$file"
}

# Assert file exists
assert_file_exists() {
    [[ -f "$1" ]] || fail "File $1 does not exist"
}

# Assert directory exists
assert_dir_exists() {
    [[ -d "$1" ]] || fail "Directory $1 does not exist"
}

# Fail function for assertions
fail() {
    echo "$1" >&2
    return 1
}

# Assert output contains text
assert_output_contains() {
    [[ "$output" == *"$1"* ]] || fail "Output does not contain: $1"
}

# Assert output matches regex pattern
assert_output_matches() {
    [[ "$output" =~ $1 ]] || fail "Output does not match pattern: $1"
}

# Mock function for testing
mock_function() {
    local func_name="$1"
    local return_value="${2:-0}"
    eval "$func_name() { return $return_value; }"
    export -f "$func_name"
}

# Assert command succeeds
assert_success() {
    [[ "$status" -eq 0 ]] || fail "Command failed with status $status"
}

# Assert command fails
assert_failure() {
    [[ "$status" -ne 0 ]] || fail "Command unexpectedly succeeded"
}

# Assert specific status code
assert_status() {
    local expected="$1"
    [[ "$status" -eq "$expected" ]] || fail "Expected status $expected, got $status"
}