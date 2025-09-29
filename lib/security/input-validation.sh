#!/bin/bash
# input-validation.sh - Input validation and sanitization
# Purpose: Validate and sanitize all user inputs
# Usage: source lib/security/input-validation.sh

set -euo pipefail

# Validation constants
readonly MAX_INPUT_LENGTH=10000
readonly MAX_PATH_LENGTH=4096
export MAX_PATH_LENGTH  # Export for external use
readonly MAX_FILENAME_LENGTH=255

# SQL injection prevention
sanitize_sql_input() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Escape dangerous SQL characters
    local sanitized
    sanitized="${input//\'/\'\'}"  # Escape single quotes
    sanitized="${sanitized//\\/\\\\}"  # Escape backslashes
    sanitized="${sanitized//\"/\\\"}"  # Escape double quotes
    sanitized="${sanitized//;/\\;}"  # Escape semicolons

    # Remove dangerous SQL keywords (case-insensitive)
    sanitized=$(echo "$sanitized" | sed -E 's/\b(DROP|DELETE|INSERT|UPDATE|ALTER|CREATE|EXEC|EXECUTE)\b//gi')

    echo "$sanitized"
    return 0
}

# XSS prevention
sanitize_html_output() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # HTML entity encoding
    local sanitized="$input"
    sanitized="${sanitized//&/&amp;}"
    sanitized="${sanitized//</&lt;}"
    sanitized="${sanitized//>/&gt;}"
    sanitized="${sanitized//\"/&quot;}"
    sanitized="${sanitized//\'/&#x27;}"
    sanitized="${sanitized//\//&#x2F;}"

    echo "$sanitized"
    return 0
}

# File name validation
validate_filename() {
    local filename="${1:-}"

    [ -z "$filename" ] && { echo "Error: Empty filename" >&2; return 1; }

    # Check for path traversal
    if [[ "$filename" =~ \.\. ]] || [[ "$filename" =~ / ]] || [[ "$filename" =~ \\ ]]; then
        echo "Error: Invalid filename - contains path characters" >&2
        return 2
    fi

    # Check for command injection characters
    if [[ "$filename" =~ [\;\|\&\$\`\(\)\{\}\[\]\<\>] ]]; then
        echo "Error: Invalid filename - contains shell metacharacters" >&2
        return 3
    fi

    # Check for null bytes
    if [[ "$filename" =~ $'\x00' ]]; then
        echo "Error: Invalid filename - contains null bytes" >&2
        return 4
    fi

    # Check reserved names (Windows compatibility)
    local reserved_names="CON PRN AUX NUL COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9 LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9"
    local base_name="${filename%%.*}"
    for reserved in $reserved_names; do
        if [[ "${base_name^^}" == "$reserved" ]]; then
            echo "Error: Invalid filename - reserved name" >&2
            return 5
        fi
    done

    # Check length
    if [ ${#filename} -gt $MAX_FILENAME_LENGTH ]; then
        echo "Error: Filename too long (max: $MAX_FILENAME_LENGTH)" >&2
        return 6
    fi

    return 0
}

# Input length validation
validate_input_length() {
    local input="${1:-}"
    local max_length="${2:-$MAX_INPUT_LENGTH}"

    if [ ${#input} -gt "$max_length" ]; then
        echo "Error: Input too long (${#input} > $max_length)" >&2
        return 1
    fi

    return 0
}

# Email validation
validate_email() {
    local email="${1:-}"

    [ -z "$email" ] && { echo "Error: Empty email" >&2; return 1; }

    # Basic email regex (RFC 5322 simplified)
    local email_regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

    if ! [[ "$email" =~ $email_regex ]]; then
        echo "Error: Invalid email format" >&2
        return 2
    fi

    # Check for dangerous characters
    if [[ "$email" =~ [\;\|\&\$\`\(\)\{\}\[\]\<\>] ]]; then
        echo "Error: Email contains dangerous characters" >&2
        return 3
    fi

    # Check for multiple @ symbols
    local at_count
    at_count=$(echo "$email" | tr -cd '@' | wc -c)
    if [ "$at_count" -ne 1 ]; then
        echo "Error: Invalid email - multiple @ symbols" >&2
        return 4
    fi

    return 0
}

# URL validation (SSRF prevention)
validate_external_url() {
    local url="${1:-}"

    [ -z "$url" ] && { echo "Error: Empty URL" >&2; return 1; }

    # Parse URL components
    local protocol="${url%%://*}"
    local rest="${url#*://}"
    local host="${rest%%/*}"
    host="${host%%:*}"  # Remove port if present

    # Check protocol
    case "$protocol" in
        http|https) ;;
        *)
            echo "Error: Invalid protocol: $protocol" >&2
            return 2
            ;;
    esac

    # Check for localhost/internal IPs (SSRF prevention)
    case "$host" in
        localhost|127.0.0.1|0.0.0.0|::1|\[::1\])
            echo "Error: URL points to localhost" >&2
            return 3
            ;;
        10.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|192.168.*|169.254.*)
            echo "Error: URL points to private network" >&2
            return 4
            ;;
    esac

    # Check for metadata endpoints
    if [[ "$host" == "169.254.169.254" ]] || [[ "$url" =~ metadata ]]; then
        echo "Error: URL points to metadata endpoint" >&2
        return 5
    fi

    return 0
}

# JSON validation
validate_json_input() {
    local json="${1:-}"

    [ -z "$json" ] && { echo "Error: Empty JSON" >&2; return 1; }

    # Check for prototype pollution
    if [[ "$json" =~ __proto__ ]] || [[ "$json" =~ constructor ]] || [[ "$json" =~ prototype ]]; then
        echo "Error: Potential prototype pollution detected" >&2
        return 2
    fi

    # Try to parse JSON (if jq available)
    if command -v jq >/dev/null 2>&1; then
        if ! echo "$json" | jq . >/dev/null 2>&1; then
            echo "Error: Invalid JSON syntax" >&2
            return 3
        fi
    fi

    return 0
}

# Integer validation (overflow prevention)
validate_integer() {
    local value="${1:-}"

    [ -z "$value" ] && { echo "Error: Empty value" >&2; return 1; }

    # Check if it's a valid integer
    if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Not a valid integer" >&2
        return 2
    fi

    # Remove leading zeros and sign for comparison
    local abs_value="${value#-}"
    abs_value="${abs_value#0}"

    # Check for overflow (64-bit signed integer max)
    local max_int="9223372036854775807"

    if [ ${#abs_value} -gt ${#max_int} ]; then
        echo "Error: Integer overflow" >&2
        return 3
    elif [ ${#abs_value} -eq ${#max_int} ]; then
        # Same length, need to compare
        if [[ "$abs_value" -gt "$max_int" ]]; then
            echo "Error: Integer overflow" >&2
            return 3
        fi
    fi

    return 0
}

# Unicode normalization
normalize_unicode() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Remove RTL/LTR override characters
    local normalized
    # Remove RTL/LTR override characters one by one
    normalized=$(echo "$input" | tr -d '\u202a' | tr -d '\u202b' | tr -d '\u202c' | tr -d '\u202d' | tr -d '\u202e')

    # Convert common homoglyphs to ASCII
    # This is a simplified version - real implementation would need more comprehensive mapping
    normalized=$(echo "$normalized" | sed 's/[а]/a/g; s/[е]/e/g; s/[о]/o/g; s/[р]/p/g; s/[с]/c/g; s/[у]/y/g; s/[х]/x/g')

    echo "$normalized"
    return 0
}

# Template injection prevention
sanitize_template_input() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Escape template syntax
    local sanitized="$input"
    sanitized="${sanitized//\{\{/\\{\\{}"
    sanitized="${sanitized//\}\}/\\}\\}}"
    sanitized="${sanitized//\${/\\\${}"
    sanitized="${sanitized//<%/\\<%}"
    sanitized="${sanitized//%>/\\%>}"
    sanitized="${sanitized//#{/\\#{}"

    echo "$sanitized"
    return 0
}

# Regular expression safety check
validate_regex_safety() {
    local regex="${1:-}"

    [ -z "$regex" ] && { echo "Error: Empty regex" >&2; return 1; }

    # Check for catastrophic backtracking patterns
    if [[ "$regex" =~ \(\.\*\)\+ ]] || \
       [[ "$regex" =~ \(\.\+\)\+ ]] || \
       [[ "$regex" =~ \([a-zA-Z]+\)\+ ]] || \
       [[ "$regex" =~ \(\\w\+\)\+ ]]; then
        echo "Error: Potential catastrophic backtracking in regex" >&2
        return 2
    fi

    # Check for nested quantifiers
    if [[ "$regex" =~ \{[0-9]+,[0-9]*\}[\*\+] ]]; then
        echo "Error: Nested quantifiers detected" >&2
        return 3
    fi

    return 0
}

# XML entity expansion prevention
parse_xml_safely() {
    local xml="${1:-}"

    [ -z "$xml" ] && { echo "Error: Empty XML" >&2; return 1; }

    # Check for entity declarations (XXE prevention)
    if [[ "$xml" =~ \<!DOCTYPE ]] || \
       [[ "$xml" =~ \<!ENTITY ]] || \
       [[ "$xml" =~ SYSTEM ]] || \
       [[ "$xml" =~ \<\?xml-stylesheet ]]; then
        echo "Error: Potentially dangerous XML entity detected" >&2
        return 2
    fi

    return 0
}

# LDAP injection prevention
sanitize_ldap_input() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Escape LDAP metacharacters
    local sanitized="$input"
    sanitized="${sanitized//\\/\\\\}"  # Backslash
    sanitized="${sanitized//\*/\\*}"   # Asterisk
    sanitized="${sanitized//\(/\\(}"   # Left paren
    sanitized="${sanitized//\)/\\)}"   # Right paren
    sanitized="${sanitized//\0/\\00}"  # Null

    echo "$sanitized"
    return 0
}

# Export functions
export -f sanitize_sql_input
export -f sanitize_html_output
export -f validate_filename
export -f validate_input_length
export -f validate_email
export -f validate_external_url
export -f validate_json_input
export -f validate_integer
export -f normalize_unicode
export -f sanitize_template_input
export -f validate_regex_safety
export -f parse_xml_safely
export -f sanitize_ldap_input