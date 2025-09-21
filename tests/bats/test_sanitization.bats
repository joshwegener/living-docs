#!/usr/bin/env bats
# Input sanitization tests for living-docs security module
# Tests should initially FAIL to drive TDD implementation

load test_helper

# Setup for each test
setup() {
    # Call parent setup from test_helper
    setup

    # Source the sanitization module (will fail initially)
    source "$LIVING_DOCS_ROOT/lib/security/sanitize.sh" 2>/dev/null || true
}

@test "sanitize_input function exists" {
    # This should fail initially - function doesn't exist yet
    type sanitize_input
}

@test "sanitize_framework_name function exists" {
    # This should fail initially - function doesn't exist yet
    type sanitize_framework_name
}

@test "sanitize_path function exists" {
    # This should fail initially - function doesn't exist yet
    type sanitize_path
}

# Command injection prevention tests
@test "sanitize_input blocks command injection with semicolon" {
    run sanitize_input "test; rm -rf /"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_input blocks command injection with pipe" {
    run sanitize_input "test | rm -rf /"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_input blocks command injection with ampersand" {
    run sanitize_input "test && rm -rf /"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_input blocks command injection with backticks" {
    run sanitize_input "test\`rm -rf /\`"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_input blocks command injection with dollar parentheses" {
    run sanitize_input "test\$(rm -rf /)"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_input blocks command injection with newline" {
    run sanitize_input $'test\nrm -rf /'
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

# Path traversal prevention tests
@test "sanitize_path blocks directory traversal with double dots" {
    run sanitize_path "../../../etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_path blocks absolute paths outside project" {
    run sanitize_path "/etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

@test "sanitize_path blocks null bytes" {
    run sanitize_path $'test\x00file'
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

# Special character handling tests
@test "sanitize_input blocks dangerous special characters" {
    # Test various dangerous characters
    local dangerous_chars=( ">" "<" "|" "&" ";" "\$" "\`" "(" ")" "{" "}" "[" "]" )

    for char in "${dangerous_chars[@]}"; do
        run sanitize_input "test${char}dangerous"
        [ "$status" -eq 1 ]
        assert_output_contains "SECURITY_VIOLATION"
    done
}

@test "sanitize_input allows safe special characters" {
    # Test safe characters that should be allowed
    local safe_chars=( "-" "_" "." ":" "@" "+" "=" "," "/" )

    for char in "${safe_chars[@]}"; do
        run sanitize_input "test${char}safe"
        [ "$status" -eq 0 ]
        [[ "$output" == "test${char}safe" ]]
    done
}

# Valid input preservation tests
@test "sanitize_input preserves valid alphanumeric input" {
    run sanitize_input "validInput123"
    [ "$status" -eq 0 ]
    [[ "$output" == "validInput123" ]]
}

@test "sanitize_input preserves valid framework names" {
    local valid_names=( "spec-kit" "agent-os" "continue" "cursor" "aider" )

    for name in "${valid_names[@]}"; do
        run sanitize_input "$name"
        [ "$status" -eq 0 ]
        [[ "$output" == "$name" ]]
    done
}

@test "sanitize_input preserves valid paths" {
    run sanitize_input "docs/current.md"
    [ "$status" -eq 0 ]
    [[ "$output" == "docs/current.md" ]]
}

# Framework name validation tests
@test "sanitize_framework_name validates known frameworks" {
    local valid_frameworks=( "spec-kit" "agent-os" "continue" "cursor" "aider" "bmad-method" )

    for framework in "${valid_frameworks[@]}"; do
        run sanitize_framework_name "$framework"
        [ "$status" -eq 0 ]
        [[ "$output" == "$framework" ]]
    done
}

@test "sanitize_framework_name rejects unknown frameworks" {
    run sanitize_framework_name "unknown-framework"
    [ "$status" -eq 1 ]
    assert_output_contains "INVALID_FRAMEWORK"
}

@test "sanitize_framework_name rejects frameworks with injection attempts" {
    run sanitize_framework_name "spec-kit; rm -rf /"
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

# Length validation tests
@test "sanitize_input rejects excessively long input" {
    # Create 1000+ character string
    local long_input=$(printf 'a%.0s' {1..1001})
    run sanitize_input "$long_input"
    [ "$status" -eq 1 ]
    assert_output_contains "INPUT_TOO_LONG"
}

@test "sanitize_input accepts reasonable length input" {
    # Create 255 character string (reasonable limit)
    local normal_input=$(printf 'a%.0s' {1..255})
    run sanitize_input "$normal_input"
    [ "$status" -eq 0 ]
    [[ "$output" == "$normal_input" ]]
}

# Empty/null input tests
@test "sanitize_input handles empty input" {
    run sanitize_input ""
    [ "$status" -eq 1 ]
    assert_output_contains "EMPTY_INPUT"
}

@test "sanitize_input handles whitespace-only input" {
    run sanitize_input "   "
    [ "$status" -eq 1 ]
    assert_output_contains "EMPTY_INPUT"
}

# Unicode and encoding tests
@test "sanitize_input handles basic unicode safely" {
    run sanitize_input "test-café"
    [ "$status" -eq 0 ]
    [[ "$output" == "test-café" ]]
}

@test "sanitize_input blocks control characters" {
    # Test various control characters
    run sanitize_input $'test\x01\x02\x03control'
    [ "$status" -eq 1 ]
    assert_output_contains "SECURITY_VIOLATION"
}

# Path normalization tests
@test "sanitize_path normalizes relative paths safely" {
    run sanitize_path "./docs/current.md"
    [ "$status" -eq 0 ]
    [[ "$output" == "docs/current.md" ]]
}

@test "sanitize_path preserves valid nested paths" {
    run sanitize_path "adapters/spec-kit/templates/memory/constitution.md"
    [ "$status" -eq 0 ]
    [[ "$output" == "adapters/spec-kit/templates/memory/constitution.md" ]]
}

# Configuration validation tests
@test "sanitize_input validates config values" {
    # Test YAML-safe values
    run sanitize_input "true"
    [ "$status" -eq 0 ]
    [[ "$output" == "true" ]]

    run sanitize_input "false"
    [ "$status" -eq 0 ]
    [[ "$output" == "false" ]]

    run sanitize_input "123"
    [ "$status" -eq 0 ]
    [[ "$output" == "123" ]]
}

# Error message tests
@test "sanitization functions provide helpful error messages" {
    run sanitize_input "test; injection"
    [ "$status" -eq 1 ]
    assert_output_contains "Command injection detected"
    assert_output_contains "Input rejected for security"
}

@test "sanitization functions log security violations" {
    # Should log to stderr for monitoring
    run sanitize_input "test\$(malicious)"
    [ "$status" -eq 1 ]
    # Check that security violation was logged (to stderr)
    [[ "$output" == *"SECURITY_VIOLATION"* ]]
}