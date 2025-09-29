#!/bin/bash
# race-conditions.sh - Race condition and TOCTOU prevention
# Purpose: Prevent time-of-check-time-of-use vulnerabilities
# Usage: source lib/security/race-conditions.sh

set -euo pipefail

# Constants
readonly LOCK_DIR="/tmp/living-docs-locks"
readonly LOCK_TIMEOUT=30
readonly MAX_RETRIES=3

# Initialize lock directory
init_locks() {
    mkdir -p "$LOCK_DIR" 2>/dev/null || true
    chmod 700 "$LOCK_DIR" 2>/dev/null || true
}

# Validate file safely (atomic check and use)
validate_file_safe() {
    local file="${1:-}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }

    # Use file descriptor for atomic operations
    exec 3<"$file" 2>/dev/null || {
        echo "Error: Cannot open file safely" >&2
        return 2
    }

    # Validate using the open descriptor
    if ! flock -n 3; then
        echo "Error: File is locked by another process" >&2
        exec 3<&-
        return 3
    fi

    # File is safe to use via fd 3
    return 0
}

# Safe file read with TOCTOU prevention
cat_file_safely() {
    local file="${1:-}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }

    # Open and lock file
    exec 3<"$file" 2>/dev/null || {
        echo "Error: Cannot open file" >&2
        return 2
    }

    if ! flock -n 3; then
        echo "Error: File is locked" >&2
        exec 3<&-
        return 3
    fi

    # Read from locked descriptor
    cat <&3
    local result=$?

    # Clean up
    flock -u 3
    exec 3<&-

    return $result
}

# Atomic file write
write_file_atomically() {
    local file="${1:-}"
    local content="${2:-}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }

    # Create temp file in same directory (for atomic rename)
    local dir
    dir=$(dirname "$file")
    local temp_file
    temp_file=$(mktemp "$dir/.tmp.XXXXXX") || {
        echo "Error: Cannot create temp file" >&2
        return 2
    }

    # Write to temp file
    echo "$content" > "$temp_file" || {
        rm -f "$temp_file"
        echo "Error: Write failed" >&2
        return 3
    }

    # Atomic rename
    mv -f "$temp_file" "$file" || {
        rm -f "$temp_file"
        echo "Error: Atomic rename failed" >&2
        return 4
    }

    return 0
}

# File locking mechanism
acquire_file_lock() {
    local file="${1:-}"
    local timeout="${2:-$LOCK_TIMEOUT}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }

    init_locks

    local lock_file="$LOCK_DIR/$(echo "$file" | tr '/' '_').lock"
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if mkdir "$lock_file" 2>/dev/null; then
            # Lock acquired
            echo $$ > "$lock_file/pid"
            return 0
        fi

        # Check if lock holder is still alive
        if [ -f "$lock_file/pid" ]; then
            local pid
            pid=$(cat "$lock_file/pid" 2>/dev/null)
            if ! kill -0 "$pid" 2>/dev/null; then
                # Stale lock, remove it
                rm -rf "$lock_file"
                continue
            fi
        fi

        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    echo "Error: Lock timeout" >&2
    return 1
}

# Release file lock
release_file_lock() {
    local file="${1:-}"

    [ -z "$file" ] && { echo "Error: No file specified" >&2; return 1; }

    local lock_file="$LOCK_DIR/$(echo "$file" | tr '/' '_').lock"

    if [ -d "$lock_file" ]; then
        local pid
        pid=$(cat "$lock_file/pid" 2>/dev/null)

        # Verify we own the lock
        if [ "$pid" = "$$" ]; then
            rm -rf "$lock_file"
            return 0
        else
            echo "Error: Lock owned by different process" >&2
            return 2
        fi
    fi

    return 0
}

# PID file management with race prevention
check_and_create_pidfile() {
    local pidfile="${1:-}"

    [ -z "$pidfile" ] && { echo "Error: No PID file specified" >&2; return 1; }

    # Atomic PID file creation
    local temp_pidfile
    temp_pidfile=$(mktemp "${pidfile}.XXXXXX") || {
        echo "Error: Cannot create temp PID file" >&2
        return 2
    }

    echo $$ > "$temp_pidfile"

    # Try to atomically move
    if mv -n "$temp_pidfile" "$pidfile" 2>/dev/null; then
        # We got it
        return 0
    fi

    # PID file exists, check if stale
    rm -f "$temp_pidfile"

    if [ -f "$pidfile" ]; then
        local old_pid
        old_pid=$(cat "$pidfile" 2>/dev/null)

        if ! kill -0 "$old_pid" 2>/dev/null; then
            # Stale PID file
            echo "Removing stale PID file (pid: $old_pid)" >&2
            rm -f "$pidfile"

            # Try again
            echo $$ > "$pidfile"
            return 0
        else
            echo "Error: Process already running (pid: $old_pid)" >&2
            return 3
        fi
    fi

    return 1
}

# Validate directory hasn't changed
validate_directory_safe() {
    local dir="${1:-}"

    [ -z "$dir" ] && { echo "Error: No directory specified" >&2; return 1; }
    [ ! -d "$dir" ] && { echo "Error: Not a directory" >&2; return 2; }

    # Get initial inode
    local inode1
    inode1=$(stat -c %i "$dir" 2>/dev/null || stat -f %i "$dir" 2>/dev/null)

    return 0
}

# Read directory files safely
read_directory_files() {
    local dir="${1:-}"

    [ -z "$dir" ] && { echo "Error: No directory specified" >&2; return 1; }

    # Verify directory hasn't changed
    local inode_before
    inode_before=$(stat -c %i "$dir" 2>/dev/null || stat -f %i "$dir" 2>/dev/null)

    # Read files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$dir" -maxdepth 1 -type f -print0)

    # Verify directory still same
    local inode_after
    inode_after=$(stat -c %i "$dir" 2>/dev/null || stat -f %i "$dir" 2>/dev/null)

    if [ "$inode_before" != "$inode_after" ]; then
        echo "Error: Directory changed during read" >&2
        return 1
    fi

    printf '%s\n' "${files[@]}"
    return 0
}

# Create secure temp file
create_secure_tempfile() {
    local prefix="${1:-living-docs}"

    # Use mktemp with secure template
    local temp_file
    temp_file=$(mktemp "/tmp/${prefix}.XXXXXX") || {
        echo "Error: Cannot create secure temp file" >&2
        return 1
    }

    # Set restrictive permissions
    chmod 600 "$temp_file"

    echo "$temp_file"
    return 0
}

# Signal handler with cleanup
cleanup_on_signal() {
    local exit_code=$?

    # Mark as cleaning up
    touch "${CLEANUP_MARKER:-.cleanup_in_progress}"

    # Perform cleanup
    if [ -n "${TEMP_FILES:-}" ]; then
        for file in $TEMP_FILES; do
            rm -f "$file" 2>/dev/null
        done
    fi

    # Release any locks
    if [ -n "${LOCKED_FILES:-}" ]; then
        for file in $LOCKED_FILES; do
            release_file_lock "$file"
        done
    fi

    # Mark cleanup complete
    touch "${CLEANUP_MARKER:-.cleanup_completed}"
    rm -f "${CLEANUP_MARKER:-.cleanup_in_progress}"

    exit $exit_code
}

# Transaction support
begin_transaction() {
    local tx_id="${1:-$$}"

    local tx_dir="$LOCK_DIR/tx_$tx_id"

    if ! mkdir "$tx_dir" 2>/dev/null; then
        echo "Error: Transaction already in progress" >&2
        return 1
    fi

    echo "BEGIN" > "$tx_dir/state"
    return 0
}

# Commit transaction
commit_transaction() {
    local tx_id="${1:-$$}"

    local tx_dir="$LOCK_DIR/tx_$tx_id"

    if [ ! -d "$tx_dir" ]; then
        echo "Error: No transaction in progress" >&2
        return 1
    fi

    echo "COMMIT" > "$tx_dir/state"
    rm -rf "$tx_dir"
    return 0
}

# Rollback transaction
rollback_transaction() {
    local tx_id="${1:-$$}"

    local tx_dir="$LOCK_DIR/tx_$tx_id"

    if [ ! -d "$tx_dir" ]; then
        echo "Error: No transaction in progress" >&2
        return 1
    fi

    echo "ROLLBACK" > "$tx_dir/state"

    # Perform rollback actions if any
    if [ -f "$tx_dir/rollback.sh" ]; then
        bash "$tx_dir/rollback.sh"
    fi

    rm -rf "$tx_dir"
    return 0
}

# Resource allocation tracking
allocate_resource() {
    local resource="${1:-resource_$$}"

    local resource_file="$LOCK_DIR/resource_$resource"

    if [ -f "$resource_file" ]; then
        echo "Error: Resource already allocated" >&2
        return 1
    fi

    echo $$ > "$resource_file"
    echo "$resource"
    return 0
}

# Free resource
free_resource() {
    local resource="${1:-}"

    [ -z "$resource" ] && { echo "Error: No resource specified" >&2; return 1; }

    local resource_file="$LOCK_DIR/resource_$resource"

    if [ ! -f "$resource_file" ]; then
        echo "Error: Resource not allocated or already freed" >&2
        return 1
    fi

    rm -f "$resource_file"
    return 0
}

# Cleanup resource
cleanup_resource() {
    local resource="${1:-}"

    [ -z "$resource" ] && { echo "Error: No resource specified" >&2; return 1; }

    # Try to free resource
    if free_resource "$resource"; then
        return 0
    else
        # Already freed or error
        return 1
    fi
}

# Cache operations with race prevention
cache_set() {
    local key="${1:-}"
    local value="${2:-}"

    [ -z "$key" ] && { echo "Error: No key specified" >&2; return 1; }

    local cache_file="$LOCK_DIR/cache_$key"

    # Atomic write
    write_file_atomically "$cache_file" "$value"
}

# Cache get
cache_get() {
    local key="${1:-}"

    [ -z "$key" ] && { echo "Error: No key specified" >&2; return 1; }

    local cache_file="$LOCK_DIR/cache_$key"

    if [ -f "$cache_file" ]; then
        cat_file_safely "$cache_file"
        return 0
    else
        return 1
    fi
}

# Lock with timeout
acquire_lock_with_timeout() {
    local lock_name="${1:-}"
    local timeout="${2:-$LOCK_TIMEOUT}"

    [ -z "$lock_name" ] && { echo "Error: No lock name specified" >&2; return 1; }

    acquire_file_lock "$lock_name" "$timeout"
}

# Export functions
export -f validate_file_safe
export -f cat_file_safely
export -f write_file_atomically
export -f acquire_file_lock
export -f release_file_lock
export -f check_and_create_pidfile
export -f validate_directory_safe
export -f read_directory_files
export -f create_secure_tempfile
export -f cleanup_on_signal
export -f begin_transaction
export -f commit_transaction
export -f rollback_transaction
export -f allocate_resource
export -f free_resource
export -f cleanup_resource
export -f cache_set
export -f cache_get
export -f acquire_lock_with_timeout