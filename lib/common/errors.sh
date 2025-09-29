#!/usr/bin/env bash
set -euo pipefail
# Common Error Handling Functions for living-docs
# Provides unified error handling across all scripts

# Source logging if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh" 2>/dev/null || true

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_FILE_NOT_FOUND=3
readonly EXIT_PERMISSION_DENIED=4
readonly EXIT_DEPENDENCY_MISSING=5
readonly EXIT_VALIDATION_FAILED=10
readonly EXIT_NETWORK_ERROR=20

# Error trap handler
error_handler() {
    local line_no=$1
    local bash_lineno=$2
    local last_command=$3
    local code=$4

    log_error "Command failed with exit code $code"
    log_error "Line $line_no: $last_command"
    log_error "Called from line $bash_lineno"

    # Cleanup if function exists
    if declare -f cleanup > /dev/null; then
        cleanup
    fi

    exit "$code"
}

# Setup error handling
setup_error_handling() {
    set -euo pipefail
    trap 'error_handler $LINENO $BASH_LINENO "$BASH_COMMAND" $?' ERR
}

# Fail with error message
fail() {
    local message="${1:-Unknown error}"
    local exit_code="${2:-$EXIT_GENERAL_ERROR}"
    
    log_error "$message"
    exit "$exit_code"
}

# Assert condition
assert() {
    local condition="$1"
    local message="${2:-Assertion failed: $condition}"
    
    if ! eval "$condition"; then
        fail "$message" "$EXIT_VALIDATION_FAILED"
    fi
}

# Require command exists
require_command() {
    local cmd="$1"
    local message="${2:-Required command not found: $cmd}"
    
    if ! command -v "$cmd" &> /dev/null; then
        fail "$message" "$EXIT_DEPENDENCY_MISSING"
    fi
}

# Require file exists
require_file() {
    local file="$1"
    local message="${2:-Required file not found: $file}"
    
    if [[ ! -f "$file" ]]; then
        fail "$message" "$EXIT_FILE_NOT_FOUND"
    fi
}

# Require directory exists
require_directory() {
    local dir="$1"
    local message="${2:-Required directory not found: $dir}"
    
    if [[ ! -d "$dir" ]]; then
        fail "$message" "$EXIT_FILE_NOT_FOUND"
    fi
}

# Export functions
export -f error_handler
export -f setup_error_handling
export -f fail
export -f assert
export -f require_command
export -f require_file
export -f require_directory
