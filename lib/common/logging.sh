#!/bin/bash
set -euo pipefail
# Common Logging Library for living-docs
# Provides consistent logging across all scripts

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Current log level (can be overridden)
LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Colors
readonly LOG_COLOR_DEBUG='\033[0;36m'  # Cyan
readonly LOG_COLOR_INFO='\033[0;32m'   # Green
readonly LOG_COLOR_WARN='\033[1;33m'   # Yellow
readonly LOG_COLOR_ERROR='\033[0;31m'  # Red
readonly LOG_COLOR_FATAL='\033[1;31m'  # Bold Red
readonly LOG_NC='\033[0m'              # No Color

# Log file (optional)
LOG_FILE="${LOG_FILE:-}"

# Initialize logging
init_logging() {
    local level="${1:-INFO}"
    local file="${2:-}"

    case "${level^^}" in
        DEBUG) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        INFO)  LOG_LEVEL=$LOG_LEVEL_INFO ;;
        WARN)  LOG_LEVEL=$LOG_LEVEL_WARN ;;
        ERROR) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        FATAL) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
        *)     LOG_LEVEL=$LOG_LEVEL_INFO ;;
    esac

    if [[ -n "$file" ]]; then
        LOG_FILE="$file"
        # Create log directory if needed
        local log_dir
        log_dir=$(dirname "$LOG_FILE")
        [[ -d "$log_dir" ]] || mkdir -p "$log_dir"
    fi
}

# Core logging function
log_message() {
    local level=$1
    local level_name=$2
    local color=$3
    local message="${4:-}"

    # Check if we should log this level
    [[ $level -lt $LOG_LEVEL ]] && return 0

    # Format timestamp
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Build log entry
    local log_entry="[$timestamp] [$level_name] $message"

    # Output to console with color
    if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "true" ]]; then
        echo -e "${color}${log_entry}${LOG_NC}"
    else
        echo "$log_entry"
    fi

    # Output to file if configured
    if [[ -n "$LOG_FILE" ]]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
}

# Log functions for each level
log_debug() {
    log_message $LOG_LEVEL_DEBUG "DEBUG" "$LOG_COLOR_DEBUG" "$*"
}

log_info() {
    log_message $LOG_LEVEL_INFO "INFO" "$LOG_COLOR_INFO" "$*"
}

log_warn() {
    log_message $LOG_LEVEL_WARN "WARN" "$LOG_COLOR_WARN" "$*"
}

log_error() {
    log_message $LOG_LEVEL_ERROR "ERROR" "$LOG_COLOR_ERROR" "$*" >&2
}

log_fatal() {
    log_message $LOG_LEVEL_FATAL "FATAL" "$LOG_COLOR_FATAL" "$*" >&2
    exit 1
}

# Log with prefix
log_with_prefix() {
    local prefix="$1"
    shift
    local message="$*"

    log_info "[$prefix] $message"
}

# Log step in a process
log_step() {
    local step_num="${1:-1}"
    local total_steps="${2:-1}"
    shift 2
    local message="$*"

    log_info "Step [$step_num/$total_steps]: $message"
}

# Log success
log_success() {
    local message="${1:-Success}"
    log_info "✓ $message"
}

# Log failure
log_failure() {
    local message="${1:-Failed}"
    log_error "✗ $message"
}

# Progress indicator
start_progress() {
    local message="${1:-Processing}"
    echo -n "$message"
}

update_progress() {
    echo -n "."
}

end_progress() {
    local status="${1:-done}"
    echo " $status"
}

# Log execution time
log_duration() {
    local start_time=$1
    local end_time=${2:-$(date +%s)}
    local duration=$((end_time - start_time))

    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))

    if [[ $hours -gt 0 ]]; then
        log_info "Duration: ${hours}h ${minutes}m ${seconds}s"
    elif [[ $minutes -gt 0 ]]; then
        log_info "Duration: ${minutes}m ${seconds}s"
    else
        log_info "Duration: ${seconds}s"
    fi
}

# Log separator
log_separator() {
    local char="${1:--}"
    local width="${2:-50}"
    local separator
    separator=$(printf "%${width}s" | tr ' ' "$char")
    log_info "$separator"
}

# Log header
log_header() {
    local title="$1"
    log_separator "="
    log_info "$title"
    log_separator "="
}

# Export functions
export -f init_logging
export -f log_message
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_fatal
export -f log_with_prefix
export -f log_step
export -f log_success
export -f log_failure
export -f start_progress
export -f update_progress
export -f end_progress
export -f log_duration
export -f log_separator
export -f log_header