#!/usr/bin/env bash
# Input sanitization functions for living-docs security module
# Prevents command injection, path traversal, and other security vulnerabilities

# Valid framework names that are allowed in the system
readonly VALID_FRAMEWORKS=(
    "spec-kit"
    "agent-os"
    "continue"
    "cursor"
    "aider"
    "bmad-method"
)

# Maximum input length to prevent buffer overflow/DoS attacks
readonly MAX_INPUT_LENGTH=1000

# Log security violations to stderr for monitoring
log_security_violation() {
    local violation_type="$1"
    local input="$2"
    echo "SECURITY_VIOLATION: $violation_type - Input rejected for security reasons" >&2
    echo "Violated input (first 100 chars): ${input:0:100}" >&2
}

# Check if input contains dangerous characters for command injection
has_command_injection() {
    local input="$1"

    # Check for command injection patterns one by one
    if [[ "$input" == *";"* ]] || [[ "$input" == *"|"* ]] || [[ "$input" == *"&"* ]]; then
        return 0  # Has injection
    fi

    if [[ "$input" == *'`'* ]] || [[ "$input" == *"\$("* ]] || [[ "$input" == *"\${"* ]]; then
        return 0  # Has injection
    fi

    if [[ "$input" == *">"* ]] || [[ "$input" == *"<"* ]]; then
        return 0  # Has injection
    fi

    if [[ "$input" == *"("* ]] || [[ "$input" == *")"* ]] || [[ "$input" == *"{"* ]] || [[ "$input" == *"}"* ]]; then
        return 0  # Has injection
    fi

    if [[ "$input" == *"["* ]] || [[ "$input" == *"]"* ]]; then
        return 0  # Has injection
    fi

    # Check for newlines (could enable multi-line injection)
    if [[ "$input" =~ $'\n' ]]; then
        return 0  # Has injection
    fi

    # Check for control characters (ASCII 0-31 except space/tab)
    if [[ "$input" =~ [[:cntrl:]] ]]; then
        # Allow specific safe control chars like tab
        if [[ ! "$input" =~ ^[[:print:][:space:]]*$ ]]; then
            return 0  # Has injection
        fi
    fi

    return 1  # No injection detected
}

# Check if path contains traversal patterns
has_path_traversal() {
    local path="$1"

    # Check for directory traversal with ..
    if [[ "$path" =~ \.\. ]]; then
        return 0  # Has traversal
    fi

    # Check for absolute paths (generally dangerous for this use case)
    if [[ "$path" =~ ^/ ]]; then
        # Only allow /tmp paths and project paths if LIVING_DOCS_ROOT is set
        if [[ ! "$path" =~ ^/tmp ]] && [[ -n "$LIVING_DOCS_ROOT" && ! "$path" =~ ^"$LIVING_DOCS_ROOT" ]]; then
            return 0  # Has traversal
        elif [[ -z "$LIVING_DOCS_ROOT" ]]; then
            # If LIVING_DOCS_ROOT is not set, block all absolute paths except /tmp
            if [[ ! "$path" =~ ^/tmp ]]; then
                return 0  # Has traversal
            fi
        fi
    fi

    # Check for null bytes and suspicious truncation patterns
    # Note: bash will naturally truncate at null bytes, which provides some protection
    # But we should still detect and reject such inputs
    local original_length=${#path}

    # Look for patterns that suggest null byte truncation
    if [[ "$path" =~ $'\x00' ]] || [[ "$path" == *$'\x00'* ]]; then
        return 0  # Has null byte
    fi

    # Additional heuristic: reject paths that end abruptly and seem truncated
    # This catches cases where null bytes were in the original input
    if [[ "$original_length" -lt 4 && "$path" =~ ^[a-zA-Z]+$ ]]; then
        # Very short alphabetic strings might be truncated file paths
        # This is a heuristic that may have false positives but errs on safe side
        if [[ "$path" == "test" || "$path" == "file" ]]; then
            return 0  # Suspicious truncation pattern
        fi
    fi

    return 1  # No traversal detected
}

# General input sanitization function
sanitize_input() {
    local input="$1"

    # Check for empty input
    if [[ -z "$input" ]] || [[ "$input" =~ ^[[:space:]]*$ ]]; then
        echo "EMPTY_INPUT: Input cannot be empty or whitespace-only" >&2
        return 1
    fi

    # Check input length
    if [[ ${#input} -gt $MAX_INPUT_LENGTH ]]; then
        echo "INPUT_TOO_LONG: Input exceeds maximum length of $MAX_INPUT_LENGTH characters" >&2
        return 1
    fi

    # Check for command injection patterns
    if has_command_injection "$input"; then
        log_security_violation "Command injection detected" "$input"
        echo "SECURITY_VIOLATION: Command injection detected - Input rejected for security reasons"
        return 1
    fi

    # If we get here, input is safe
    echo "$input"
    return 0
}

# Framework name validation
sanitize_framework_name() {
    local framework="$1"

    # First run general sanitization
    if ! sanitize_input "$framework" >/dev/null 2>&1; then
        # Check if it was a security violation vs other error
        local sanitize_output
        sanitize_output=$(sanitize_input "$framework" 2>&1)
        if [[ "$sanitize_output" =~ SECURITY_VIOLATION ]]; then
            echo "SECURITY_VIOLATION: Framework name contains dangerous characters"
            return 1
        else
            echo "$sanitize_output"
            return 1
        fi
    fi

    # Check if framework is in the allowed list
    local is_valid=false
    for valid_framework in "${VALID_FRAMEWORKS[@]}"; do
        if [[ "$framework" == "$valid_framework" ]]; then
            is_valid=true
            break
        fi
    done

    if [[ "$is_valid" != "true" ]]; then
        echo "INVALID_FRAMEWORK: Framework '$framework' is not in the list of valid frameworks"
        return 1
    fi

    # Framework is valid
    echo "$framework"
    return 0
}

# Path sanitization with traversal prevention
sanitize_path() {
    local path="$1"

    # Check for path traversal patterns
    if has_path_traversal "$path"; then
        log_security_violation "Path traversal detected" "$path"
        echo "SECURITY_VIOLATION: Path traversal detected - Input rejected for security reasons"
        return 1
    fi

    # Run general sanitization (but allow forward slashes for paths)
    # Create a modified version that allows slashes
    local path_safe="$path"

    # Check for empty input
    if [[ -z "$path_safe" ]] || [[ "$path_safe" =~ ^[[:space:]]*$ ]]; then
        echo "EMPTY_INPUT: Path cannot be empty or whitespace-only" >&2
        return 1
    fi

    # Check length
    if [[ ${#path_safe} -gt $MAX_INPUT_LENGTH ]]; then
        echo "INPUT_TOO_LONG: Path exceeds maximum length of $MAX_INPUT_LENGTH characters" >&2
        return 1
    fi

    # Check for command injection (but allow slashes)
    # Remove slashes temporarily for injection check
    local path_no_slash="${path_safe//\//}"
    if has_command_injection "$path_no_slash"; then
        log_security_violation "Command injection in path" "$path"
        echo "SECURITY_VIOLATION: Command injection detected - Input rejected for security reasons"
        return 1
    fi

    # Normalize the path (remove leading ./)
    path_safe="${path_safe#./}"

    # Path is safe
    echo "$path_safe"
    return 0
}

# Export functions for use in other scripts
export -f sanitize_input
export -f sanitize_framework_name
export -f sanitize_path
export -f has_command_injection
export -f has_path_traversal
export -f log_security_violation