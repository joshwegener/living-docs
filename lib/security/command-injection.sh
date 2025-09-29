#!/bin/bash
# command-injection.sh - Command injection prevention
# Purpose: Prevent shell command injection attacks
# Usage: source lib/security/command-injection.sh

set -euo pipefail

# Security constants
readonly SAFE_CHARS='[a-zA-Z0-9._/-]'
readonly MAX_COMMAND_LENGTH=1024

# Sanitize shell input - remove dangerous characters
sanitize_shell_input() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Remove dangerous shell metacharacters
    local sanitized="$input"

    # Remove backticks
    sanitized="${sanitized//\`/}"

    # Remove command substitution
    sanitized="${sanitized//\$(/}"
    sanitized="${sanitized//\${/}"

    # Escape pipes
    sanitized="${sanitized//|/\\|}"

    # Escape semicolons
    sanitized="${sanitized//;/\\;}"

    # Escape ampersands
    sanitized="${sanitized//&/\\&}"

    # Escape redirections
    sanitized="${sanitized//</\\<}"
    sanitized="${sanitized//>/\\>}"

    # Remove newlines and carriage returns
    sanitized="${sanitized//$'\n'/}"
    sanitized="${sanitized//$'\r'/}"

    echo "$sanitized"
    return 0
}

# Sanitize for safe execution
sanitize_for_execution() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Escape dollar signs to prevent variable expansion
    local sanitized="${input//\$/\\\$}"

    # Remove all environment variable references
    sanitized=$(echo "$sanitized" | sed 's/\$[A-Za-z_][A-Za-z0-9_]*//g')
    sanitized=$(echo "$sanitized" | sed 's/\${[^}]*}//g')

    echo "$sanitized"
    return 0
}

# Detect dangerous constructs
detect_dangerous_constructs() {
    local code="${1:-}"

    [ -z "$code" ] && return 0

    # Check for eval usage
    if [[ "$code" =~ eval[[:space:]] ]]; then
        echo "Error: eval detected - dangerous construct" >&2
        return 1
    fi

    # Check for source/dot sourcing of variables
    if [[ "$code" =~ (source|\.).*\$ ]]; then
        echo "Error: Sourcing with variables detected" >&2
        return 2
    fi

    # Check for exec with variables
    if [[ "$code" =~ exec.*\$ ]]; then
        echo "Error: exec with variables detected" >&2
        return 3
    fi

    return 0
}

# Validate command against whitelist
validate_command_whitelist() {
    local command="${1:-}"
    shift
    local allowed_commands=("$@")

    [ -z "$command" ] && { echo "Error: No command provided" >&2; return 1; }

    # Extract base command
    local base_command="${command%% *}"

    # Check if in whitelist
    local allowed=false
    for allowed_cmd in "${allowed_commands[@]}"; do
        if [[ "$base_command" == "$allowed_cmd" ]]; then
            allowed=true
            break
        fi
    done

    if [[ "$allowed" != "true" ]]; then
        echo "Error: Command not in whitelist: $base_command" >&2
        return 1
    fi

    return 0
}

# Validate command arguments
validate_command_arguments() {
    local full_command="${1:-}"

    [ -z "$full_command" ] && { echo "Error: No command provided" >&2; return 1; }

    # Check for dangerous paths in arguments
    if [[ "$full_command" =~ /etc/(passwd|shadow|sudoers) ]]; then
        echo "Error: Access to sensitive system files denied" >&2
        return 2
    fi

    # Check for output redirection to sensitive locations
    if [[ "$full_command" =~ \>.*(/etc/|/root/|/sys/|/proc/) ]]; then
        echo "Error: Output redirection to sensitive location denied" >&2
        return 3
    fi

    # Check for dangerous flags
    if [[ "$full_command" =~ (--privileged|--cap-add|--pid=host) ]]; then
        echo "Error: Dangerous command flags detected" >&2
        return 4
    fi

    return 0
}

# Sanitize Python input
sanitize_python_input() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    local sanitized="$input"

    # Remove dangerous Python functions
    sanitized=$(echo "$sanitized" | sed 's/__import__//g')
    sanitized=$(echo "$sanitized" | sed 's/eval//g')
    sanitized=$(echo "$sanitized" | sed 's/exec//g')
    sanitized=$(echo "$sanitized" | sed 's/compile//g')
    sanitized=$(echo "$sanitized" | sed 's/globals//g')
    sanitized=$(echo "$sanitized" | sed 's/locals//g')

    echo "$sanitized"
    return 0
}

# Block SQL commands
block_sql_commands() {
    local sql="${1:-}"

    [ -z "$sql" ] && return 0

    # Check for dangerous SQL commands
    if [[ "$sql" =~ (EXEC|EXECUTE|xp_cmdshell|sp_execute_external_script) ]]; then
        echo "Error: SQL command execution attempt blocked" >&2
        return 1
    fi

    # Check for INTO OUTFILE
    if [[ "$sql" =~ INTO[[:space:]]+OUTFILE ]]; then
        echo "Error: SQL file output attempt blocked" >&2
        return 2
    fi

    return 0
}

# Validate Docker arguments
validate_docker_args() {
    local args="${1:-}"

    [ -z "$args" ] && return 0

    # Check for privileged mode
    if [[ "$args" =~ --privileged ]]; then
        echo "Error: Docker privileged mode not allowed" >&2
        return 1
    fi

    # Check for dangerous volume mounts
    if [[ "$args" =~ -v[[:space:]]*/: ]] || [[ "$args" =~ --volume[[:space:]]*/: ]]; then
        echo "Error: Root filesystem mount not allowed" >&2
        return 2
    fi

    # Check for host PID namespace
    if [[ "$args" =~ --pid=host ]]; then
        echo "Error: Host PID namespace not allowed" >&2
        return 3
    fi

    # Check for dangerous capabilities
    if [[ "$args" =~ --cap-add=(ALL|SYS_ADMIN|NET_ADMIN) ]]; then
        echo "Error: Dangerous Docker capabilities not allowed" >&2
        return 4
    fi

    return 0
}

# Create safe command wrapper
safe_command() {
    local command="${1:-}"
    shift
    local args=("$@")

    # Validate command
    if ! validate_command_whitelist "$command" "ls" "cat" "echo" "grep" "find" "wc"; then
        return 1
    fi

    # Sanitize arguments
    local safe_args=()
    for arg in "${args[@]}"; do
        safe_args+=("$(sanitize_shell_input "$arg")")
    done

    # Execute safely
    "$command" "${safe_args[@]}"
}

# Escape for use in quotes
escape_for_quotes() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Escape existing escapes first
    local escaped="${input//\\/\\\\}"

    # Escape double quotes
    escaped="${escaped//\"/\\\"}"

    # Escape dollar signs
    escaped="${escaped//\$/\\\$}"

    # Escape backticks
    escaped="${escaped//\`/\\\`}"

    echo "$escaped"
    return 0
}

# Validate shell script safety
validate_shell_script() {
    local script="${1:-}"

    [ -z "$script" ] && { echo "Error: No script provided" >&2; return 1; }
    [ ! -f "$script" ] && { echo "Error: Script not found" >&2; return 2; }

    # Check for dangerous patterns
    if grep -q 'eval.*\$' "$script"; then
        echo "Error: Dangerous eval usage detected" >&2
        return 3
    fi

    if grep -q 'source.*\$\|\..*\$' "$script"; then
        echo "Error: Dynamic sourcing detected" >&2
        return 4
    fi

    if grep -q 'rm -rf /' "$script"; then
        echo "Error: Dangerous rm command detected" >&2
        return 5
    fi

    return 0
}

# Prevent command chaining
prevent_command_chaining() {
    local input="${1:-}"

    [ -z "$input" ] && return 0

    # Check for command separators
    if [[ "$input" =~ [';|&'] ]]; then
        echo "Error: Command chaining not allowed" >&2
        return 1
    fi

    # Check for newlines (another form of command separation)
    if [[ "$input" =~ $'\n' ]]; then
        echo "Error: Multi-line commands not allowed" >&2
        return 2
    fi

    return 0
}

# Export functions
export -f sanitize_shell_input
export -f sanitize_for_execution
export -f detect_dangerous_constructs
export -f validate_command_whitelist
export -f validate_command_arguments
export -f sanitize_python_input
export -f block_sql_commands
export -f validate_docker_args
export -f safe_command
export -f escape_for_quotes
export -f validate_shell_script
export -f prevent_command_chaining