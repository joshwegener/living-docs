#!/bin/bash
# Input validation and sanitization functions for security
set -euo pipefail

# Validate adapter name format (alphanumeric with hyphens only)
validate_adapter_name() {
    local name="$1"

    # Check for empty
    if [[ -z "$name" ]]; then
        echo "Error: Adapter name cannot be empty" >&2
        return 1
    fi

    # Check length
    if [[ ${#name} -gt 50 ]]; then
        echo "Error: Adapter name too long (max 50 chars)" >&2
        return 1
    fi

    # Check format: lowercase letters, numbers, hyphens only
    # Must start with letter, no consecutive hyphens
    if ! [[ "$name" =~ ^[a-z]([a-z0-9]|-[a-z0-9])*$ ]]; then
        echo "Error: Invalid adapter name format" >&2
        echo "Must use lowercase letters, numbers, hyphens only" >&2
        echo "Must start with letter, no consecutive hyphens" >&2
        return 1
    fi

    # Check for path traversal attempts
    if [[ "$name" == *".."* ]] || [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]]; then
        echo "Error: Path traversal detected in adapter name" >&2
        return 1
    fi

    echo "$name"
    return 0
}

# Sanitize file paths - remove dangerous characters
sanitize_path() {
    local path="$1"

    # Remove leading/trailing whitespace
    path="$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    # Check for null bytes
    if [[ "$path" == *$'\0'* ]]; then
        echo "Error: Null byte in path" >&2
        return 1
    fi

    # Remove path traversal sequences
    path="${path//\.\.\/}"
    path="${path//\.\.\\}"

    # Remove absolute path prefixes
    path="${path#/}"
    path="${path#\\}"

    # Remove dangerous characters for shell expansion
    path="${path//\$/}"
    path="${path//\`/}"
    path="${path//\(/}"
    path="${path//\)/}"
    path="${path//\;/}"
    path="${path//\&/}"
    path="${path//\|/}"
    path="${path//\>/}"
    path="${path//\</}"
    path="${path//\*/}"
    path="${path//\?/}"
    path="${path//\[/}"
    path="${path//\]/}"
    path="${path//\{/}"
    path="${path//\}/}"
    path="${path//\~/}"
    path="${path//\!/}"

    echo "$path"
}

# Validate version format
validate_version() {
    local version="$1"

    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?$ ]]; then
        echo "Error: Invalid version format (expected: x.y.z or x.y.z-tag)" >&2
        return 1
    fi

    echo "$version"
}

# Validate prefix format
validate_prefix() {
    local prefix="$1"

    # Check format: lowercase letters, numbers, underscores only
    if ! [[ "$prefix" =~ ^[a-z][a-z0-9_]*$ ]]; then
        echo "Error: Invalid prefix format" >&2
        echo "Must start with letter, use only lowercase letters, numbers, underscores" >&2
        return 1
    fi

    # Check length
    if [[ ${#prefix} -gt 20 ]]; then
        echo "Error: Prefix too long (max 20 chars)" >&2
        return 1
    fi

    echo "$prefix"
}

# Escape string for safe use in JSON
escape_json() {
    local str="$1"

    # Escape special JSON characters
    str="${str//\\/\\\\}"  # Backslash
    str="${str//\"/\\\"}"  # Quote
    str="${str//$'\n'/\\n}" # Newline
    str="${str//$'\r'/\\r}" # Carriage return
    str="${str//$'\t'/\\t}" # Tab

    echo "$str"
}

# Escape string for safe use in AWK
escape_awk() {
    local str="$1"

    # Escape special AWK characters
    str="${str//\\/\\\\}"  # Backslash
    str="${str//\"/\\\"}"  # Quote
    str="${str//\$/\\\$}"  # Dollar
    str="${str//\//\\/}"   # Forward slash

    echo "$str"
}

# Check if path is safe (no symlinks, within project)
check_safe_path() {
    local path="$1"
    local base="${2:-$(pwd)}"

    # Resolve to absolute path
    local abs_path
    abs_path="$(cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")" || {
        echo "Error: Invalid path" >&2
        return 1
    }

    # Check if within base directory
    if ! [[ "$abs_path" == "$base"* ]]; then
        echo "Error: Path outside project directory" >&2
        return 1
    fi

    # Check for symlinks
    if [[ -L "$path" ]]; then
        echo "Error: Symlinks not allowed" >&2
        return 1
    fi

    return 0
}

# Export functions
export -f validate_adapter_name
export -f sanitize_path
export -f validate_version
export -f validate_prefix
export -f escape_json
export -f escape_awk
export -f check_safe_path