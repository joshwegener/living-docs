#!/usr/bin/env bats

load test_helper

# Path traversal prevention tests for lib/security/paths.sh
# These tests should fail initially and drive TDD implementation
#
# TDD Implementation Strategy:
# 1. All tests currently fail (lib/security/paths.sh doesn't exist)
# 2. Implement functions one by one to make tests pass
# 3. Start with detect_path_traversal, then validate_* functions
# 4. Implement helper functions (normalize_path, safe_path_join, etc.)
# 5. Finish with comprehensive path_security_check function
#
# Run tests with: ./scripts/test-paths.sh [pattern]

@test "loads path security library" {
    # This test should fail until lib/security/paths.sh is implemented
    [ -f "$LIVING_DOCS_ROOT/lib/security/paths.sh" ]
    run source "$LIVING_DOCS_ROOT/lib/security/paths.sh"
    [ "$status" -eq 0 ]
}

@test "detect_path_traversal: detects basic ../ attack" {
    run detect_path_traversal "../etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "detect_path_traversal: detects encoded ../ attack" {
    run detect_path_traversal "%2e%2e/etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "detect_path_traversal: detects double-encoded ../ attack" {
    run detect_path_traversal "%252e%252e/etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "detect_path_traversal: detects nested path traversal" {
    run detect_path_traversal "docs/../../etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "detect_path_traversal: detects Windows-style path traversal" {
    run detect_path_traversal "..\..\..\windows\system32\config"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "detect_path_traversal: allows safe relative paths" {
    run detect_path_traversal "docs/current.md"
    [ "$status" -eq 0 ]
}

@test "detect_path_traversal: allows current directory references" {
    run detect_path_traversal "./docs/current.md"
    [ "$status" -eq 0 ]
}

@test "validate_absolute_path: rejects relative paths" {
    run validate_absolute_path "docs/current.md"
    [ "$status" -eq 1 ]
    assert_output_contains "absolute path required"
}

@test "validate_absolute_path: accepts valid absolute paths" {
    run validate_absolute_path "/tmp/test.txt"
    [ "$status" -eq 0 ]
}

@test "validate_absolute_path: rejects empty paths" {
    run validate_absolute_path ""
    [ "$status" -eq 1 ]
    assert_output_contains "empty path"
}

@test "validate_relative_path: rejects absolute paths" {
    run validate_relative_path "/etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "relative path required"
}

@test "validate_relative_path: accepts valid relative paths" {
    run validate_relative_path "docs/current.md"
    [ "$status" -eq 0 ]
}

@test "validate_relative_path: rejects path traversal in relative paths" {
    run validate_relative_path "../etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "resolve_symlinks: resolves symbolic links safely" {
    # Create test symlink
    create_test_file "$TEST_DIR/target.txt" "test content"
    ln -s "$TEST_DIR/target.txt" "$TEST_DIR/link.txt"

    run resolve_symlinks "$TEST_DIR/link.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_DIR/target.txt" ]
}

@test "resolve_symlinks: detects dangerous symlink loops" {
    # Create symlink loop
    ln -s "$TEST_DIR/loop2" "$TEST_DIR/loop1"
    ln -s "$TEST_DIR/loop1" "$TEST_DIR/loop2"

    run resolve_symlinks "$TEST_DIR/loop1"
    [ "$status" -eq 1 ]
    assert_output_contains "symlink loop"
}

@test "resolve_symlinks: prevents symlink escaping base directory" {
    # Create symlink pointing outside test directory
    ln -s "/etc/passwd" "$TEST_DIR/evil_link"

    run resolve_symlinks "$TEST_DIR/evil_link" "$TEST_DIR"
    [ "$status" -eq 1 ]
    assert_output_contains "symlink escape"
}

@test "safe_path_join: joins paths safely" {
    run safe_path_join "/base/dir" "subdir/file.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "/base/dir/subdir/file.txt" ]
}

@test "safe_path_join: prevents path traversal in joined paths" {
    run safe_path_join "/base/dir" "../../../etc/passwd"
    [ "$status" -eq 1 ]
    assert_output_contains "path traversal"
}

@test "safe_path_join: normalizes multiple slashes" {
    run safe_path_join "/base//dir/" "//subdir///file.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "/base/dir/subdir/file.txt" ]
}

@test "safe_path_join: handles empty components" {
    run safe_path_join "/base/dir" ""
    [ "$status" -eq 0 ]
    [ "$output" = "/base/dir" ]
}

@test "normalize_path: removes redundant path components" {
    run normalize_path "/base/./dir/../other/./file.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "/base/other/file.txt" ]
}

@test "normalize_path: preserves root directory" {
    run normalize_path "/../../../"
    [ "$status" -eq 0 ]
    [ "$output" = "/" ]
}

@test "normalize_path: handles relative path normalization" {
    run normalize_path "dir/../other/./file.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "other/file.txt" ]
}

@test "is_within_base: validates path is within base directory" {
    run is_within_base "/base/dir/file.txt" "/base"
    [ "$status" -eq 0 ]
}

@test "is_within_base: rejects paths outside base directory" {
    run is_within_base "/other/dir/file.txt" "/base"
    [ "$status" -eq 1 ]
    assert_output_contains "outside base"
}

@test "is_within_base: handles symlinks properly" {
    # Create symlink that escapes base
    mkdir -p "$TEST_DIR/base/subdir"
    create_test_file "$TEST_DIR/outside.txt" "content"
    ln -s "$TEST_DIR/outside.txt" "$TEST_DIR/base/subdir/link"

    run is_within_base "$TEST_DIR/base/subdir/link" "$TEST_DIR/base"
    [ "$status" -eq 1 ]
    assert_output_contains "outside base"
}

@test "sanitize_filename: removes dangerous characters" {
    run sanitize_filename "file../name?.txt"
    [ "$status" -eq 0 ]
    [ "$output" = "file__name_.txt" ]
}

@test "sanitize_filename: handles null bytes" {
    run sanitize_filename $'file\x00name.txt'
    [ "$status" -eq 0 ]
    [ "$output" = "file_name.txt" ]
}

@test "sanitize_filename: rejects control characters" {
    run sanitize_filename $'file\x01\x02name.txt'
    [ "$status" -eq 0 ]
    [ "$output" = "file__name.txt" ]
}

@test "validate_file_extension: allows whitelisted extensions" {
    run validate_file_extension "document.md" "md,txt,json"
    [ "$status" -eq 0 ]
}

@test "validate_file_extension: rejects non-whitelisted extensions" {
    run validate_file_extension "script.sh" "md,txt,json"
    [ "$status" -eq 1 ]
    assert_output_contains "invalid extension"
}

@test "validate_file_extension: handles case insensitivity" {
    run validate_file_extension "document.MD" "md,txt,json"
    [ "$status" -eq 0 ]
}

@test "path_security_check: comprehensive security validation" {
    run path_security_check "/base/dir/file.txt" "/base" "txt,md"
    [ "$status" -eq 0 ]
}

@test "path_security_check: fails on any security violation" {
    run path_security_check "/base/../etc/passwd" "/base" "txt,md"
    [ "$status" -eq 1 ]
    assert_output_contains "security violation"
}