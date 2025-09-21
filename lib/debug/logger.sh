#!/usr/bin/env bash
# Debug Logging Library for living-docs
# Comprehensive debug logging with security, performance, and context features
# Supports levels, file output, timing, and context preservation

set -eo pipefail

# Global variables for debug state management
LIVING_DOCS_DEBUG_INITIALIZED=0
LIVING_DOCS_DEBUG_SECTION_DEPTH=0

# Check if we have associative array support (bash 4.0+)
HAVE_ASSOC_ARRAYS=1
if ! declare -A _test_array 2>/dev/null; then
    HAVE_ASSOC_ARRAYS=0
fi

# Initialize timing and section storage
if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
    declare -A LIVING_DOCS_DEBUG_TIMERS
    declare -A LIVING_DOCS_DEBUG_SECTIONS
    declare -A DEBUG_LEVELS
    # Set up debug levels
    DEBUG_LEVELS["ERROR"]=1
    DEBUG_LEVELS["WARN"]=2
    DEBUG_LEVELS["INFO"]=3
    DEBUG_LEVELS["TRACE"]=4
else
    # Use simple variables for older bash
    LIVING_DOCS_DEBUG_TIMERS=""
    LIVING_DOCS_DEBUG_SECTIONS=""
    DEBUG_LEVELS=""
fi

# Initialize debug logging system
_debug_init() {
    [[ $LIVING_DOCS_DEBUG_INITIALIZED -eq 1 ]] && return 0

    # Set default values if not provided
    LIVING_DOCS_DEBUG="${LIVING_DOCS_DEBUG:-0}"
    LIVING_DOCS_DEBUG_LEVEL="${LIVING_DOCS_DEBUG_LEVEL:-TRACE}"
    LIVING_DOCS_DEBUG_TIMESTAMP_FORMAT="${LIVING_DOCS_DEBUG_TIMESTAMP_FORMAT:-%Y-%m-%d %H:%M:%S}"

    # Validate and sanitize log file path if provided
    if [[ -n "${LIVING_DOCS_DEBUG_FILE:-}" ]]; then
        if ! _debug_validate_log_file "$LIVING_DOCS_DEBUG_FILE"; then
            echo "WARNING: Invalid log file path, debug logging disabled" >&2
            LIVING_DOCS_DEBUG=0
            return 1
        fi
    fi

    LIVING_DOCS_DEBUG_INITIALIZED=1
    return 0
}

# Check if debug logging is enabled
_debug_enabled() {
    [[ "${LIVING_DOCS_DEBUG:-0}" == "1" ]]
}

# Check if a log level should be output
_debug_level_enabled() {
    local level="$1"
    local current_level="${LIVING_DOCS_DEBUG_LEVEL:-TRACE}"

    # Get numeric values for comparison
    local level_num=4
    local current_num=4

    if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
        level_num="${DEBUG_LEVELS[$level]:-4}"
        current_num="${DEBUG_LEVELS[$current_level]:-4}"
    else
        # Fallback for older bash
        case "$level" in
            "ERROR") level_num=1 ;;
            "WARN") level_num=2 ;;
            "INFO") level_num=3 ;;
            "TRACE") level_num=4 ;;
        esac
        case "$current_level" in
            "ERROR") current_num=1 ;;
            "WARN") current_num=2 ;;
            "INFO") current_num=3 ;;
            "TRACE") current_num=4 ;;
        esac
    fi

    [[ $level_num -le $current_num ]]
}

# Generate timestamp for log entries
_debug_timestamp() {
    date +"${LIVING_DOCS_DEBUG_TIMESTAMP_FORMAT}"
}

# Sanitize and validate log file path
_debug_validate_log_file() {
    local file_path="$1"

    # Source security library if available
    if [[ -f "${LIVING_DOCS_ROOT:-}/lib/security/paths.sh" ]]; then
        source "${LIVING_DOCS_ROOT}/lib/security/paths.sh"

        # Use security library for validation
        if ! detect_path_traversal "$file_path"; then
            echo "ERROR: Path traversal detected in log file path: $file_path" >&2
            return 1
        fi
    else
        # Basic path traversal check if security library not available
        if [[ "$file_path" =~ \.\. ]]; then
            echo "ERROR: Path traversal detected in log file path: $file_path" >&2
            return 1
        fi
    fi

    # Ensure file path is reasonable length
    if [[ ${#file_path} -gt 4096 ]]; then
        echo "ERROR: Log file path too long: $file_path" >&2
        return 1
    fi

    return 0
}

# Create log file and directory with secure permissions
_debug_ensure_log_file() {
    local file_path="$1"

    # Create directory if needed
    local dir_path
    dir_path=$(dirname "$file_path")
    if [[ ! -d "$dir_path" ]]; then
        if ! mkdir -p "$dir_path"; then
            echo "ERROR: Cannot create log directory: $dir_path" >&2
            return 1
        fi
        # Set secure directory permissions
        chmod 755 "$dir_path"
    fi

    # Create file if it doesn't exist
    if [[ ! -f "$file_path" ]]; then
        if ! touch "$file_path"; then
            echo "ERROR: Cannot create log file: $file_path" >&2
            return 1
        fi
        # Set secure file permissions
        chmod 644 "$file_path"
    fi

    return 0
}

# Escape special characters for safe output
_debug_escape_message() {
    local message="$1"
    # Replace null bytes and other problematic characters
    printf '%s' "$message" | tr '\000\001\002\003\004\005\006\007\010\011\013\014\016\017\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037\177' '?'
}

# Core logging function
_debug_output() {
    local level="$1"
    local message="$2"
    local context="${3:-}"

    # Initialize if needed
    _debug_init || return 0

    # Check if debug is enabled
    _debug_enabled || return 0

    # Check if this level should be output
    _debug_level_enabled "$level" || return 0

    # Build log entry
    local timestamp
    timestamp=$(_debug_timestamp)

    local escaped_message
    escaped_message=$(_debug_escape_message "$message")

    local log_entry
    if [[ -n "$context" ]]; then
        log_entry="$timestamp [$level] $context: $escaped_message"
    else
        log_entry="$timestamp [$level] $escaped_message"
    fi

    # Add section indentation if in nested context
    local indent=""
    if [[ $LIVING_DOCS_DEBUG_SECTION_DEPTH -gt 0 ]]; then
        printf -v indent '%*s' $((LIVING_DOCS_DEBUG_SECTION_DEPTH * 2)) ''
        log_entry="$timestamp [$level] $indent$escaped_message"
    fi

    # Output to stderr (so it doesn't interfere with stdout)
    echo "$log_entry" >&2

    # Also write to file if specified
    if [[ -n "${LIVING_DOCS_DEBUG_FILE:-}" ]]; then
        if _debug_ensure_log_file "$LIVING_DOCS_DEBUG_FILE"; then
            echo "$log_entry" >> "$LIVING_DOCS_DEBUG_FILE" 2>/dev/null || true
        fi
    fi

    return 0
}

# Basic debug logging function
debug_log() {
    local message="$1"
    _debug_output "DEBUG" "$message"
}

# Level-specific logging functions
debug_info() {
    local message="$1"
    _debug_output "INFO" "$message"
}

debug_warn() {
    local message="$1"
    _debug_output "WARN" "$message"
}

debug_error() {
    local message="$1"
    _debug_output "ERROR" "$message"
}

debug_trace() {
    local message="$1"
    _debug_output "TRACE" "$message"
}

# Context-aware logging with function/line information
debug_context() {
    local message="$1"

    # Get caller information
    local func_name="${FUNCNAME[1]:-main}"
    local line_number="${BASH_LINENO[0]:-?}"

    # Try to get script name from various sources
    local script_name="unknown"

    # Check BATS environment first
    if [[ -n "${BATS_TEST_FILENAME:-}" ]]; then
        script_name=$(basename "$BATS_TEST_FILENAME")
    elif [[ -n "${BASH_SOURCE[1]:-}" ]]; then
        script_name=$(basename "${BASH_SOURCE[1]}")
    elif [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        script_name=$(basename "${BASH_SOURCE[0]}")
    fi

    # If we're in a BATS test file path, extract just the filename
    if [[ "$script_name" =~ test.*\.bats$ ]]; then
        script_name=$(basename "$script_name")
    fi

    local context="$script_name:$func_name:$line_number"
    _debug_output "DEBUG" "$message" "$context"
}

# Variable state dumping
debug_vars() {
    local var_names=("$@")

    _debug_enabled || return 0

    for var_name in "${var_names[@]}"; do
        if [[ -n "${!var_name+set}" ]]; then
            local var_value="${!var_name}"
            _debug_output "DEBUG" "$var_name=$var_value"
        else
            _debug_output "DEBUG" "$var_name=<unset>"
        fi
    done
}

# Section management for nested contexts
debug_start_section() {
    local section_name="$1"

    _debug_enabled || return 0

    # Store section start time (use seconds * 1000 + milliseconds)
    local start_time
    if command -v gdate >/dev/null 2>&1; then
        # GNU date (available via brew install coreutils)
        start_time=$(gdate +%s%3N)
    elif date +%N >/dev/null 2>&1; then
        # Linux date with nanoseconds
        start_time=$(date +%s%3N)
    else
        # macOS fallback - use seconds * 1000
        start_time=$(($(date +%s) * 1000))
    fi

    if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
        LIVING_DOCS_DEBUG_SECTIONS["$section_name"]="$start_time"
    else
        # Simple fallback - just track most recent section
        LIVING_DOCS_DEBUG_SECTIONS="$section_name:$start_time"
    fi

    _debug_output "DEBUG" ">>> Starting section: $section_name"
    LIVING_DOCS_DEBUG_SECTION_DEPTH=$((LIVING_DOCS_DEBUG_SECTION_DEPTH + 1))
}

debug_end_section() {
    local section_name="$1"

    _debug_enabled || return 0

    LIVING_DOCS_DEBUG_SECTION_DEPTH=$((LIVING_DOCS_DEBUG_SECTION_DEPTH - 1))
    [[ $LIVING_DOCS_DEBUG_SECTION_DEPTH -lt 0 ]] && LIVING_DOCS_DEBUG_SECTION_DEPTH=0

    # Calculate section duration if we have start time
    local duration_msg=""
    local end_time
    if command -v gdate >/dev/null 2>&1; then
        end_time=$(gdate +%s%3N)
    elif date +%N >/dev/null 2>&1; then
        end_time=$(date +%s%3N)
    else
        end_time=$(($(date +%s) * 1000))
    fi

    if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
        if [[ -n "${LIVING_DOCS_DEBUG_SECTIONS[$section_name]:-}" ]]; then
            local start_time="${LIVING_DOCS_DEBUG_SECTIONS[$section_name]}"
            local duration=$((end_time - start_time))
            duration_msg=" (${duration}ms)"
            unset LIVING_DOCS_DEBUG_SECTIONS["$section_name"]
        fi
    else
        # Simple fallback
        if [[ "$LIVING_DOCS_DEBUG_SECTIONS" =~ ^$section_name:([0-9]+)$ ]]; then
            local start_time="${BASH_REMATCH[1]}"
            local duration=$((end_time - start_time))
            duration_msg=" (${duration}ms)"
            LIVING_DOCS_DEBUG_SECTIONS=""
        fi
    fi

    _debug_output "DEBUG" "<<< Ending section: $section_name$duration_msg"
}

# Performance timing functions
debug_timing_start() {
    local operation_name="$1"

    _debug_enabled || return 0

    # Store start time in milliseconds
    local start_time
    if command -v gdate >/dev/null 2>&1; then
        start_time=$(gdate +%s%3N)
    elif date +%N >/dev/null 2>&1; then
        start_time=$(date +%s%3N)
    else
        start_time=$(($(date +%s) * 1000))
    fi

    if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
        LIVING_DOCS_DEBUG_TIMERS["$operation_name"]="$start_time"
    else
        # Simple fallback - just track most recent timer
        LIVING_DOCS_DEBUG_TIMERS="$operation_name:$start_time"
    fi
    _debug_output "DEBUG" "TIMING: Started $operation_name"
}

debug_timing_end() {
    local operation_name="$1"

    _debug_enabled || return 0

    # Calculate duration
    local start_time=""
    if [[ $HAVE_ASSOC_ARRAYS -eq 1 ]]; then
        start_time="${LIVING_DOCS_DEBUG_TIMERS[$operation_name]:-}"
        if [[ -n "$start_time" ]]; then
            unset LIVING_DOCS_DEBUG_TIMERS["$operation_name"]
        fi
    else
        # Simple fallback
        if [[ "$LIVING_DOCS_DEBUG_TIMERS" =~ ^$operation_name:([0-9]+)$ ]]; then
            start_time="${BASH_REMATCH[1]}"
            LIVING_DOCS_DEBUG_TIMERS=""
        fi
    fi

    if [[ -n "$start_time" ]]; then
        local end_time
        if command -v gdate >/dev/null 2>&1; then
            end_time=$(gdate +%s%3N)
        elif date +%N >/dev/null 2>&1; then
            end_time=$(date +%s%3N)
        else
            end_time=$(($(date +%s) * 1000))
        fi
        local duration=$((end_time - start_time))

        # Format duration appropriately
        local duration_str
        if [[ $duration -ge 1000 ]]; then
            local seconds=$((duration / 1000))
            local remaining_ms=$((duration % 1000))
            if [[ $remaining_ms -eq 0 ]]; then
                duration_str="${seconds}s"
            else
                duration_str="${seconds}.$(printf '%03d' $remaining_ms)s"
            fi
        else
            duration_str="${duration}ms"
        fi

        _debug_output "DEBUG" "TIMING: Completed $operation_name in $duration_str"
    else
        _debug_output "WARN" "TIMING: No start time found for $operation_name"
    fi
}

# Export all debug functions for use in subshells
export -f debug_log debug_info debug_warn debug_error debug_trace
export -f debug_context debug_vars
export -f debug_start_section debug_end_section
export -f debug_timing_start debug_timing_end
export -f _debug_init _debug_enabled _debug_level_enabled _debug_timestamp
export -f _debug_validate_log_file _debug_ensure_log_file _debug_escape_message _debug_output

# Initialize on load
_debug_init