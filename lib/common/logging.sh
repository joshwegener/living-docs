#!/usr/bin/env bash
set -euo pipefail
# Common Logging Functions for living-docs
# Provides unified logging across all scripts

# Colors for output
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_GRAY='\033[0;90m'

# Log levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARNING=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_VERBOSE=4
readonly LOG_LEVEL_DEBUG=5

# Current log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# Log functions
log_error() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]]; then
        echo -e "${COLOR_RED}✗ ERROR: $*${COLOR_RESET}" >&2
    fi
}

log_warning() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_WARNING ]]; then
        echo -e "${COLOR_YELLOW}⚠ WARNING: $*${COLOR_RESET}" >&2
    fi
}

log_info() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        echo -e "${COLOR_BLUE}ℹ INFO: $*${COLOR_RESET}"
    fi
}

log_success() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]]; then
        echo -e "${COLOR_GREEN}✓ SUCCESS: $*${COLOR_RESET}"
    fi
}

log_verbose() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_VERBOSE ]]; then
        echo -e "${COLOR_GRAY}→ $*${COLOR_RESET}"
    fi
}

log_debug() {
    if [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]]; then
        echo -e "${COLOR_GRAY}[DEBUG] $*${COLOR_RESET}" >&2
    fi
}

# Export functions
export -f log_error
export -f log_warning
export -f log_info
export -f log_success
export -f log_verbose
export -f log_debug
