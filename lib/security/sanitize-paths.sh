#!/bin/bash
set -euo pipefail
# Secure path sanitization for adapter system

# Sanitize a path variable to prevent injection
sanitize_path() {
    local input="$1"
    local sanitized=""

    # Remove dangerous characters and patterns
    # Only allow alphanumeric, dash, underscore, forward slash, and dot
    sanitized=$(echo "$input" | tr -cd '[:alnum:]/_.-')

    # Prevent directory traversal
    sanitized=${sanitized//\.\.\/}
    sanitized=${sanitized//\.\.}

    # Remove leading slashes to prevent absolute paths
    sanitized=${sanitized#/}

    # Limit length to prevent buffer issues
    if [[ ${#sanitized} -gt 256 ]]; then
        sanitized=${sanitized:0:256}
    fi

    # Default to safe value if empty
    if [[ -z "$sanitized" ]]; then
        sanitized="invalid"
    fi

    echo "$sanitized"
}

# Validate path variable name
validate_path_variable() {
    local var_name="$1"

    case "$var_name" in
        SCRIPTS_PATH|SPECS_PATH|MEMORY_PATH|AI_PATH|PROJECT_ROOT)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Get sanitized path value
get_sanitized_path() {
    local var_name="$1"
    local default_value="$2"

    if ! validate_path_variable "$var_name"; then
        echo "Error: Invalid path variable name: $var_name" >&2
        echo "$default_value"
        return 1
    fi

    local value="${!var_name:-$default_value}"
    sanitize_path "$value"
}

# Export functions
export -f sanitize_path
export -f validate_path_variable
export -f get_sanitized_path