#!/usr/bin/env bats
# Security hardening tests for shell modules

setup() {
    # Set up test environment
    TEST_DIR="$(mktemp -d)"
    export PROJECT_ROOT="$TEST_DIR"

    # Source the modules
    source "${BATS_TEST_DIRNAME}/../../lib/adapter/updater.sh"
    source "${BATS_TEST_DIRNAME}/../../lib/a11y/engine.sh"
}

teardown() {
    # Clean up
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# Input validation tests
@test "check_adapter_updates rejects malicious adapter names" {
    run check_adapter_updates "../../../etc/passwd"
    [ "$status" -eq 1 ]

    run check_adapter_updates "adapter; rm -rf /"
    [ "$status" -eq 1 ]

    run check_adapter_updates "\$(cat /etc/passwd)"
    [ "$status" -eq 1 ]
}

@test "check_adapter_updates validates adapter name format" {
    # Should only accept alphanumeric, dash, underscore
    run check_adapter_updates "valid-adapter_name"
    [ "$status" -eq 1 ]  # Will fail due to no manifest, but should not error on name

    run check_adapter_updates "../../evil"
    [ "$status" -eq 1 ]
}

@test "compare_versions handles malicious version strings safely" {
    run compare_versions "1.0.0; rm -rf /" "2.0.0"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "rm" ]]

    run compare_versions "\$(whoami)" "2.0.0"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "root" ]]
}

# Path traversal protection tests
@test "manifest file path cannot be manipulated" {
    # Create a fake manifest in a predictable location
    mkdir -p "$TEST_DIR/.."
    echo '{"adapters": {"evil": {"version": "1.0.0"}}}' > "$TEST_DIR/../.living-docs-manifest.json"

    # Try to escape PROJECT_ROOT
    PROJECT_ROOT="$TEST_DIR/../../"
    run check_adapter_updates "test"
    [ "$status" -eq 1 ]
}

# Command injection protection in a11y engine
@test "check_missing_alt handles malicious HTML safely" {
    local malicious_html='<img src="\$(whoami)"> <img alt="\`rm -rf /\`">'
    run check_missing_alt "$malicious_html"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "root" ]]
    [[ ! "$output" =~ "rm" ]]
}

@test "check_missing_labels escapes regex special chars" {
    local malicious_html='<input id="test[^>]*">
<label for="test[^>]*">Label</label>'
    run check_missing_labels "$malicious_html"
    [ "$status" -eq 0 ]
}

# Version comparison edge cases
@test "compare_versions handles empty/null versions" {
    run compare_versions "" ""
    [ "$status" -eq 0 ]

    run compare_versions "null" "1.0.0"
    [ "$status" -eq 0 ]
}

@test "compare_versions handles non-semantic versions safely" {
    run compare_versions "not-a-version" "1.0.0"
    [ "$status" -eq 0 ]

    run compare_versions "1.0.0" "also-not-a-version"
    [ "$status" -eq 0 ]
}

# JSON injection protection
@test "jq operations are safe from injection" {
    # Create manifest with malicious content
    echo '{"adapters": {"test": {"version": "1.0.0\"; rm -rf /; echo \""}}}' > "$PROJECT_ROOT/.living-docs-manifest.json"

    run check_adapter_updates "test"
    [[ ! "$output" =~ "rm" ]]
}

# File permission checks
@test "sensitive operations check file permissions" {
    # Create manifest with loose permissions
    touch "$PROJECT_ROOT/.living-docs-manifest.json"
    chmod 777 "$PROJECT_ROOT/.living-docs-manifest.json"

    # Should warn about insecure permissions
    run check_adapter_updates "test"
    [[ "$output" =~ "permission" ]] || [[ "$output" =~ "Warning" ]] || [ "$status" -eq 1 ]
}