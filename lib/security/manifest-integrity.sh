#!/bin/bash
set -euo pipefail
# Manifest integrity verification for adapter system

# Generate checksum for a manifest
generate_manifest_checksum() {
    local manifest_file="$1"

    if [[ ! -f "$manifest_file" ]]; then
        echo "Error: Manifest not found: $manifest_file" >&2
        return 1
    fi

    # Use SHA256 for integrity
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$manifest_file" | cut -d' ' -f1
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$manifest_file" | cut -d' ' -f1
    else
        echo "Error: No SHA256 tool available" >&2
        return 1
    fi
}

# Verify manifest integrity
verify_manifest_integrity() {
    local manifest_file="$1"
    local expected_checksum="${2:-}"

    if [[ ! -f "$manifest_file" ]]; then
        echo "Error: Manifest not found: $manifest_file" >&2
        return 1
    fi

    # Calculate current checksum
    local current_checksum
    current_checksum=$(generate_manifest_checksum "$manifest_file")

    if [[ -z "$expected_checksum" ]]; then
        # No expected checksum, just return the current one
        echo "$current_checksum"
        return 0
    fi

    # Verify against expected
    if [[ "$current_checksum" != "$expected_checksum" ]]; then
        echo "Error: Manifest integrity check failed!" >&2
        echo "  Expected: $expected_checksum" >&2
        echo "  Got:      $current_checksum" >&2
        return 1
    fi

    return 0
}

# Store manifest checksum
store_manifest_checksum() {
    local manifest_file="$1"
    local checksum_file="${manifest_file}.sha256"

    local checksum
    checksum=$(generate_manifest_checksum "$manifest_file")

    echo "$checksum" > "$checksum_file"
    echo "Stored checksum: $checksum"
}

# Verify manifest hasn't been tampered with
check_manifest_tampering() {
    local manifest_file="$1"
    local checksum_file="${manifest_file}.sha256"

    if [[ ! -f "$checksum_file" ]]; then
        echo "Warning: No checksum file found for manifest" >&2
        return 2  # No checksum to verify against
    fi

    local expected_checksum
    expected_checksum=$(cat "$checksum_file")

    verify_manifest_integrity "$manifest_file" "$expected_checksum"
}

# Validate manifest JSON structure
validate_manifest_structure() {
    local manifest_file="$1"

    if ! command -v jq >/dev/null 2>&1; then
        echo "Warning: jq not available, skipping JSON validation" >&2
        return 2
    fi

    # Check if valid JSON
    if ! jq empty "$manifest_file" 2>/dev/null; then
        echo "Error: Invalid JSON in manifest" >&2
        return 1
    fi

    # Check required fields
    local required_fields=("adapter" "version" "files" "timestamp")
    for field in "${required_fields[@]}"; do
        if ! jq -e ".${field}" "$manifest_file" >/dev/null 2>&1; then
            echo "Error: Missing required field: $field" >&2
            return 1
        fi
    done

    return 0
}

# Sign manifest with GPG (if available)
sign_manifest() {
    local manifest_file="$1"
    local key_id="${2:-}"

    if ! command -v gpg >/dev/null 2>&1; then
        echo "Warning: GPG not available, skipping signature" >&2
        return 2
    fi

    local gpg_opts=""
    if [[ -n "$key_id" ]]; then
        gpg_opts="--default-key $key_id"
    fi

    gpg $gpg_opts --detach-sign --armor "$manifest_file"
    echo "Manifest signed: ${manifest_file}.asc"
}

# Verify manifest signature
verify_manifest_signature() {
    local manifest_file="$1"
    local signature_file="${manifest_file}.asc"

    if [[ ! -f "$signature_file" ]]; then
        echo "Warning: No signature file found" >&2
        return 2
    fi

    if ! command -v gpg >/dev/null 2>&1; then
        echo "Warning: GPG not available, cannot verify signature" >&2
        return 2
    fi

    gpg --verify "$signature_file" "$manifest_file"
}

# Export functions
export -f generate_manifest_checksum
export -f verify_manifest_integrity
export -f store_manifest_checksum
export -f check_manifest_tampering
export -f validate_manifest_structure
export -f sign_manifest
export -f verify_manifest_signature