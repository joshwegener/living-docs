#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing race condition and TOCTOU vulnerability prevention

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy security libraries
    cp -r "${BATS_TEST_DIRNAME}/../../lib/security" lib/

    # Create test files
    echo "original" > target.txt
    echo "sensitive" > sensitive.txt
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "security: TOCTOU - file check/use race condition prevention" {
    # THIS TEST WILL FAIL: No TOCTOU prevention
    # Start file validation in background
    {
        sleep 0.01  # Simulate check delay
        validate_file_safe "target.txt"
    } &
    CHECK_PID=$!

    # Race condition: replace file during check
    sleep 0.005
    rm target.txt
    ln -s sensitive.txt target.txt

    wait $CHECK_PID
    STATUS=$?

    [ "$STATUS" -ne 0 ]  # Should detect the race condition

    # Should not read sensitive file (THIS WILL FAIL)
    run cat_file_safely "target.txt"
    [ "$status" -ne 0 ]
}

@test "security: Atomic file operations to prevent races" {
    # THIS TEST WILL FAIL: No atomic operations
    # Try to write to file atomically
    run write_file_atomically "important.txt" "critical data"
    [ "$status" -eq 0 ]

    # File should exist with correct content
    [ -f "important.txt" ]
    grep -q "critical data" important.txt

    # Should use temp file + rename pattern (THIS WILL FAIL)
    [ -f ".important.txt.tmp" ] || [[ "$output" =~ "atomic" ]]
}

@test "security: File locking prevents concurrent modification" {
    # THIS TEST WILL FAIL: No file locking
    # Try to acquire exclusive lock
    {
        acquire_file_lock "shared.txt"
        echo "process1" >> shared.txt
        sleep 0.1
        release_file_lock "shared.txt"
    } &
    PID1=$!

    # Second process tries to write simultaneously
    sleep 0.01
    {
        acquire_file_lock "shared.txt"
        echo "process2" >> shared.txt
        release_file_lock "shared.txt"
    } &
    PID2=$!

    wait $PID1
    wait $PID2

    # Should have both writes in order (THIS WILL FAIL)
    [ $(wc -l < shared.txt) -eq 2 ]
    grep -q "process1" shared.txt
    grep -q "process2" shared.txt
}

@test "security: PID file race condition prevention" {
    # THIS TEST WILL FAIL: No PID file protection
    # Create PID file
    echo $$ > app.pid

    # Another process tries to start
    run check_and_create_pidfile "app.pid"
    [ "$status" -ne 0 ]  # Should detect existing instance

    # Should prevent PID reuse attacks (THIS WILL FAIL)
    echo "99999" > app.pid  # Fake PID
    run check_and_create_pidfile "app.pid"
    [ "$status" -eq 0 ]  # Should detect stale PID
}

@test "security: Directory traversal race prevention" {
    # THIS TEST WILL FAIL: No traversal race prevention
    mkdir -p safe/dir
    echo "data" > safe/dir/file.txt

    # Start directory check
    {
        validate_directory_safe "safe/dir"
        sleep 0.05
        read_directory_files "safe/dir"
    } &
    CHECK_PID=$!

    # Race: replace directory with symlink
    sleep 0.02
    mv safe/dir safe/dir.bak
    ln -s /etc safe/dir

    wait $CHECK_PID
    STATUS=$?

    [ "$STATUS" -ne 0 ]  # Should detect directory change
}

@test "security: Temp file race condition prevention" {
    # THIS TEST WILL FAIL: No secure temp file creation
    # Create temp file securely
    run create_secure_tempfile
    [ "$status" -eq 0 ]

    TEMPFILE="$output"
    [ -f "$TEMPFILE" ]

    # Check permissions (should be 600)
    PERMS=$(stat -c %a "$TEMPFILE" 2>/dev/null || stat -f %A "$TEMPFILE")
    [ "$PERMS" = "600" ]

    # Should use unpredictable names (THIS WILL FAIL)
    [[ "$TEMPFILE" =~ /tmp/.*XXXXXX ]]
}

@test "security: Signal race condition handling" {
    # THIS TEST WILL FAIL: No signal race handling
    # Set up signal handler
    setup_signal_handler() {
        trap 'cleanup_on_signal' SIGTERM SIGINT
        CRITICAL_OPERATION=true
        sleep 0.1
        CRITICAL_OPERATION=false
    }

    # Start critical operation
    setup_signal_handler &
    PID=$!

    # Send signal during critical operation
    sleep 0.01
    kill -TERM $PID 2>/dev/null || true

    wait $PID
    STATUS=$?

    # Should handle signal safely (THIS WILL FAIL)
    [ "$STATUS" -ne 0 ]
    [ -f ".cleanup_completed" ]  # Should have cleaned up
}

@test "security: Database transaction race prevention" {
    # THIS TEST WILL FAIL: No transaction isolation
    # Simulate concurrent transactions
    {
        begin_transaction
        read_value "counter"
        sleep 0.02
        increment_value "counter"
        commit_transaction
    } &
    T1=$!

    {
        sleep 0.01
        begin_transaction
        read_value "counter"
        increment_value "counter"
        commit_transaction
    } &
    T2=$!

    wait $T1
    wait $T2

    # Both increments should succeed (THIS WILL FAIL)
    run get_value "counter"
    [ "$output" -eq 2 ]  # Should be 2, not 1
}

@test "security: Resource cleanup race prevention" {
    # THIS TEST WILL FAIL: No cleanup race prevention
    # Allocate resource
    allocate_resource "resource1"

    # Concurrent cleanup attempts
    {
        cleanup_resource "resource1"
    } &
    C1=$!

    {
        cleanup_resource "resource1"
    } &
    C2=$!

    wait $C1
    STATUS1=$?
    wait $C2
    STATUS2=$?

    # Only one should succeed (THIS WILL FAIL)
    [ $((STATUS1 + STATUS2)) -eq 1 ]
}

@test "security: Cache race condition prevention" {
    # THIS TEST WILL FAIL: No cache race protection
    # Concurrent cache updates
    {
        cache_set "key1" "value1"
    } &
    P1=$!

    {
        cache_set "key1" "value2"
    } &
    P2=$!

    wait $P1
    wait $P2

    # Should have consistent value (THIS WILL FAIL)
    run cache_get "key1"
    [ "$status" -eq 0 ]
    [[ "$output" = "value1" ]] || [[ "$output" = "value2" ]]

    # Should not have corrupted data
    [[ "$output" != "value1value2" ]]
}

@test "security: Lock file stale detection" {
    # THIS TEST WILL FAIL: No stale lock detection
    # Create old lock file
    touch -t 202301010000 app.lock
    echo "99999" > app.lock  # Non-existent PID

    # Should detect and remove stale lock (THIS WILL FAIL)
    run acquire_lock_with_timeout "app.lock" 5
    [ "$status" -eq 0 ]

    # Should have new lock
    [ -f "app.lock" ]
    grep -q "$$" app.lock
}

@test "security: Double-free prevention in cleanup" {
    # THIS TEST WILL FAIL: No double-free prevention
    # Allocate and free resource
    RESOURCE=$(allocate_resource)
    free_resource "$RESOURCE"

    # Try to free again (double-free)
    run free_resource "$RESOURCE"
    [ "$status" -ne 0 ]  # Should detect double-free

    # Should report double-free attempt (THIS WILL FAIL)
    [[ "$output" =~ "already freed" ]] || [[ "$output" =~ "double" ]]
}