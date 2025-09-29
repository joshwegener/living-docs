#!/bin/bash
# gpg.sh - GPG signature verification for updates
# Purpose: Verify GPG signatures on downloaded updates
# Usage: source lib/security/gpg.sh

set -euo pipefail

# Verify GPG signature on file
verify_gpg_signature() {
    local file="${1:-}"
    local signature="${2:-}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }
    [ -z "$signature" ] && { echo "Error: No signature specified" >&2; return 2; }
    [ ! -f "$file" ] && { echo "Error: File not found" >&2; return 3; }

    # Check if GPG is available
    if ! command -v gpg >/dev/null 2>&1; then
        echo "Error: GPG not installed" >&2
        return 4
    fi

    # Verify signature
    if [ -f "$signature" ]; then
        gpg --verify "$signature" "$file" 2>/dev/null || {
            echo "Error: Signature verification failed" >&2
            return 5
        }
    else
        echo "Error: Signature file not found" >&2
        return 6
    fi

    return 0
}

# Export function
export -f verify_gpg_signature