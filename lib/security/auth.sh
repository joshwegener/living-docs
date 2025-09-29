#!/bin/bash
# auth.sh - Authentication and authorization security functions
# Purpose: Provide secure authentication mechanisms
# Usage: source lib/security/auth.sh

set -euo pipefail

# Security constants
readonly MIN_KEY_LENGTH=32
readonly SESSION_TIMEOUT=3600  # 1 hour
readonly MAX_LOGIN_ATTEMPTS=5
readonly LOCKOUT_DURATION=900  # 15 minutes

# GPG signature verification
verify_gpg_signature() {
    local file="${1:-}"

    [ -z "$file" ] && { echo "Error: No file specified for signature verification" >&2; return 1; }
    [ ! -f "$file" ] && { echo "Error: File not found: $file" >&2; return 2; }

    local sig_file="${file}.sig"
    [ ! -f "$sig_file" ] && { echo "Error: Signature file not found: $sig_file" >&2; return 3; }

    # Verify with GPG
    if command -v gpg >/dev/null 2>&1; then
        gpg --verify "$sig_file" "$file" 2>/dev/null || {
            echo "Error: GPG signature verification failed" >&2
            return 4
        }
        echo "GPG signature verified successfully"
        return 0
    else
        echo "Warning: GPG not available, skipping signature verification" >&2
        return 5
    fi
}

# Environment variable sanitization
sanitize_environment() {
    # Remove dangerous environment variables
    unset LD_PRELOAD
    unset LD_LIBRARY_PATH
    unset DYLD_INSERT_LIBRARIES
    unset DYLD_LIBRARY_PATH

    # Sanitize PATH - remove relative paths and suspicious entries
    local safe_path=""
    local IFS=':'
    for dir in $PATH; do
        # Skip relative paths
        [[ "$dir" =~ ^[^/] ]] && continue
        # Skip suspicious paths
        [[ "$dir" =~ (/tmp|/var/tmp|^\.$) ]] && continue
        # Add to safe path
        safe_path="${safe_path}${safe_path:+:}${dir}"
    done

    export PATH="$safe_path"

    # Set secure defaults
    export IFS=$' \t\n'
    umask 077

    return 0
}

# SSH key permissions validation
validate_ssh_permissions() {
    local ssh_dir="${HOME}/.ssh"
    local errors=0

    # Check directory permissions
    if [ -d "$ssh_dir" ]; then
        local dir_perms
        dir_perms=$(stat -c %a "$ssh_dir" 2>/dev/null || stat -f %A "$ssh_dir" 2>/dev/null)
        if [ "$dir_perms" != "700" ]; then
            echo "Error: SSH directory has insecure permissions: $dir_perms (should be 700)" >&2
            ((errors++))
        fi
    fi

    # Check key file permissions
    for key_file in "$ssh_dir"/id_* "$ssh_dir"/*_rsa "$ssh_dir"/*_dsa "$ssh_dir"/*_ecdsa "$ssh_dir"/*_ed25519; do
        [ -f "$key_file" ] || continue

        # Skip public keys
        [[ "$key_file" =~ \.pub$ ]] && continue

        local key_perms
        key_perms=$(stat -c %a "$key_file" 2>/dev/null || stat -f %A "$key_file" 2>/dev/null)
        if [ "$key_perms" != "600" ] && [ "$key_perms" != "400" ]; then
            echo "Error: SSH key has insecure permissions: $key_file ($key_perms, should be 600)" >&2
            ((errors++))
        fi
    done

    return $errors
}

# Secure token generation
generate_secure_token() {
    local length="${1:-32}"

    # Validate length
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 16 ]; then
        echo "Error: Token length must be at least 16" >&2
        return 1
    fi

    # Use /dev/urandom for secure random bytes
    if [ -r /dev/urandom ]; then
        # Generate random bytes and encode as hex
        od -An -tx1 -N "$length" /dev/urandom | tr -d ' \n'
    else
        echo "Error: /dev/urandom not available" >&2
        return 2
    fi
}

# Session validation
validate_session() {
    local session_file="${1:-}"

    [ -z "$session_file" ] && { echo "Error: No session file specified" >&2; return 1; }
    [ ! -f "$session_file" ] && { echo "Error: Session file not found" >&2; return 2; }

    # Check file age
    local current_time
    current_time=$(date +%s)

    local file_time
    file_time=$(stat -c %Y "$session_file" 2>/dev/null || stat -f %m "$session_file" 2>/dev/null)

    local age=$((current_time - file_time))

    if [ "$age" -gt "$SESSION_TIMEOUT" ]; then
        echo "Error: Session expired (age: ${age}s, timeout: ${SESSION_TIMEOUT}s)" >&2
        return 3
    fi

    echo "Session valid (age: ${age}s)"
    return 0
}

# Secure credential prompting
secure_prompt() {
    local prompt="${1:-Enter password}"
    local var_name="${2:-SECURE_INPUT}"

    # Disable echo for password input
    if [ -t 0 ]; then
        echo -n "$prompt: " >&2
        stty -echo 2>/dev/null || true
        IFS= read -r "$var_name"
        stty echo 2>/dev/null || true
        echo >&2  # New line after password
    else
        # Non-interactive mode
        IFS= read -r "$var_name"
    fi

    # Validate input was received
    local input_value
    eval "input_value=\$$var_name"

    [ -z "$input_value" ] && { echo "Error: No credential provided" >&2; return 1; }

    return 0
}

# Rate limiting implementation
check_rate_limit() {
    local action="${1:-api_call}"
    local limit="${2:-10}"
    local window="${3:-60}"  # seconds

    local rate_file="/tmp/.rate_limit_${action}_$$"
    local current_time
    current_time=$(date +%s)

    # Clean old entries
    if [ -f "$rate_file" ]; then
        local cutoff=$((current_time - window))
        grep -v "^[0-9]*$" "$rate_file" 2>/dev/null | \
        while read -r timestamp; do
            [ "$timestamp" -ge "$cutoff" ] && echo "$timestamp"
        done > "${rate_file}.tmp"
        mv "${rate_file}.tmp" "$rate_file"
    fi

    # Count recent requests
    local count=0
    [ -f "$rate_file" ] && count=$(wc -l < "$rate_file")

    if [ "$count" -ge "$limit" ]; then
        echo "Error: Rate limit exceeded ($count/$limit in ${window}s)" >&2
        return 1
    fi

    # Record this request
    echo "$current_time" >> "$rate_file"
    return 0
}

# Audit logging
audit_log() {
    local action="${1:-}"
    local details="${2:-}"
    local audit_file="${AUDIT_LOG:-/var/log/living-docs-audit.log}"

    [ -z "$action" ] && { echo "Error: No action specified for audit log" >&2; return 1; }

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local user="${USER:-unknown}"
    local pid="$$"

    # Format: timestamp|user|pid|action|details
    local log_entry="${timestamp}|${user}|${pid}|${action}|${details}"

    # Write to audit log (create if needed)
    if [ -w "$(dirname "$audit_file")" ] || [ -w "$audit_file" ]; then
        echo "$log_entry" >> "$audit_file"
    else
        # Fallback to local audit log
        echo "$log_entry" >> "${HOME}/.living-docs-audit.log"
    fi

    return 0
}

# Privilege escalation check
check_privilege_escalation() {
    # Check for sudo escalation attempts
    if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "${USER:-}" ]; then
        echo "Error: Privilege escalation detected (SUDO_USER=${SUDO_USER})" >&2
        audit_log "PRIVILEGE_ESCALATION_ATTEMPT" "sudo_user=${SUDO_USER}"
        return 1
    fi

    # Check for UID changes
    if [ "${EUID:-$(id -u)}" -ne "${UID:-$(id -ru)}" ]; then
        echo "Error: UID mismatch detected (EUID=${EUID}, UID=${UID})" >&2
        audit_log "PRIVILEGE_ESCALATION_ATTEMPT" "uid_mismatch"
        return 2
    fi

    # Check for suspicious environment
    if [ -n "${LD_PRELOAD:-}" ] || [ -n "${LD_LIBRARY_PATH:-}" ]; then
        echo "Error: Suspicious environment variables detected" >&2
        audit_log "PRIVILEGE_ESCALATION_ATTEMPT" "suspicious_env"
        return 3
    fi

    return 0
}

# Certificate pinning verification
verify_certificate_pin() {
    local host="${1:-}"
    local expected_pin="${2:-}"

    [ -z "$host" ] && { echo "Error: No host specified" >&2; return 1; }

    # Get certificate fingerprint
    local actual_pin
    actual_pin=$(openssl s_client -connect "${host}:443" -servername "$host" 2>/dev/null </dev/null | \
                 openssl x509 -noout -fingerprint -sha256 2>/dev/null | \
                 cut -d= -f2)

    if [ -z "$actual_pin" ]; then
        echo "Error: Could not retrieve certificate for $host" >&2
        return 2
    fi

    # If no expected pin provided, just return the actual pin
    if [ -z "$expected_pin" ]; then
        echo "Certificate pin for $host: $actual_pin"
        return 0
    fi

    # Verify pin matches
    if [ "$actual_pin" != "$expected_pin" ]; then
        echo "Error: Certificate pin mismatch for $host" >&2
        echo "  Expected: $expected_pin" >&2
        echo "  Actual: $actual_pin" >&2
        audit_log "CERT_PIN_MISMATCH" "host=$host"
        return 3
    fi

    echo "Certificate pin verified for $host"
    return 0
}

# Export functions for use in other scripts
export -f verify_gpg_signature
export -f sanitize_environment
export -f validate_ssh_permissions
export -f generate_secure_token
export -f validate_session
export -f secure_prompt
export -f check_rate_limit
export -f audit_log
export -f check_privilege_escalation
export -f verify_certificate_pin