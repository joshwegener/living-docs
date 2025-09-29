#!/usr/bin/env bash
set -euo pipefail
# Common Validation Functions for living-docs
# Provides unified input validation across all scripts

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh" 2>/dev/null || true

# Validate email address
validate_email() {
    local email="${1:-}"
    local regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    if [[ "$email" =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validate URL
validate_url() {
    local url="${1:-}"
    local regex="^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$"
    
    if [[ "$url" =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validate semantic version
validate_semver() {
    local version="${1:-}"
    local regex="^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$"
    
    if [[ "$version" =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validate integer
validate_integer() {
    local value="${1:-}"
    local min="${2:-}"
    local max="${3:-}"
    
    # Check if integer
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        return 1
    fi
    
    # Check range if provided
    if [[ -n "$min" ]] && [[ "$value" -lt "$min" ]]; then
        return 1
    fi
    
    if [[ -n "$max" ]] && [[ "$value" -gt "$max" ]]; then
        return 1
    fi
    
    return 0
}

# Validate file path (no traversal)
validate_path() {
    local path="${1:-}"
    
    # Check for path traversal
    if [[ "$path" =~ \.\. ]] || [[ "$path" =~ ^/ ]]; then
        return 1
    fi
    
    # Check for dangerous characters
    if [[ "$path" =~ [';|&`$'] ]]; then
        return 1
    fi
    
    return 0
}

# Validate identifier (alphanumeric + underscore)
validate_identifier() {
    local id="${1:-}"
    local regex="^[a-zA-Z_][a-zA-Z0-9_]*$"
    
    if [[ "$id" =~ $regex ]]; then
        return 0
    else
        return 1
    fi
}

# Validate boolean value
validate_boolean() {
    local value="${1:-}"
    
    case "${value,,}" in
        true|false|yes|no|1|0|on|off)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Normalize boolean to true/false
normalize_boolean() {
    local value="${1:-}"
    
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

# Validate JSON
validate_json() {
    local json="${1:-}"
    
    if command -v jq &> /dev/null; then
        echo "$json" | jq empty 2>/dev/null
        return $?
    else
        # Basic check for JSON structure
        if [[ "$json" =~ ^[[:space:]]*\{.*\}[[:space:]]*$ ]] || \
           [[ "$json" =~ ^[[:space:]]*\[.*\][[:space:]]*$ ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# Export functions
export -f validate_email
export -f validate_url
export -f validate_semver
export -f validate_integer
export -f validate_path
export -f validate_identifier
export -f validate_boolean
export -f normalize_boolean
export -f validate_json
