#!/bin/bash
set -euo pipefail
# Common Error Handling Library for living-docs
# Provides consistent error handling across all scripts

# Colors for error output
readonly ERROR_RED='\033[0;31m'
readonly ERROR_YELLOW='\033[1;33m'
readonly ERROR_NC='\033[0m'

# Error codes
readonly E_GENERAL=1
readonly E_INVALID_INPUT=2
readonly E_FILE_NOT_FOUND=3
readonly E_PERMISSION_DENIED=4
readonly E_DEPENDENCY_MISSING=5
readonly E_NETWORK_ERROR=6
readonly E_TIMEOUT=7
readonly E_CONFLICT=8
readonly E_VALIDATION=9

# Error handler function
error_handler() {
    local line_no=$1
    local bash_lineno=$2
    local last_command=$3
    local exit_code=$4

    echo -e "${ERROR_RED}✗ Error occurred:${ERROR_NC}" >&2
    echo "  Line: $line_no" >&2
    echo "  Command: $last_command" >&2
    echo "  Exit code: $exit_code" >&2

    # Log to error file if LOG_ERRORS is set
    if [[ "${LOG_ERRORS:-false}" == "true" ]]; then
        log_error "$line_no" "$last_command" "$exit_code"
    fi

    exit "$exit_code"
}

# Set up error trap
setup_error_trap() {
    set -euo pipefail
    trap 'error_handler ${LINENO} ${BASH_LINENO} "$BASH_COMMAND" $?' ERR
}

# Log error to file
log_error() {
    local line_no=$1
    local command=$2
    local exit_code=$3

    local error_log="${ERROR_LOG:-/tmp/living-docs-errors.log}"
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error in ${BASH_SOURCE[2]:-unknown}"
        echo "  Line: $line_no"
        echo "  Command: $command"
        echo "  Exit code: $exit_code"
        echo "---"
    } >> "$error_log"
}

# Print error message and exit
die() {
    local message="${1:-Unknown error}"
    local exit_code="${2:-$E_GENERAL}"

    echo -e "${ERROR_RED}✗ Error: $message${ERROR_NC}" >&2
    exit "$exit_code"
}

# Print warning message
warn() {
    local message="${1:-Warning}"
    echo -e "${ERROR_YELLOW}⚠ Warning: $message${ERROR_NC}" >&2
}

# Validate required command exists
require_command() {
    local cmd="$1"
    local message="${2:-$cmd is required but not found}"

    if ! command -v "$cmd" &>/dev/null; then
        die "$message. Please install $cmd and try again." "$E_DEPENDENCY_MISSING"
    fi
}

# Validate required file exists
require_file() {
    local file="$1"
    local message="${2:-File not found: $file}"

    if [[ ! -f "$file" ]]; then
        die "$message" "$E_FILE_NOT_FOUND"
    fi
}

# Validate required directory exists
require_dir() {
    local dir="$1"
    local message="${2:-Directory not found: $dir}"

    if [[ ! -d "$dir" ]]; then
        die "$message" "$E_FILE_NOT_FOUND"
    fi
}

# Check write permission
require_write_permission() {
    local path="$1"

    if [[ ! -w "$path" ]]; then
        die "No write permission for: $path" "$E_PERMISSION_DENIED"
    fi
}

# Retry command with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    shift 2
    local command=("$@")
    local attempt=1

    while [ $attempt -le "$max_attempts" ]; do
        if "${command[@]}"; then
            return 0
        fi

        if [ $attempt -lt "$max_attempts" ]; then
            warn "Command failed (attempt $attempt/$max_attempts). Retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))
        fi

        ((attempt++))
    done

    die "Command failed after $max_attempts attempts" "$E_GENERAL"
}

# Timeout wrapper
with_timeout() {
    local timeout="$1"
    shift
    local command=("$@")

    if command -v timeout &>/dev/null; then
        timeout "$timeout" "${command[@]}"
    elif command -v gtimeout &>/dev/null; then
        gtimeout "$timeout" "${command[@]}"
    else
        # Fallback: run without timeout
        warn "timeout command not available, running without timeout"
        "${command[@]}"
    fi
}

# Clean up on exit
cleanup_on_exit() {
    local cleanup_function="${1:-cleanup}"

    trap "$cleanup_function" EXIT INT TERM
}

# Export functions
export -f error_handler
export -f setup_error_trap
export -f die
export -f warn
export -f require_command
export -f require_file
export -f require_dir
export -f require_write_permission
export -f retry_with_backoff
export -f with_timeout
export -f cleanup_on_exit