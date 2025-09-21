#!/usr/bin/env bats

# Test file for checksum verification functionality
# This test drives TDD implementation of lib/security/checksum.sh

load test_helper

setup() {
    # Call parent setup
    export TEST_DIR="$(mktemp -d)"
    export LIVING_DOCS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    export PATH="$LIVING_DOCS_ROOT/lib:$PATH"
    cd "$TEST_DIR" || exit 1

    # Source the checksum library (will fail initially)
    source "$LIVING_DOCS_ROOT/lib/security/checksum.sh" 2>/dev/null || true

    # Create test files
    echo "test content for file1" > test_file1.txt
    echo "different content for file2" > test_file2.txt
    echo "binary content" > test_binary_file.bin

    # Create a directory with multiple files
    mkdir -p test_dir
    echo "content in dir file1" > test_dir/file1.txt
    echo "content in dir file2" > test_dir/file2.txt
}

teardown() {
    cd "$LIVING_DOCS_ROOT" || exit 1
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Test: generate_checksum function exists and works
@test "generate_checksum function generates SHA256 checksum for single file" {
    run generate_checksum test_file1.txt
    [ "$status" -eq 0 ]
    [ "${#lines[0]}" -eq 64 ]  # SHA256 hash length
    [[ "${lines[0]}" =~ ^[a-f0-9]{64}$ ]]  # Valid hex string
}

@test "generate_checksum function generates different checksums for different files" {
    run generate_checksum test_file1.txt
    checksum1="$output"

    run generate_checksum test_file2.txt
    checksum2="$output"

    [ "$checksum1" != "$checksum2" ]
}

@test "generate_checksum function handles binary files" {
    run generate_checksum test_binary_file.bin
    [ "$status" -eq 0 ]
    [ "${#lines[0]}" -eq 64 ]
}

@test "generate_checksum function fails for non-existent file" {
    run generate_checksum non_existent_file.txt
    [ "$status" -ne 0 ]
    [[ "$output" == *"File not found"* ]] || [[ "$output" == *"No such file"* ]]
}

# Test: generate_directory_checksum function
@test "generate_directory_checksum function generates checksum for directory" {
    run generate_directory_checksum test_dir
    [ "$status" -eq 0 ]
    [ "${#lines[0]}" -eq 64 ]  # SHA256 hash length
}

@test "generate_directory_checksum function is deterministic" {
    run generate_directory_checksum test_dir
    checksum1="$output"

    run generate_directory_checksum test_dir
    checksum2="$output"

    [ "$checksum1" = "$checksum2" ]
}

@test "generate_directory_checksum function changes when directory content changes" {
    run generate_directory_checksum test_dir
    checksum1="$output"

    echo "new content" > test_dir/new_file.txt

    run generate_directory_checksum test_dir
    checksum2="$output"

    [ "$checksum1" != "$checksum2" ]
}

@test "generate_directory_checksum function fails for non-existent directory" {
    run generate_directory_checksum non_existent_dir
    [ "$status" -ne 0 ]
}

# Test: create_checksum_file function
@test "create_checksum_file function creates checksum file with proper format" {
    run create_checksum_file test_file1.txt
    [ "$status" -eq 0 ]
    assert_file_exists "test_file1.txt.sha256"

    # Verify file format: checksum filename
    content=$(cat test_file1.txt.sha256)
    [[ "$content" =~ ^[a-f0-9]{64}[[:space:]]+test_file1\.txt$ ]]
}

@test "create_checksum_file function creates checksum file for directory" {
    run create_checksum_file test_dir
    [ "$status" -eq 0 ]
    assert_file_exists "test_dir.sha256"
}

@test "create_checksum_file function overwrites existing checksum file" {
    echo "fake checksum content" > test_file1.txt.sha256
    run create_checksum_file test_file1.txt
    [ "$status" -eq 0 ]

    content=$(cat test_file1.txt.sha256)
    [[ "$content" != "fake checksum content" ]]
    [[ "$content" =~ ^[a-f0-9]{64}[[:space:]]+test_file1\.txt$ ]]
}

# Test: verify_checksum function
@test "verify_checksum function verifies valid checksum" {
    # Create checksum file first
    generate_checksum test_file1.txt > test_file1.txt.sha256
    echo "test_file1.txt" >> test_file1.txt.sha256

    run verify_checksum test_file1.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"VALID"* ]] || [[ "$output" == *"OK"* ]]
}

@test "verify_checksum function detects invalid checksum" {
    # Create incorrect checksum file
    echo "0000000000000000000000000000000000000000000000000000000000000000 test_file1.txt" > test_file1.txt.sha256

    run verify_checksum test_file1.txt
    [ "$status" -ne 0 ]
    [[ "$output" == *"INVALID"* ]] || [[ "$output" == *"FAILED"* ]]
}

@test "verify_checksum function detects file modification" {
    # Create valid checksum
    create_checksum_file test_file1.txt

    # Modify the file
    echo "modified content" > test_file1.txt

    run verify_checksum test_file1.txt
    [ "$status" -ne 0 ]
    [[ "$output" == *"INVALID"* ]] || [[ "$output" == *"FAILED"* ]]
}

@test "verify_checksum function fails when checksum file missing" {
    run verify_checksum test_file1.txt
    [ "$status" -ne 0 ]
    [[ "$output" == *"checksum file not found"* ]] || [[ "$output" == *"No such file"* ]]
}

# Test: verify_directory_checksum function
@test "verify_directory_checksum function verifies valid directory checksum" {
    create_checksum_file test_dir

    run verify_directory_checksum test_dir
    [ "$status" -eq 0 ]
    [[ "$output" == *"VALID"* ]] || [[ "$output" == *"OK"* ]]
}

@test "verify_directory_checksum function detects directory modification" {
    create_checksum_file test_dir

    # Modify directory content
    echo "new file content" > test_dir/modified_file.txt

    run verify_directory_checksum test_dir
    [ "$status" -ne 0 ]
    [[ "$output" == *"INVALID"* ]] || [[ "$output" == *"FAILED"* ]]
}

# Test: validate_checksum_file_format function
@test "validate_checksum_file_format function accepts valid format" {
    echo "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890 test_file.txt" > valid_checksum.sha256

    run validate_checksum_file_format valid_checksum.sha256
    [ "$status" -eq 0 ]
}

@test "validate_checksum_file_format function rejects invalid hash length" {
    echo "shortHash test_file.txt" > invalid_checksum.sha256

    run validate_checksum_file_format invalid_checksum.sha256
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid format"* ]] || [[ "$output" == *"malformed"* ]]
}

@test "validate_checksum_file_format function rejects non-hex characters" {
    echo "g1b2c3d4e5f6789012345678901234567890123456789012345678901234567890 test_file.txt" > invalid_checksum.sha256

    run validate_checksum_file_format invalid_checksum.sha256
    [ "$status" -ne 0 ]
}

@test "validate_checksum_file_format function rejects missing filename" {
    echo "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890" > invalid_checksum.sha256

    run validate_checksum_file_format invalid_checksum.sha256
    [ "$status" -ne 0 ]
}

@test "validate_checksum_file_format function rejects empty file" {
    touch empty_checksum.sha256

    run validate_checksum_file_format empty_checksum.sha256
    [ "$status" -ne 0 ]
}

# Test: batch checksum operations
@test "create_batch_checksums function creates checksums for multiple files" {
    run create_batch_checksums test_file1.txt test_file2.txt test_binary_file.bin
    [ "$status" -eq 0 ]
    assert_file_exists "test_file1.txt.sha256"
    assert_file_exists "test_file2.txt.sha256"
    assert_file_exists "test_binary_file.bin.sha256"
}

@test "verify_batch_checksums function verifies multiple files" {
    create_batch_checksums test_file1.txt test_file2.txt

    run verify_batch_checksums test_file1.txt test_file2.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"All checksums valid"* ]] || [[ "$output" == *"VALID"* ]]
}

@test "verify_batch_checksums function detects when one file is invalid" {
    create_batch_checksums test_file1.txt test_file2.txt

    # Corrupt one file
    echo "corrupted" > test_file1.txt

    run verify_batch_checksums test_file1.txt test_file2.txt
    [ "$status" -ne 0 ]
    [[ "$output" == *"test_file1.txt"* ]]
}

# Test: error handling
@test "checksum functions handle special characters in filenames" {
    echo "test content" > "file with spaces.txt"
    echo "test content" > "file-with-dashes.txt"
    echo "test content" > "file_with_underscores.txt"

    run create_checksum_file "file with spaces.txt"
    [ "$status" -eq 0 ]

    run create_checksum_file "file-with-dashes.txt"
    [ "$status" -eq 0 ]

    run create_checksum_file "file_with_underscores.txt"
    [ "$status" -eq 0 ]
}

@test "checksum functions handle very large files" {
    # Create a larger test file (1MB)
    dd if=/dev/zero of=large_file.bin bs=1024 count=1024 2>/dev/null

    run generate_checksum large_file.bin
    [ "$status" -eq 0 ]
    [ "${#lines[0]}" -eq 64 ]
}

@test "checksum functions are consistent across multiple runs" {
    run generate_checksum test_file1.txt
    checksum1="$output"

    # Wait a moment and generate again
    sleep 1
    run generate_checksum test_file1.txt
    checksum2="$output"

    [ "$checksum1" = "$checksum2" ]
}