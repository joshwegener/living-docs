#!/bin/bash
# security/input-sanitizer.sh - Input sanitization utilities

set -euo pipefail

# Validate adapter name (alphanumeric, dash, underscore only)
validate_adapter_name() {
    local name="${1:-}"

    if [[ -z "$name" ]]; then
        return 1
    fi

    # Check for path traversal attempts
    if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]]; then
        return 1
    fi

    # Only allow safe characters
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi

    # Reject command injection patterns
    if [[ "$name" =~ [\$\`\;\|\&\>\<\(\)\{\}] ]]; then
        return 1
    fi

    return 0
}

# Sanitize version string
sanitize_version() {
    local version="${1:-0.0.0}"

    # Remove any dangerous characters first
    version=$(echo "$version" | tr -cd '0-9v.\\-+')

    # Remove v prefix
    version="${version#v}"

    # Default if empty
    if [[ -z "$version" ]]; then
        echo "0.0.0"
        return
    fi

    # Extract clean semantic version
    if echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
        version=$(echo "$version" | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        echo "$version"
    elif echo "$version" | grep -qE '^[0-9]+\.[0-9]+'; then
        version=$(echo "$version" | grep -oE '^[0-9]+\.[0-9]+' | head -1)
        echo "${version}.0"
    elif echo "$version" | grep -qE '^[0-9]+'; then
        version=$(echo "$version" | grep -oE '^[0-9]+' | head -1)
        echo "${version}.0.0"
    else
        echo "0.0.0"
    fi
}

# Check file permissions
check_file_permissions() {
    local file="${1:-}"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Get octal permissions
    local perms
    if [[ "$(uname)" == "Darwin" ]]; then
        perms=$(stat -f "%OLp" "$file")
    else
        perms=$(stat -c "%a" "$file")
    fi

    # Warn if world-writable
    if [[ "$((perms & 2))" -ne 0 ]]; then
        echo "WARNING: File $file has insecure permissions ($perms)" >&2
        return 1
    fi

    return 0
}

# Escape regex special characters
escape_regex() {
    local input="${1:-}"
    printf '%s' "$input" | sed 's/[][\.|$(){}?+*^]/\\&/g'
}

# Sanitize path (prevent traversal)
sanitize_path() {
    local path="${1:-}"

    # Remove leading/trailing spaces
    path="${path#"${path%%[![:space:]]*}"}"
    path="${path%"${path##*[![:space:]]}"}"

    # Reject if contains traversal
    if [[ "$path" =~ \.\. ]]; then
        return 1
    fi

    # Must be within PROJECT_ROOT if set
    if [[ -n "${PROJECT_ROOT:-}" ]]; then
        local realpath_cmd="realpath"
        if ! command -v realpath &>/dev/null; then
            realpath_cmd="readlink -f"
        fi

        local abs_path
        abs_path=$($realpath_cmd "$path" 2>/dev/null) || return 1

        local abs_root
        abs_root=$($realpath_cmd "$PROJECT_ROOT" 2>/dev/null) || return 1

        if [[ "$abs_path" != "$abs_root"* ]]; then
            return 1
        fi
    fi

    echo "$path"
}