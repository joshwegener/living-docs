#!/usr/bin/env bash
# Checksum generation and verification functions for living-docs
# Provides SHA256-based integrity checking for files and directories

set -euo pipefail

# Generate SHA256 checksum for a single file
generate_checksum() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "ERROR: File not found: $file" >&2
        return 1
    fi

    # Use appropriate command based on OS
    if command -v sha256sum &>/dev/null; then
        # Linux
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        # macOS
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo "ERROR: No SHA256 tool available" >&2
        return 1
    fi
}

# Generate deterministic checksum for a directory
generate_directory_checksum() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        echo "ERROR: Directory does not exist: $dir" >&2
        return 1
    fi

    # Create sorted list of files with their checksums
    local temp_checksums
    temp_checksums=$(mktemp)

    # Find all files, sort them, and generate checksums
    find "$dir" -type f ! -name "*.sha256" 2>/dev/null | sort | while read -r file; do
        local checksum
        checksum=$(generate_checksum "$file")
        local relative_path="${file#$dir/}"
        echo "$checksum  $relative_path" >> "$temp_checksums"
    done

    # Generate final checksum of the checksums file
    local final_checksum
    final_checksum=$(generate_checksum "$temp_checksums")

    rm -f "$temp_checksums"
    echo "$final_checksum"
}

# Create a checksum file with proper format
create_checksum_file() {
    local file="$1"
    local output="${2:-$file.sha256}"

    # Handle directories
    if [[ -d "$file" ]]; then
        local checksum
        checksum=$(generate_directory_checksum "$file")
        echo "$checksum" > "$file/.checksum"
        echo "Created checksum file: $file/.checksum"
        return 0
    fi

    if [[ ! -f "$file" ]]; then
        echo "ERROR: File does not exist: $file" >&2
        return 1
    fi

    local checksum
    checksum=$(generate_checksum "$file")
    local filename
    filename=$(basename "$file")

    echo "$checksum  $filename" > "$output"
    echo "Created checksum file: $output"
}

# Verify a file against its checksum
verify_checksum() {
    local file="$1"
    local expected_checksum="${2:-}"

    if [[ ! -f "$file" ]]; then
        echo "ERROR: File does not exist: $file" >&2
        return 1
    fi

    # If no checksum provided, look for .sha256 file
    if [[ -z "$expected_checksum" ]]; then
        local checksum_file="$file.sha256"
        if [[ -f "$checksum_file" ]]; then
            expected_checksum=$(awk '{print $1}' "$checksum_file")
        else
            echo "ERROR: checksum file not found: $checksum_file" >&2
            return 1
        fi
    fi

    # Validate checksum format (64 hex characters)
    if ! [[ "$expected_checksum" =~ ^[a-f0-9]{64}$ ]]; then
        echo "ERROR: Invalid checksum format" >&2
        return 1
    fi

    local actual_checksum
    actual_checksum=$(generate_checksum "$file")

    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        echo "VALID"
        return 0
    else
        echo "INVALID: Checksum verification failed" >&2
        echo "Expected: $expected_checksum" >&2
        echo "Actual:   $actual_checksum" >&2
        return 1
    fi
}

# Verify directory checksum
verify_directory_checksum() {
    local dir="$1"
    local expected_checksum="${2:-}"

    if [[ ! -d "$dir" ]]; then
        echo "ERROR: Directory does not exist: $dir" >&2
        return 1
    fi

    # If no checksum provided, look for .checksum file
    if [[ -z "$expected_checksum" ]]; then
        local checksum_file="$dir/.checksum"
        if [[ -f "$checksum_file" ]]; then
            expected_checksum=$(cat "$checksum_file")
        else
            echo "ERROR: No checksum provided and no .checksum file found" >&2
            return 1
        fi
    fi

    local actual_checksum
    actual_checksum=$(generate_directory_checksum "$dir")

    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        return 0
    else
        echo "ERROR: Directory checksum verification failed" >&2
        return 1
    fi
}

# Validate checksum file format
validate_checksum_file_format() {
    local checksum_file="$1"

    if [[ ! -f "$checksum_file" ]]; then
        echo "ERROR: Checksum file does not exist: $checksum_file" >&2
        return 1
    fi

    # Check if file is empty
    if [[ ! -s "$checksum_file" ]]; then
        echo "ERROR: invalid format - file is empty" >&2
        return 1
    fi

    # Check if file contains valid checksum format
    while IFS= read -r line; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Check format: 64-char hex hash followed by two spaces and filename
        if ! [[ "$line" =~ ^[a-f0-9]{64}\ \ .+$ ]]; then
            echo "ERROR: invalid format" >&2
            return 1
        fi
    done < "$checksum_file"

    return 0
}

# Create checksums for multiple files
create_batch_checksums() {
    local output_file="$1"
    shift
    local files=("$@")

    > "$output_file"  # Clear or create output file

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local checksum
            checksum=$(generate_checksum "$file")
            local filename
            filename=$(basename "$file")
            echo "$checksum  $filename" >> "$output_file"
        else
            echo "WARNING: Skipping non-existent file: $file" >&2
        fi
    done

    echo "Created batch checksum file: $output_file"
}

# Verify multiple files from a checksum file
verify_batch_checksums() {
    local checksum_file="$1"
    local base_dir="${2:-.}"

    if [[ ! -f "$checksum_file" ]]; then
        echo "ERROR: Checksum file does not exist: $checksum_file" >&2
        return 1
    fi

    local failed=0
    while IFS='  ' read -r checksum filename; do
        # Skip empty lines
        [[ -z "$checksum" ]] && continue

        local file_path="$base_dir/$filename"
        if [[ -f "$file_path" ]]; then
            if ! verify_checksum "$file_path" "$checksum" 2>/dev/null; then
                echo "FAILED: $filename" >&2
                ((failed++))
            else
                echo "OK: $filename"
            fi
        else
            echo "MISSING: $filename" >&2
            ((failed++))
        fi
    done < "$checksum_file"

    if [[ $failed -gt 0 ]]; then
        echo "ERROR: $failed files failed verification" >&2
        return 1
    fi

    echo "All checksums verified successfully"
    return 0
}

# Export functions for use by other scripts
export -f generate_checksum
export -f generate_directory_checksum
export -f create_checksum_file
export -f verify_checksum
export -f verify_directory_checksum
export -f validate_checksum_file_format
export -f create_batch_checksums
export -f verify_batch_checksums