#!/usr/bin/env bats
# Tests for security input sanitizer functions

setup() {
    # Source the security module
    source "${BATS_TEST_DIRNAME}/../../lib/security/input-sanitizer.sh"

    # Set up test environment
    export PROJECT_ROOT="$(mktemp -d)"
}

teardown() {
    [[ -d "$PROJECT_ROOT" ]] && rm -rf "$PROJECT_ROOT"
}

@test "validate_adapter_name rejects path traversal" {
    run validate_adapter_name "../../../etc/passwd"
    [ "$status" -eq 1 ]

    run validate_adapter_name "adapter/../evil"
    [ "$status" -eq 1 ]
}

@test "validate_adapter_name rejects command injection" {
    run validate_adapter_name "adapter; rm -rf /"
    [ "$status" -eq 1 ]

    run validate_adapter_name "\$(whoami)"
    [ "$status" -eq 1 ]

    run validate_adapter_name "adapter\`cat /etc/passwd\`"
    [ "$status" -eq 1 ]
}

@test "validate_adapter_name accepts valid names" {
    run validate_adapter_name "valid-adapter"
    [ "$status" -eq 0 ]

    run validate_adapter_name "adapter_123"
    [ "$status" -eq 0 ]

    run validate_adapter_name "MyAdapter"
    [ "$status" -eq 0 ]
}

@test "sanitize_version removes malicious content" {
    run sanitize_version "1.0.0; rm -rf /"
    [ "$status" -eq 0 ]
    [ "$output" = "1.0.0" ]

    run sanitize_version "v2.3.4\$(whoami)"
    [ "$status" -eq 0 ]
    [ "$output" = "2.3.4" ]
}

@test "sanitize_version handles invalid versions" {
    run sanitize_version "not-a-version"
    [ "$status" -eq 0 ]
    [ "$output" = "0.0.0" ]

    run sanitize_version ""
    [ "$status" -eq 0 ]
    [ "$output" = "0.0.0" ]
}

@test "check_file_permissions detects insecure perms" {
    local test_file="$PROJECT_ROOT/test.json"
    echo "{}" > "$test_file"

    # Secure permissions
    chmod 644 "$test_file"
    run check_file_permissions "$test_file"
    [ "$status" -eq 0 ]

    # World-writable
    chmod 666 "$test_file"
    run check_file_permissions "$test_file"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "WARNING" ]]
}

@test "escape_regex escapes special characters" {
    run escape_regex "test[^>]*"
    [ "$status" -eq 0 ]
    [ "$output" = "test\\[\\^>\\]\\*" ]

    run escape_regex "id.test|other"
    [ "$status" -eq 0 ]
    [ "$output" = "id\\.test\\|other" ]
}

@test "sanitize_path prevents traversal" {
    run sanitize_path "$PROJECT_ROOT/../evil"
    [ "$status" -eq 1 ]

    run sanitize_path "../../etc/passwd"
    [ "$status" -eq 1 ]
}

@test "sanitize_path allows valid paths within PROJECT_ROOT" {
    mkdir -p "$PROJECT_ROOT/subdir"

    run sanitize_path "$PROJECT_ROOT/subdir"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "$PROJECT_ROOT" ]]
}