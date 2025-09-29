#!/bin/bash
# path-traversal.sh - Path traversal prevention and validation
# Purpose: Prevent directory traversal and path-based attacks
# Usage: source lib/security/path-traversal.sh

set -euo pipefail

# Path security constants
readonly MAX_PATH_LENGTH=4096
readonly MAX_SYMLINK_DEPTH=5

# Resolve safe path (prevent traversal)
resolve_safe_path() {
    local input_path="${1:-}"
    local base_dir="${2:-$(pwd)}"

    [ -z "$input_path" ] && { echo "Error: No path provided" >&2; return 1; }
    [ -z "$base_dir" ] && { echo "Error: No base directory" >&2; return 2; }

    # Remove any .. sequences
    if [[ "$input_path" =~ \.\. ]]; then
        echo "Error: Path traversal detected" >&2
        return 3
    fi

    # Get absolute paths
    local abs_base
    abs_base=$(cd "$base_dir" 2>/dev/null && pwd) || {
        echo "Error: Invalid base directory" >&2
        return 4
    }

    # Resolve the path
    local resolved_path="${abs_base}/${input_path#/}"

    # Verify it's under base directory
    if [[ "$resolved_path" != "$abs_base"* ]]; then
        echo "Error: Path escapes base directory" >&2
        return 5
    fi

    echo "$resolved_path"
    return 0
}

# Access file safely (prevent symlink attacks)
access_file_safely() {
    local file_path="${1:-}"

    [ -z "$file_path" ] && { echo "Error: No file path provided" >&2; return 1; }

    # Check if it's a symlink
    if [ -L "$file_path" ]; then
        # Resolve symlink target
        local target
        target=$(readlink "$file_path") || {
            echo "Error: Cannot resolve symlink" >&2
            return 2
        }

        # Check if target is in restricted area
        if [[ "$target" =~ ^/ ]]; then
            # Absolute path - check if it's safe
            if [[ "$target" =~ (/etc/|/root/|/var/|/sys/|/proc/) ]]; then
                echo "Error: Symlink points to restricted area" >&2
                return 3
            fi
        fi
    fi

    # Access the file
    if [ -r "$file_path" ]; then
        cat "$file_path"
        return 0
    else
        echo "Error: Cannot read file" >&2
        return 4
    fi
}

# Validate relative path only
validate_relative_path() {
    local path="${1:-}"

    [ -z "$path" ] && { echo "Error: No path provided" >&2; return 1; }

    # Check for absolute paths
    if [[ "$path" =~ ^/ ]] || [[ "$path" =~ ^[a-zA-Z]: ]]; then
        echo "Error: Absolute path not allowed" >&2
        return 2
    fi

    # Check for file:// protocol
    if [[ "$path" =~ ^file:// ]]; then
        echo "Error: File protocol not allowed" >&2
        return 3
    fi

    return 0
}

# Decode and validate URL encoded paths
decode_and_validate_path() {
    local encoded_path="${1:-}"

    [ -z "$encoded_path" ] && { echo "Error: No path provided" >&2; return 1; }

    # URL decode
    local decoded_path
    decoded_path=$(printf '%b' "${encoded_path//%/\\x}")

    # Check for traversal after decoding
    if [[ "$decoded_path" =~ \.\. ]]; then
        echo "Error: Encoded path traversal detected" >&2
        return 2
    fi

    # Check for double encoding
    local double_decoded
    double_decoded=$(printf '%b' "${decoded_path//%/\\x}")
    if [[ "$double_decoded" =~ \.\. ]] && [[ "$double_decoded" != "$decoded_path" ]]; then
        echo "Error: Double-encoded path traversal detected" >&2
        return 3
    fi

    echo "$decoded_path"
    return 0
}

# Check for null bytes in path
validate_path_no_null() {
    local path="${1:-}"

    [ -z "$path" ] && { echo "Error: No path provided" >&2; return 1; }

    # Check for null bytes
    if [[ "$path" =~ $'\x00' ]]; then
        echo "Error: Null byte in path" >&2
        return 2
    fi

    # Check for URL-encoded null
    if [[ "$path" =~ %00 ]]; then
        echo "Error: Encoded null byte in path" >&2
        return 3
    fi

    return 0
}

# Validate Unix-only paths (reject Windows paths)
validate_unix_path() {
    local path="${1:-}"

    [ -z "$path" ] && { echo "Error: No path provided" >&2; return 1; }

    # Check for Windows path patterns
    if [[ "$path" =~ \\ ]] || [[ "$path" =~ ^[A-Za-z]: ]]; then
        echo "Error: Windows path not allowed" >&2
        return 2
    fi

    # Check for UNC paths
    if [[ "$path" =~ ^\\\\|^// ]]; then
        echo "Error: UNC path not allowed" >&2
        return 3
    fi

    # Check for Windows reserved names
    local reserved="CON PRN AUX NUL COM1 COM2 COM3 COM4 LPT1 LPT2 LPT3"
    local basename="${path##*/}"
    basename="${basename%%.*}"

    for name in $reserved; do
        if [[ "${basename^^}" == "$name" ]]; then
            echo "Error: Windows reserved name" >&2
            return 4
        fi
    done

    return 0
}

# Prevent directory listing attempts
prevent_directory_listing() {
    local path="${1:-}"

    [ -z "$path" ] && path="."

    # Check for directory traversal patterns
    case "$path" in
        .|..|/|~/|./)
            echo "Error: Directory listing not allowed" >&2
            return 1
            ;;
        ../)
            echo "Error: Parent directory access not allowed" >&2
            return 2
            ;;
    esac

    return 0
}

# Enforce chroot jail
enforce_jail() {
    local requested_path="${1:-}"
    local jail_root="${JAIL_ROOT:-$(pwd)}"

    [ -z "$requested_path" ] && { echo "Error: No path provided" >&2; return 1; }

    # Get absolute path of jail
    local abs_jail
    abs_jail=$(cd "$jail_root" 2>/dev/null && pwd) || {
        echo "Error: Invalid jail root" >&2
        return 2
    }

    # Resolve requested path
    local abs_requested="${abs_jail}/${requested_path#/}"

    # Ensure it's within jail
    if [[ "$abs_requested" != "$abs_jail"* ]]; then
        echo "Error: Path escapes jail" >&2
        return 3
    fi

    echo "$abs_requested"
    return 0
}

# Normalize Unicode in paths
normalize_path_unicode() {
    local path="${1:-}"

    [ -z "$path" ] && { echo "Error: No path provided" >&2; return 1; }

    # Remove Unicode direction markers
    local normalized
    normalized=$(echo "$path" | tr -d '\u202e\u202d\u202c\u202b\u202a')

    # Normalize Unicode dots and slashes
    normalized="${normalized//․/.}"  # Unicode dot to ASCII
    normalized="${normalized//⁄/\/}" # Unicode slash to ASCII

    # Check for remaining traversal
    if [[ "$normalized" =~ \.\. ]]; then
        echo "Error: Unicode path traversal detected" >&2
        return 2
    fi

    echo "$normalized"
    return 0
}

# Validate archive entry paths
validate_archive_entry() {
    local entry_path="${1:-}"
    local extract_dir="${2:-$(pwd)}"

    [ -z "$entry_path" ] && { echo "Error: No entry path provided" >&2; return 1; }

    # Check for absolute paths
    if [[ "$entry_path" =~ ^/ ]]; then
        echo "Error: Absolute path in archive" >&2
        return 2
    fi

    # Check for traversal
    if [[ "$entry_path" =~ \.\. ]]; then
        echo "Error: Path traversal in archive" >&2
        return 3
    fi

    # Verify extraction path
    local full_path="${extract_dir}/${entry_path}"
    local abs_extract
    abs_extract=$(cd "$extract_dir" 2>/dev/null && pwd) || {
        echo "Error: Invalid extraction directory" >&2
        return 4
    }

    # Ensure it stays within extraction directory
    if [[ "$full_path" != "$abs_extract"* ]]; then
        echo "Error: Archive entry escapes extraction directory" >&2
        return 5
    fi

    return 0
}

# Validate path length
validate_path_length() {
    local path="${1:-}"

    [ -z "$path" ] && { echo "Error: No path provided" >&2; return 1; }

    if [ ${#path} -gt $MAX_PATH_LENGTH ]; then
        echo "Error: Path too long (${#path} > $MAX_PATH_LENGTH)" >&2
        return 2
    fi

    return 0
}

# Check for hidden file access
access_non_hidden_file() {
    local file_path="${1:-}"

    [ -z "$file_path" ] && { echo "Error: No file path provided" >&2; return 1; }

    # Check each component of the path
    IFS='/' read -ra parts <<< "$file_path"
    for part in "${parts[@]}"; do
        if [[ "$part" =~ ^\. ]] && [[ "$part" != "." ]] && [[ "$part" != ".." ]]; then
            echo "Error: Access to hidden file/directory denied: $part" >&2
            return 2
        fi
    done

    # Special check for sensitive hidden files
    local sensitive_patterns=(".git" ".env" ".ssh" ".aws" ".npmrc" ".bashrc" ".zshrc" ".config")
    for pattern in "${sensitive_patterns[@]}"; do
        if [[ "$file_path" =~ $pattern ]]; then
            echo "Error: Access to sensitive file denied" >&2
            return 3
        fi
    done

    return 0
}

# Export functions
export -f resolve_safe_path
export -f access_file_safely
export -f validate_relative_path
export -f decode_and_validate_path
export -f validate_path_no_null
export -f validate_unix_path
export -f prevent_directory_listing
export -f enforce_jail
export -f normalize_path_unicode
export -f validate_archive_entry
export -f validate_path_length
export -f access_non_hidden_file