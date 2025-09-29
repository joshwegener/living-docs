#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing path traversal prevention security

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy security libraries
    cp -r "${BATS_TEST_DIRNAME}/../../lib/security" lib/

    # Create test directory structure
    mkdir -p safe/area
    mkdir -p restricted
    echo "secret" > restricted/sensitive.txt
    echo "public" > safe/area/public.txt
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "security: Path traversal with ../ sequences blocked" {
    # Various path traversal attempts
    local bad_paths=(
        "../../../etc/passwd"
        "../../restricted/sensitive.txt"
        "safe/../../restricted/sensitive.txt"
        "./../restricted/sensitive.txt"
        "safe/area/../../../restricted/sensitive.txt"
    )

    # THIS TEST WILL FAIL: No path traversal prevention
    source lib/security/paths.sh
    for path in "${bad_paths[@]}"; do
        run resolve_safe_path "$path" "safe"
        [ "$status" -ne 0 ]  # Should reject traversal attempts
    done
}

@test "security: Symbolic link traversal prevention" {
    # Create malicious symlink
    ln -s ../../restricted/sensitive.txt safe/area/evil_link

    # THIS TEST WILL FAIL: No symlink traversal prevention
    run access_file_safely "safe/area/evil_link"
    [ "$status" -ne 0 ]  # Should reject symlink to restricted area

    # Should detect symlink escape (THIS WILL FAIL)
    [[ "$output" =~ "symlink" ]] || [[ "$output" =~ "restricted" ]]
}

@test "security: Absolute path injection blocked" {
    # Absolute path attempts
    local bad_paths=(
        "/etc/passwd"
        "/root/.ssh/id_rsa"
        "/var/log/auth.log"
        "file:///etc/shadow"
    )

    # THIS TEST WILL FAIL: No absolute path blocking
    for path in "${bad_paths[@]}"; do
        run validate_relative_path "$path"
        [ "$status" -ne 0 ]  # Should reject absolute paths
    done
}

@test "security: URL encoded path traversal blocked" {
    # URL encoded traversal attempts
    local encoded_paths=(
        "..%2F..%2F..%2Fetc%2Fpasswd"
        "%2e%2e%2f%2e%2e%2frestricted"
        "..%252F..%252F..%252Fetc"  # Double encoded
        "%c0%ae%c0%ae%c0%af"  # Unicode encoded ../
    )

    # THIS TEST WILL FAIL: No URL decoding protection
    for path in "${encoded_paths[@]}"; do
        run decode_and_validate_path "$path"
        [ "$status" -ne 0 ]  # Should detect encoded traversal
    done
}

@test "security: Null byte injection prevention" {
    # Null byte injection attempts
    local null_paths=(
        "safe.txt\x00.jpg"
        "file.php\x00.txt"
        "allowed%00.restricted"
    )

    # THIS TEST WILL FAIL: No null byte prevention
    for path in "${null_paths[@]}"; do
        run validate_path_no_null "$path"
        [ "$status" -ne 0 ]  # Should reject null bytes
    done
}

@test "security: Windows path traversal patterns blocked" {
    # Windows-style traversal
    local win_paths=(
        "..\\..\\windows\\system32"
        "C:\\Windows\\System32\\config\\sam"
        "\\\\server\\share\\sensitive"
        "AUX"
        "CON"
        "PRN"
    )

    # THIS TEST WILL FAIL: No Windows path protection
    for path in "${win_paths[@]}"; do
        run validate_unix_path "$path"
        [ "$status" -ne 0 ]  # Should reject Windows paths
    done
}

@test "security: Directory listing prevention" {
    # Attempt to list parent directories
    local list_attempts=(
        "./"
        "../"
        "/"
        "~/"
        "."
        ".."
    )

    # THIS TEST WILL FAIL: No directory listing prevention
    for attempt in "${list_attempts[@]}"; do
        run prevent_directory_listing "$attempt"
        [ "$status" -ne 0 ]  # Should block directory listings
    done
}

@test "security: Chroot jail enforcement" {
    # Set up chroot jail
    export JAIL_ROOT="$TEST_DIR/safe"

    # Attempt to escape jail
    cd "$JAIL_ROOT"

    # THIS TEST WILL FAIL: No chroot enforcement
    run enforce_jail "../restricted/sensitive.txt"
    [ "$status" -ne 0 ]  # Should prevent jail escape

    # Should stay within jail (THIS WILL FAIL)
    [[ "$PWD" =~ "$JAIL_ROOT" ]]
}

@test "security: Race condition prevention in path checks" {
    # Create file that will be replaced
    echo "original" > safe/area/target.txt

    # THIS TEST WILL FAIL: No TOCTOU prevention
    # Check file then try to use it (simulating race condition)
    validate_path_safe "safe/area/target.txt" &
    PID=$!

    # Replace file during check
    sleep 0.01
    rm safe/area/target.txt
    ln -s ../../restricted/sensitive.txt safe/area/target.txt

    wait $PID
    STATUS=$?

    [ "$STATUS" -ne 0 ]  # Should detect race condition
}

@test "security: Unicode normalization in paths" {
    # Unicode tricks in paths
    local unicode_paths=(
        "safe/área/../../../etc"  # Unicode á
        "safe/area\u002e\u002e/"  # Unicode encoded dots
        "safe/\u202e\u0061\u0072\u0065\u0061"  # RLO character
    )

    # THIS TEST WILL FAIL: No Unicode path normalization
    for path in "${unicode_paths[@]}"; do
        run normalize_path_unicode "$path"
        [ "$status" -eq 0 ]

        # Should normalize to safe ASCII (THIS WILL FAIL)
        [[ ! "$output" =~ "\.\." ]]
    done
}

@test "security: Archive extraction path validation" {
    # Create malicious archive entries
    local archive_entries=(
        "../../../etc/passwd"
        "/etc/shadow"
        "../../restricted/sensitive.txt"
    )

    # THIS TEST WILL FAIL: No archive path validation
    for entry in "${archive_entries[@]}"; do
        run validate_archive_entry "$entry" "safe/extract"
        [ "$status" -ne 0 ]  # Should reject dangerous entries
    done
}

@test "security: Path length limits enforced" {
    # Create extremely long path (potential buffer overflow)
    LONG_PATH=$(printf 'a/%.0s' {1..1000})

    # THIS TEST WILL FAIL: No path length limits
    run validate_path_length "$LONG_PATH"
    [ "$status" -ne 0 ]  # Should reject too-long paths

    # Should report length issue (THIS WILL FAIL)
    [[ "$output" =~ "length" ]] || [[ "$output" =~ "too long" ]]
}

@test "security: Hidden file access prevention" {
    # Hidden/special files that shouldn't be accessed
    local hidden_files=(
        ".git/config"
        ".env"
        ".ssh/id_rsa"
        ".aws/credentials"
        ".npmrc"
        ".bashrc"
    )

    # THIS TEST WILL FAIL: No hidden file protection
    for file in "${hidden_files[@]}"; do
        run access_non_hidden_file "$file"
        [ "$status" -ne 0 ]  # Should block hidden file access
    done
}