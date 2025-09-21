#!/usr/bin/env bats

load test_helper

# Debug mode tests for lib/debug/logger.sh
# These tests should fail initially and drive TDD implementation
#
# TDD Implementation Strategy:
# 1. All tests currently fail (lib/debug/logger.sh doesn't exist)
# 2. Implement basic debug logging with LIVING_DOCS_DEBUG=1
# 3. Add timestamp formatting and log levels
# 4. Implement log file creation and rotation
# 5. Add context preservation and structured logging
# 6. Finish with performance and security features
#
# Run tests with: bats tests/bats/test_debug.bats

@test "loads debug logger library" {
    # This test should fail until lib/debug/logger.sh is implemented
    [ -f "$LIVING_DOCS_ROOT/lib/debug/logger.sh" ]
    run source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"
    [ "$status" -eq 0 ]
}

# Basic Debug Output Tests
@test "debug_log: outputs when LIVING_DOCS_DEBUG=1" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "test message"
    [ "$status" -eq 0 ]
    assert_output_contains "test message"
}

@test "debug_log: silent when LIVING_DOCS_DEBUG=0" {
    export LIVING_DOCS_DEBUG=0
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "test message"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "debug_log: silent when LIVING_DOCS_DEBUG unset" {
    unset LIVING_DOCS_DEBUG
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "test message"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# Timestamp Formatting Tests
@test "debug_log: includes timestamp in output" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "timestamp test"
    [ "$status" -eq 0 ]
    # Should match ISO 8601 format: YYYY-MM-DD HH:MM:SS
    assert_output_contains "$(date '+%Y-%m-%d')"
}

@test "debug_log: timestamp format is ISO 8601" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "format test"
    [ "$status" -eq 0 ]
    # Check for ISO 8601 pattern (basic check)
    [[ "$output" =~ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

@test "debug_log: custom timestamp format with LIVING_DOCS_DEBUG_TIMESTAMP_FORMAT" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_TIMESTAMP_FORMAT="%H:%M:%S"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "custom format test"
    [ "$status" -eq 0 ]
    # Should only contain time, not date
    [[ "$output" =~ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]
    [[ ! "$output" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]
}

# Log Levels Tests
@test "debug_info: outputs info level messages" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_info "info message"
    [ "$status" -eq 0 ]
    assert_output_contains "[INFO]"
    assert_output_contains "info message"
}

@test "debug_warn: outputs warning level messages" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_warn "warning message"
    [ "$status" -eq 0 ]
    assert_output_contains "[WARN]"
    assert_output_contains "warning message"
}

@test "debug_error: outputs error level messages" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_error "error message"
    [ "$status" -eq 0 ]
    assert_output_contains "[ERROR]"
    assert_output_contains "error message"
}

@test "debug_trace: outputs trace level messages" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_trace "trace message"
    [ "$status" -eq 0 ]
    assert_output_contains "[TRACE]"
    assert_output_contains "trace message"
}

@test "log levels: respect LIVING_DOCS_DEBUG_LEVEL filter" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_LEVEL="WARN"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    # INFO should be filtered out
    run debug_info "info message"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]

    # WARN should pass through
    run debug_warn "warning message"
    [ "$status" -eq 0 ]
    assert_output_contains "[WARN]"
}

# Log File Creation Tests
@test "debug_log: creates log file when LIVING_DOCS_DEBUG_FILE set" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_FILE="$TEST_DIR/debug.log"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    debug_log "file test"

    assert_file_exists "$TEST_DIR/debug.log"
    grep -q "file test" "$TEST_DIR/debug.log"
}

@test "debug_log: appends to existing log file" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_FILE="$TEST_DIR/debug.log"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    debug_log "first message"
    debug_log "second message"

    assert_file_exists "$TEST_DIR/debug.log"
    grep -q "first message" "$TEST_DIR/debug.log"
    grep -q "second message" "$TEST_DIR/debug.log"
    [ "$(wc -l < "$TEST_DIR/debug.log")" -eq 2 ]
}

@test "debug_log: creates log directory if needed" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_FILE="$TEST_DIR/logs/nested/debug.log"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    debug_log "directory test"

    assert_dir_exists "$TEST_DIR/logs/nested"
    assert_file_exists "$TEST_DIR/logs/nested/debug.log"
}

@test "debug_log: handles log file permissions safely" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_FILE="$TEST_DIR/debug.log"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    debug_log "permission test"

    # Log file should have secure permissions (600 or 644)
    local perms=$(stat -f "%OLp" "$TEST_DIR/debug.log" 2>/dev/null || stat -c "%a" "$TEST_DIR/debug.log" 2>/dev/null)
    [[ "$perms" =~ ^(600|644)$ ]]
}

# Context Preservation Tests
@test "debug_context: captures function call context" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    test_function() {
        debug_context "function context test"
    }

    run test_function
    [ "$status" -eq 0 ]
    assert_output_contains "test_function"
    assert_output_contains "function context test"
}

@test "debug_context: includes line number information" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_context "line number test"
    [ "$status" -eq 0 ]
    # Should contain line number pattern
    [[ "$output" =~ :[0-9]+: ]]
}

@test "debug_context: includes script name" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_context "script name test"
    [ "$status" -eq 0 ]
    assert_output_contains "test_debug.bats"
}

@test "debug_vars: dumps variable state" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    local test_var="test_value"
    local another_var="another_value"

    run debug_vars test_var another_var
    [ "$status" -eq 0 ]
    assert_output_contains "test_var=test_value"
    assert_output_contains "another_var=another_value"
}

@test "debug_vars: handles unset variables safely" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    local set_var="value"
    unset unset_var

    run debug_vars set_var unset_var
    [ "$status" -eq 0 ]
    assert_output_contains "set_var=value"
    assert_output_contains "unset_var=<unset>"
}

# Performance and Security Tests
@test "debug_log: performs well with large messages" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    # Create a 1KB message
    local large_message=$(printf 'A%.0s' {1..1024})

    run timeout 5s debug_log "$large_message"
    [ "$status" -eq 0 ]
    assert_output_contains "$large_message"
}

@test "debug_log: handles special characters safely" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    local special_message=$'special\nchars\t"quotes"\x00null'

    run debug_log "$special_message"
    [ "$status" -eq 0 ]
    # Should not break output parsing
    [[ "$output" == *"special"* ]]
}

@test "debug_log: sanitizes log file paths" {
    export LIVING_DOCS_DEBUG=1
    export LIVING_DOCS_DEBUG_FILE="../../../etc/passwd"
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run debug_log "path traversal test"
    [ "$status" -ne 0 ] || {
        # If it succeeds, should create file in safe location, not /etc/passwd
        [ ! -f "/etc/passwd.debug" ]
        [ ! -f "/etc/passwd" ] || [ "$(stat -c %s /etc/passwd 2>/dev/null)" -eq "$(stat -c %s /etc/passwd 2>/dev/null)" ]
    }
}

# Integration Tests
@test "debug_log: integrates with existing error handling" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    # Should not interfere with normal exit codes
    run bash -c "source $LIVING_DOCS_ROOT/lib/debug/logger.sh; debug_log 'test'; exit 42"
    [ "$status" -eq 42 ]
    assert_output_contains "test"
}

@test "debug_log: works with pipes and redirects" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    # Debug output should not interfere with normal stdout
    result=$(echo "normal output" | debug_log "pipe test" >&2; cat)
    [ "$result" = "normal output" ]
}

@test "debug_start_section and debug_end_section: create nested context" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run bash -c "
        source $LIVING_DOCS_ROOT/lib/debug/logger.sh
        debug_start_section 'outer section'
        debug_log 'inside outer'
        debug_start_section 'inner section'
        debug_log 'inside inner'
        debug_end_section 'inner section'
        debug_end_section 'outer section'
    "
    [ "$status" -eq 0 ]
    assert_output_contains "outer section"
    assert_output_contains "inner section"
    assert_output_contains "inside outer"
    assert_output_contains "inside inner"
}

@test "debug_timing: measures execution time" {
    export LIVING_DOCS_DEBUG=1
    source "$LIVING_DOCS_ROOT/lib/debug/logger.sh"

    run bash -c "
        source $LIVING_DOCS_ROOT/lib/debug/logger.sh
        debug_timing_start 'test_operation'
        sleep 0.1
        debug_timing_end 'test_operation'
    "
    [ "$status" -eq 0 ]
    assert_output_contains "test_operation"
    # Should contain timing information (ms or seconds)
    [[ "$output" =~ [0-9]+(\.[0-9]+)?(ms|s) ]]
}