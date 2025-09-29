#!/bin/bash
# checksum.sh - Checksum verification for downloaded files
# Purpose: Verify file integrity using checksums
# Usage: source lib/security/checksum.sh

set -euo pipefail

# Verify checksum of file
verify_checksum() {
    local file="${1:-}"
    local expected="${2:-}"
    local algorithm="${3:-sha256}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }
    [ -z "$expected" ] && { echo "Error: No expected checksum" >&2; return 2; }
    [ ! -f "$file" ] && { echo "Error: File not found" >&2; return 3; }

    local actual
    case "$algorithm" in
        sha256)
            if command -v shasum >/dev/null 2>&1; then
                actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
            elif command -v sha256sum >/dev/null 2>&1; then
                actual=$(sha256sum "$file" | cut -d' ' -f1)
            else
                echo "Error: No SHA256 tool available" >&2
                return 4
            fi
            ;;
        md5)
            if command -v md5sum >/dev/null 2>&1; then
                actual=$(md5sum "$file" | cut -d' ' -f1)
            elif command -v md5 >/dev/null 2>&1; then
                actual=$(md5 -q "$file")
            else
                echo "Error: No MD5 tool available" >&2
                return 4
            fi
            ;;
        *)
            echo "Error: Unsupported algorithm: $algorithm" >&2
            return 5
            ;;
    esac

    if [ "$actual" = "$expected" ]; then
        return 0
    else
        echo "Error: Checksum mismatch" >&2
        echo "  Expected: $expected" >&2
        echo "  Actual:   $actual" >&2
        return 6
    fi
}

# Export function
export -f verify_checksum