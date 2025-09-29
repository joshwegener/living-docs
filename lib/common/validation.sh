#!/bin/bash
set -euo pipefail
# Common Validation Library for living-docs
# Provides consistent input validation and sanitization

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/errors.sh" 2>/dev/null || true

# Validate string is not empty
validate_not_empty() {
    local value="$1"
    local name="${2:-value}"

    if [[ -z "${value:-}" ]]; then
        die "$name cannot be empty" "$E_INVALID_INPUT"
    fi
}

# Validate string matches pattern
validate_pattern() {
    local value="$1"
    local pattern="$2"
    local name="${3:-value}"

    if ! [[ "$value" =~ $pattern ]]; then
        die "$name does not match required pattern: $pattern" "$E_VALIDATION"
    fi
}

# Validate integer
validate_integer() {
    local value="$1"
    local name="${2:-value}"

    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        die "$name must be an integer: $value" "$E_INVALID_INPUT"
    fi
}

# Validate positive integer
validate_positive_integer() {
    local value="$1"
    local name="${2:-value}"

    validate_integer "$value" "$name"

    if [[ "$value" -le 0 ]]; then
        die "$name must be positive: $value" "$E_INVALID_INPUT"
    fi
}

# Validate number in range
validate_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local name="${4:-value}"

    validate_integer "$value" "$name"

    if [[ "$value" -lt "$min" ]] || [[ "$value" -gt "$max" ]]; then
        die "$name must be between $min and $max: $value" "$E_INVALID_INPUT"
    fi
}

# Validate boolean
validate_boolean() {
    local value="$1"
    local name="${2:-value}"

    case "${value,,}" in
        true|false|yes|no|1|0|on|off)
            return 0
            ;;
        *)
            die "$name must be a boolean value: $value" "$E_INVALID_INPUT"
            ;;
    esac
}

# Normalize boolean to true/false
normalize_boolean() {
    local value="$1"

    case "${value,,}" in
        true|yes|1|on)
            echo "true"
            ;;
        false|no|0|off)
            echo "false"
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Validate email
validate_email() {
    local email="$1"
    local pattern='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if ! [[ "$email" =~ $pattern ]]; then
        die "Invalid email address: $email" "$E_INVALID_INPUT"
    fi
}

# Validate URL
validate_url() {
    local url="$1"
    local pattern='^(https?|ftp)://[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})(:[0-9]+)?(/.*)?$'

    if ! [[ "$url" =~ $pattern ]]; then
        die "Invalid URL: $url" "$E_INVALID_INPUT"
    fi
}

# Validate semantic version
validate_semver() {
    local version="$1"
    local pattern='^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$'

    if ! [[ "$version" =~ $pattern ]]; then
        die "Invalid semantic version: $version" "$E_INVALID_INPUT"
    fi
}

# Validate adapter name
validate_adapter_name() {
    local name="$1"
    local pattern='^[a-z][a-z0-9-]*$'

    validate_not_empty "$name" "Adapter name"

    if ! [[ "$name" =~ $pattern ]]; then
        die "Invalid adapter name. Must start with lowercase letter and contain only lowercase letters, numbers, and hyphens: $name" "$E_INVALID_INPUT"
    fi

    if [[ ${#name} -gt 50 ]]; then
        die "Adapter name too long (max 50 characters): $name" "$E_INVALID_INPUT"
    fi

    echo "$name"
}

# Validate command name
validate_command_name() {
    local name="$1"
    local pattern='^[a-z][a-z0-9_-]*$'

    validate_not_empty "$name" "Command name"

    if ! [[ "$name" =~ $pattern ]]; then
        die "Invalid command name. Must start with lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens: $name" "$E_INVALID_INPUT"
    fi

    echo "$name"
}

# Validate prefix
validate_prefix() {
    local prefix="$1"
    local pattern='^[a-z][a-z0-9_]*$'

    validate_not_empty "$prefix" "Prefix"

    if ! [[ "$prefix" =~ $pattern ]]; then
        die "Invalid prefix. Must start with lowercase letter and contain only lowercase letters, numbers, and underscores: $prefix" "$E_INVALID_INPUT"
    fi

    if [[ ${#prefix} -gt 20 ]]; then
        die "Prefix too long (max 20 characters): $prefix" "$E_INVALID_INPUT"
    fi

    echo "$prefix"
}

# Validate JSON
validate_json() {
    local json="$1"
    local name="${2:-JSON}"

    if command -v jq &>/dev/null; then
        if ! echo "$json" | jq empty 2>/dev/null; then
            die "Invalid $name" "$E_INVALID_INPUT"
        fi
    else
        # Basic check without jq
        if ! [[ "$json" =~ ^\{.*\}$|^\[.*\]$ ]]; then
            die "Invalid $name (appears malformed)" "$E_INVALID_INPUT"
        fi
    fi
}

# Sanitize string (remove dangerous characters)
sanitize_string() {
    local input="$1"
    local allowed_chars="${2:-[:alnum:][:space:]._-}"

    # Remove characters not in allowed set
    echo "$input" | tr -cd "$allowed_chars"
}

# Escape string for shell
escape_shell() {
    local input="$1"
    printf '%q' "$input"
}

# Escape string for regex
escape_regex() {
    local input="$1"
    echo "$input" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Validate enum value
validate_enum() {
    local value="$1"
    local name="$2"
    shift 2
    local valid_values=("$@")

    for valid in "${valid_values[@]}"; do
        if [[ "$value" == "$valid" ]]; then
            return 0
        fi
    done

    die "$name must be one of: ${valid_values[*]}" "$E_INVALID_INPUT"
}

# Export functions
export -f validate_not_empty
export -f validate_pattern
export -f validate_integer
export -f validate_positive_integer
export -f validate_range
export -f validate_boolean
export -f normalize_boolean
export -f validate_email
export -f validate_url
export -f validate_semver
export -f validate_adapter_name
export -f validate_command_name
export -f validate_prefix
export -f validate_json
export -f sanitize_string
export -f escape_shell
export -f escape_regex
export -f validate_enum