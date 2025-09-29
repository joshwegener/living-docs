#!/usr/bin/env bash
set -euo pipefail
# progress.sh - Progress indicator library for living-docs
# Provides visual progress indicators for shell scripts

# Global variables for state management
PROGRESS_SPINNER_PID=""
PROGRESS_CLEANUP_DONE=""

# Color definitions (respect NO_COLOR)
setup_colors() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        # No colors
        PROGRESS_GREEN=""
        PROGRESS_BLUE=""
        PROGRESS_YELLOW=""
        PROGRESS_RED=""
        PROGRESS_RESET=""
        PROGRESS_BOLD=""
    else
        # ANSI color codes
        PROGRESS_GREEN="\033[32m"
        PROGRESS_BLUE="\033[34m"
        PROGRESS_YELLOW="\033[33m"
        PROGRESS_RED="\033[31m"
        PROGRESS_RESET="\033[0m"
        PROGRESS_BOLD="\033[1m"
    fi
}

# Initialize colors
setup_colors

# Utility functions
is_quiet() {
    [[ -n "${QUIET:-}" ]]
}

is_ci() {
    [[ -n "${CI:-}" ]]
}

get_terminal_width() {
    if [[ -n "${COLUMNS:-}" ]]; then
        echo "$COLUMNS"
    elif command -v tput >/dev/null 2>&1; then
        tput cols 2>/dev/null || echo "80"
    else
        echo "80"
    fi
}

# Ensure cleanup on exit
setup_cleanup_trap() {
    if [[ -z "$PROGRESS_CLEANUP_DONE" ]]; then
        trap 'progress_cleanup' EXIT INT TERM
        PROGRESS_CLEANUP_DONE="1"
    fi
}

# progress_bar - Display a visual progress bar
# Usage: progress_bar current total [width] [message]
progress_bar() {
    local current="${1:-0}"
    local total="${2:-100}"
    local width="${3:-40}"
    local message="${4:-}"

    # Return early if quiet mode
    is_quiet && return 0

    # Validate and sanitize inputs
    if ! [[ "$current" =~ ^-?[0-9]+$ ]] || ! [[ "$total" =~ ^-?[0-9]+$ ]]; then
        current=0
        total=100
    fi

    # Handle edge cases
    if (( total <= 0 )); then
        total=1
    fi

    if (( current < 0 )); then
        current=0
    elif (( current > total )); then
        current=$total
    fi

    # Calculate percentage
    local percentage=$(( (current * 100) / total ))

    # Adjust width for smaller terminals
    local term_width
    term_width=$(get_terminal_width)
    if (( width > term_width - 20 )); then
        width=$((term_width - 20))
    fi

    # Ensure minimum width
    if (( width < 5 )); then
        width=5
    fi

    # Calculate filled portion
    local filled=$(( (current * width) / total ))
    local empty=$((width - filled))

    # Build progress bar
    local bar="["

    # Add filled portion
    for ((i=0; i<filled; i++)); do
        if is_ci; then
            bar+="="
        else
            bar+="${PROGRESS_GREEN}█${PROGRESS_RESET}"
        fi
    done

    # Add empty portion
    for ((i=0; i<empty; i++)); do
        bar+=" "
    done

    bar+="]"

    # Format output
    local output=""
    if [[ -n "$message" ]]; then
        output="$message "
    fi

    if is_ci; then
        output+="$bar ${percentage}%"
    else
        output+="${PROGRESS_BOLD}$bar${PROGRESS_RESET} ${PROGRESS_BLUE}${percentage}%${PROGRESS_RESET}"
    fi

    printf "\r%s" "$output"

    # Add newline if we're at 100%
    if (( percentage == 100 )); then
        echo
    fi
}

# progress_spinner - Display an animated spinner
# Usage: progress_spinner message
progress_spinner() {
    local message="${1:-Loading}"

    # Return early if quiet mode
    is_quiet && return 0

    setup_cleanup_trap

    local spinner_chars
    if is_ci; then
        # Simple dots for CI
        spinner_chars=("." ".." "..." "....")
    else
        # Animated spinner
        spinner_chars=("|" "/" "-" "\\")
    fi

    local count=0

    while true; do
        local char="${spinner_chars[$((count % ${#spinner_chars[@]}))]}"

        if is_ci; then
            printf "\r%s %s" "$message" "$char"
        else
            printf "\r${PROGRESS_YELLOW}%s${PROGRESS_RESET} %s" "$char" "$message"
        fi

        sleep 0.1
        ((count++))

        # Check if parent process still exists
        if ! kill -0 $$ 2>/dev/null; then
            break
        fi
    done
}

# percentage_progress - Simple percentage display
# Usage: percentage_progress current total
percentage_progress() {
    local current="${1:-0}"
    local total="${2:-100}"

    # Return early if quiet mode
    is_quiet && return 0

    # Validate inputs
    if ! [[ "$current" =~ ^-?[0-9]+$ ]] || ! [[ "$total" =~ ^-?[0-9]+$ ]]; then
        current=0
        total=100
    fi

    # Handle edge cases
    if (( total <= 0 )); then
        total=1
    fi

    if (( current < 0 )); then
        current=0
    elif (( current > total )); then
        current=$total
    fi

    # Calculate percentage
    local percentage=$(( (current * 100) / total ))

    if is_ci; then
        echo "${percentage}%"
    else
        echo "${PROGRESS_BLUE}${percentage}%${PROGRESS_RESET}"
    fi
}

# step_progress - Step-by-step progress indicator
# Usage: step_progress current total message
step_progress() {
    local current="${1:-1}"
    local total="${2:-1}"
    local message="${3:-}"

    # Return early if quiet mode
    is_quiet && return 0

    # Validate inputs
    if ! [[ "$current" =~ ^-?[0-9]+$ ]] || ! [[ "$total" =~ ^-?[0-9]+$ ]]; then
        current=1
        total=1
    fi

    # Handle edge cases
    if (( total <= 0 )); then
        total=1
    fi

    if (( current < 1 )); then
        current=1
    elif (( current > total )); then
        current=$total
    fi

    # Calculate percentage
    local percentage=$(( (current * 100) / total ))

    # Format output
    local output=""

    if is_ci; then
        output="Step ${current}/${total}"
        if [[ -n "$message" ]]; then
            output+=" - $message"
        fi
        output+=" (${percentage}%)"
    else
        output="${PROGRESS_BOLD}Step ${current}/${total}${PROGRESS_RESET}"
        if [[ -n "$message" ]]; then
            output+=" - ${PROGRESS_GREEN}$message${PROGRESS_RESET}"
        fi
        output+=" ${PROGRESS_BLUE}(${percentage}%)${PROGRESS_RESET}"
    fi

    echo "$output"
}

# multi_step_progress - Coordinate multiple steps with descriptions
# Usage: multi_step_progress current step1 step2 step3 ...
multi_step_progress() {
    local current="${1:-1}"
    shift
    local steps=("$@")

    # Return early if quiet mode
    is_quiet && return 0

    local total=${#steps[@]}

    # Validate current step
    if ! [[ "$current" =~ ^-?[0-9]+$ ]]; then
        current=1
    fi

    if (( current < 1 )); then
        current=1
    elif (( current > total )); then
        current=$total
    fi

    # Get current step description
    local step_desc=""
    if (( current <= total && current > 0 )); then
        step_desc="${steps[$((current - 1))]}"
    fi

    # Use step_progress to display
    step_progress "$current" "$total" "$step_desc"
}

# elapsed_time_progress - Progress with elapsed time information
# Usage: elapsed_time_progress start_time current total
elapsed_time_progress() {
    local start_time="${1:-$(date +%s)}"
    local current="${2:-0}"
    local total="${3:-100}"

    # Return early if quiet mode
    is_quiet && return 0

    # Validate inputs
    if ! [[ "$start_time" =~ ^-?[0-9]+$ ]]; then
        start_time=$(date +%s)
    fi

    # Calculate elapsed time
    local now
    now=$(date +%s)
    local elapsed=$((now - start_time))

    # Format elapsed time
    local elapsed_str=""
    if (( elapsed < 60 )); then
        elapsed_str="${elapsed}s"
    elif (( elapsed < 3600 )); then
        local minutes=$((elapsed / 60))
        local seconds=$((elapsed % 60))
        elapsed_str="${minutes}m ${seconds}s"
    else
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        elapsed_str="${hours}h ${minutes}m"
    fi

    # Calculate percentage
    if ! [[ "$current" =~ ^-?[0-9]+$ ]] || ! [[ "$total" =~ ^-?[0-9]+$ ]]; then
        current=0
        total=100
    fi

    if (( total <= 0 )); then
        total=1
    fi

    if (( current < 0 )); then
        current=0
    elif (( current > total )); then
        current=$total
    fi

    local percentage=$(( (current * 100) / total ))

    # Estimate remaining time
    local eta_str=""
    if (( current > 0 && current < total )); then
        local rate=$((elapsed * total / current))
        local remaining=$((rate - elapsed))

        if (( remaining < 60 )); then
            eta_str=" (ETA: ${remaining}s)"
        elif (( remaining < 3600 )); then
            local eta_minutes=$((remaining / 60))
            eta_str=" (ETA: ${eta_minutes}m)"
        else
            local eta_hours=$((remaining / 3600))
            eta_str=" (ETA: ${eta_hours}h)"
        fi
    fi

    # Format output
    if is_ci; then
        echo "${percentage}% - Elapsed: ${elapsed_str}${eta_str}"
    else
        echo "${PROGRESS_BLUE}${percentage}%${PROGRESS_RESET} - ${PROGRESS_YELLOW}Elapsed: ${elapsed_str}${PROGRESS_RESET}${eta_str}"
    fi
}

# progress_cleanup - Clean up progress displays and processes
progress_cleanup() {
    # Kill spinner if running
    if [[ -n "$PROGRESS_SPINNER_PID" ]] && kill -0 "$PROGRESS_SPINNER_PID" 2>/dev/null; then
        kill "$PROGRESS_SPINNER_PID" 2>/dev/null || true
        wait "$PROGRESS_SPINNER_PID" 2>/dev/null || true
    fi

    # Clear any remaining progress line
    if ! is_quiet && ! is_ci; then
        printf "\r\033[K"  # Clear current line
    fi

    PROGRESS_SPINNER_PID=""
}

# Wrapper to start spinner in background and store PID
start_spinner() {
    local message="${1:-Loading}"

    if is_quiet; then
        return 0
    fi

    progress_spinner "$message" &
    PROGRESS_SPINNER_PID=$!
    setup_cleanup_trap
}

# Stop the currently running spinner
stop_spinner() {
    if [[ -n "$PROGRESS_SPINNER_PID" ]] && kill -0 "$PROGRESS_SPINNER_PID" 2>/dev/null; then
        kill "$PROGRESS_SPINNER_PID" 2>/dev/null || true
        wait "$PROGRESS_SPINNER_PID" 2>/dev/null || true
    fi

    # Clear spinner line
    if ! is_quiet && ! is_ci; then
        printf "\r\033[K"
    fi

    PROGRESS_SPINNER_PID=""
}

# Allow script to be run directly for testing or CLI usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If run directly, allow calling functions from command line
    "$@"
fi

# Note: Functions are defined in this file and available when sourced
# Test compatibility: Some tests may expect functions in subshells,
# but that requires the sourcing context to handle the export.