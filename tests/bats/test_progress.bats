#!/usr/bin/env bats

load test_helper

setup() {
    # Standard test setup
    export TEST_DIR="$(mktemp -d)"
    export LIVING_DOCS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    export PATH="$LIVING_DOCS_ROOT/lib:$PATH"

    # Progress-specific setup
    export PROGRESS_LIB="$LIVING_DOCS_ROOT/lib/ui/progress.sh"
    export TERM="xterm-256color"  # Ensure color support for tests
    cd "$TEST_DIR" || exit 1
}

teardown() {
    cd "$LIVING_DOCS_ROOT" || exit 1
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper to source progress library (once it exists)
load_progress_lib() {
    if [[ -f "$PROGRESS_LIB" ]]; then
        source "$PROGRESS_LIB"
    else
        skip "progress.sh not implemented yet"
    fi
}

@test "progress library exists and is sourceable" {
    assert_file_exists "$PROGRESS_LIB"
    run source "$PROGRESS_LIB"
    assert_success
}

@test "progress_bar function exists" {
    load_progress_lib
    run type progress_bar
    assert_success
    assert_output_contains "progress_bar is a function"
}

@test "progress_bar displays basic progress bar" {
    load_progress_lib

    # Test 50% progress
    run progress_bar 50 100
    assert_success
    assert_output_contains "["
    assert_output_contains "]"
    assert_output_contains "50%"
}

@test "progress_bar handles edge cases" {
    load_progress_lib

    # Test 0% progress
    run progress_bar 0 100
    assert_success
    assert_output_contains "0%"

    # Test 100% progress
    run progress_bar 100 100
    assert_success
    assert_output_contains "100%"

    # Test invalid values (should handle gracefully)
    run progress_bar -10 100
    assert_success

    run progress_bar 150 100
    assert_success
}

@test "progress_bar with custom width" {
    load_progress_lib

    # Test custom width parameter
    run progress_bar 50 100 20
    assert_success

    # Test very narrow width
    run progress_bar 50 100 5
    assert_success
}

@test "progress_bar with custom message" {
    load_progress_lib

    run progress_bar 50 100 40 "Processing files"
    assert_success
    assert_output_contains "Processing files"
    assert_output_contains "50%"
}

@test "spinner function exists and works" {
    load_progress_lib

    run type progress_spinner
    assert_success
    assert_output_contains "progress_spinner is a function"
}

@test "spinner displays animation characters" {
    load_progress_lib

    # Test spinner with short duration
    timeout 2s bash -c "progress_spinner 'Loading' &
                        SPINNER_PID=\$!
                        sleep 0.5
                        kill \$SPINNER_PID 2>/dev/null || true
                        wait \$SPINNER_PID 2>/dev/null || true" > spinner_output.txt

    # Check that spinner output contains expected characters
    run cat spinner_output.txt
    # Should contain spinner chars: | / - \
    [[ "$output" == *"|"* ]] || [[ "$output" == *"/"* ]] || [[ "$output" == *"-"* ]] || [[ "$output" == *"\\"* ]]
}

@test "spinner with custom message" {
    load_progress_lib

    timeout 1s bash -c "progress_spinner 'Custom message' &
                        SPINNER_PID=\$!
                        sleep 0.2
                        kill \$SPINNER_PID 2>/dev/null || true
                        wait \$SPINNER_PID 2>/dev/null || true" > spinner_output.txt

    run cat spinner_output.txt
    assert_output_contains "Custom message"
}

@test "percentage_progress function exists" {
    load_progress_lib

    run type percentage_progress
    assert_success
    assert_output_contains "percentage_progress is a function"
}

@test "percentage_progress displays correct percentages" {
    load_progress_lib

    # Test various percentage calculations
    run percentage_progress 25 100
    assert_success
    assert_output_contains "25%"

    run percentage_progress 1 3
    assert_success
    assert_output_contains "33%"

    run percentage_progress 2 3
    assert_success
    assert_output_contains "66%"

    run percentage_progress 3 3
    assert_success
    assert_output_contains "100%"
}

@test "step_progress function exists and works" {
    load_progress_lib

    run type step_progress
    assert_success
    assert_output_contains "step_progress is a function"
}

@test "step_progress displays step information" {
    load_progress_lib

    run step_progress 3 10 "Installing dependencies"
    assert_success
    assert_output_contains "Step 3/10"
    assert_output_contains "Installing dependencies"
    assert_output_contains "30%"
}

@test "step_progress handles edge cases" {
    load_progress_lib

    # First step
    run step_progress 1 5 "Starting"
    assert_success
    assert_output_contains "Step 1/5"
    assert_output_contains "20%"

    # Last step
    run step_progress 5 5 "Finishing"
    assert_success
    assert_output_contains "Step 5/5"
    assert_output_contains "100%"
}

@test "progress functions work in quiet mode" {
    load_progress_lib

    export QUIET=1

    # Progress bar should not output in quiet mode
    run progress_bar 50 100
    assert_success
    [[ -z "$output" ]]

    # Step progress should not output in quiet mode
    run step_progress 2 5 "Test step"
    assert_success
    [[ -z "$output" ]]

    # Percentage should not output in quiet mode
    run percentage_progress 50 100
    assert_success
    [[ -z "$output" ]]
}

@test "progress functions respect NO_COLOR environment" {
    load_progress_lib

    export NO_COLOR=1

    run progress_bar 50 100
    assert_success
    # Output should not contain ANSI color codes
    [[ ! "$output" =~ \x1b ]]
}

@test "progress functions work with color support" {
    load_progress_lib

    unset NO_COLOR
    export TERM="xterm-256color"

    run progress_bar 50 100
    assert_success
    # Should contain progress indicator
    assert_output_contains "50%"
}

@test "multi_step_progress function coordinates multiple steps" {
    load_progress_lib

    run type multi_step_progress
    assert_success
    assert_output_contains "multi_step_progress is a function"
}

@test "multi_step_progress handles step array" {
    load_progress_lib

    # Create a test that simulates multi-step progress
    steps=("Initialize" "Download" "Install" "Configure" "Complete")

    run multi_step_progress 2 "${steps[@]}"
    assert_success
    assert_output_contains "Step 2/5"
    assert_output_contains "Download"
    assert_output_contains "40%"
}

@test "progress_cleanup function exists" {
    load_progress_lib

    run type progress_cleanup
    assert_success
    assert_output_contains "progress_cleanup is a function"
}

@test "progress_cleanup clears spinner and progress displays" {
    load_progress_lib

    # Test that cleanup function works without errors
    run progress_cleanup
    assert_success
}

@test "progress functions handle terminal width detection" {
    load_progress_lib

    # Test with narrow terminal
    export COLUMNS=40
    run progress_bar 50 100
    assert_success

    # Test with wide terminal
    export COLUMNS=120
    run progress_bar 50 100
    assert_success

    # Test with no COLUMNS set (should detect or default)
    unset COLUMNS
    run progress_bar 50 100
    assert_success
}

@test "progress indicators work in CI environment" {
    load_progress_lib

    export CI=true

    # In CI, progress should still work but may be simplified
    run progress_bar 50 100
    assert_success
    assert_output_contains "50%"

    run step_progress 2 4 "CI Test"
    assert_success
    assert_output_contains "Step 2/4"
}

@test "progress functions are interrupt-safe" {
    load_progress_lib

    # Test that progress functions handle SIGINT gracefully
    timeout 1s bash -c "
        progress_spinner 'Testing interrupt' &
        SPINNER_PID=\$!
        sleep 0.3
        kill -INT \$SPINNER_PID 2>/dev/null || true
        wait \$SPINNER_PID 2>/dev/null || true
        echo 'Cleanup successful'
    " > interrupt_test.txt

    run cat interrupt_test.txt
    # Should complete without hanging
    assert_output_contains "Cleanup successful"
}

@test "elapsed_time_progress shows time information" {
    load_progress_lib

    run type elapsed_time_progress
    assert_success
    assert_output_contains "elapsed_time_progress is a function"
}

@test "elapsed_time_progress calculates duration" {
    load_progress_lib

    # Test with start time (simulate 30 seconds elapsed)
    start_time=$(($(date +%s) - 30))
    run elapsed_time_progress "$start_time" 50 100
    assert_success
    assert_output_contains "50%"
    assert_output_contains "30s"
}