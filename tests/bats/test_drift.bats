#!/usr/bin/env bats
# Comprehensive drift detection tests for TDD implementation

load test_helper

# Test setup - create mock drift detector
setup() {
    # Set up test environment like test_helper but without loading it
    export TEST_DIR="$(mktemp -d)"
    export LIVING_DOCS_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    export PATH="$LIVING_DOCS_ROOT/lib:$PATH"
    cd "$TEST_DIR" || exit 1

    # Create a test project structure
    mkdir -p "docs"
    mkdir -p "lib/drift"
    mkdir -p ".living-docs"

    # Create baseline files
    echo "# Main docs" > "docs/main.md"
    echo "# Current status" > "docs/current.md"
    echo "config: basic" > ".living-docs/config.yml"

    # Create mock detector script path
    export DRIFT_DETECTOR="$LIVING_DOCS_ROOT/lib/drift/detector.sh"
    export TEST_PROJECT_ROOT="$TEST_DIR"
}

# Clean up after tests
teardown() {
    # Return to original directory
    cd "$LIVING_DOCS_ROOT" || exit 1

    # Clean up test directory if it exists
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
}

# === BASIC DETECTOR EXISTENCE TESTS ===

@test "drift detector script exists" {
    [[ -f "$DRIFT_DETECTOR" ]]
}

@test "drift detector is executable" {
    [[ -x "$DRIFT_DETECTOR" ]]
}

# === MODIFIED FILES DETECTION ===

@test "detects modified files from git status" {
    # Initialize git repo with baseline
    git init
    git add .
    git commit -m "Initial commit"

    # Modify a file
    echo "Modified content" >> docs/main.md

    # Run drift detector
    run bash "$DRIFT_DETECTOR" --check-modified

    [ "$status" -eq 1 ]  # Should exit with error code for drift detected
    assert_output_contains "docs/main.md"
    assert_output_contains "MODIFIED"
}

@test "detects multiple modified files" {
    git init
    git add .
    git commit -m "Initial commit"

    # Modify multiple files
    echo "Modified" >> docs/main.md
    echo "Also modified" >> docs/current.md

    run bash "$DRIFT_DETECTOR" --check-modified

    [ "$status" -eq 1 ]
    assert_output_contains "docs/main.md"
    assert_output_contains "docs/current.md"
}

@test "returns clean status when no files modified" {
    git init
    git add .
    git commit -m "Initial commit"

    run bash "$DRIFT_DETECTOR" --check-modified

    [ "$status" -eq 0 ]
    assert_output_contains "No modified files detected"
}

# === ADDED/REMOVED FILES DETECTION ===

@test "detects newly added files" {
    git init
    git add .
    git commit -m "Initial commit"

    # Add new file
    echo "New content" > docs/new-file.md

    run bash "$DRIFT_DETECTOR" --check-added

    [ "$status" -eq 1 ]
    assert_output_contains "docs/new-file.md"
    assert_output_contains "ADDED"
}

@test "detects removed files" {
    git init
    git add .
    git commit -m "Initial commit"

    # Remove a file
    rm docs/main.md

    run bash "$DRIFT_DETECTOR" --check-removed

    [ "$status" -eq 1 ]
    assert_output_contains "docs/main.md"
    assert_output_contains "REMOVED"
}

@test "detects both added and removed files in combined check" {
    git init
    git add .
    git commit -m "Initial commit"

    # Add and remove files
    echo "New content" > docs/new-file.md
    rm docs/current.md

    run bash "$DRIFT_DETECTOR" --check-all-changes

    [ "$status" -eq 1 ]
    assert_output_contains "docs/new-file.md"
    assert_output_contains "ADDED"
    assert_output_contains "docs/current.md"
    assert_output_contains "REMOVED"
}

# === CHECKSUM-BASED DRIFT DETECTION ===

@test "generates baseline checksums" {
    run bash "$DRIFT_DETECTOR" --generate-baseline

    [ "$status" -eq 0 ]
    assert_file_exists ".living-docs/checksums.baseline"

    # Verify checksum format
    run cat .living-docs/checksums.baseline
    assert_output_contains "docs/main.md"
    assert_output_contains "docs/current.md"
}

@test "detects drift via checksum comparison" {
    # Generate baseline
    bash "$DRIFT_DETECTOR" --generate-baseline

    # Modify file content
    echo "Additional content" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --check-checksums

    [ "$status" -eq 1 ]
    assert_output_contains "docs/main.md"
    assert_output_contains "CHECKSUM_MISMATCH"
}

@test "checksum validation passes when no changes" {
    # Generate baseline
    bash "$DRIFT_DETECTOR" --generate-baseline

    run bash "$DRIFT_DETECTOR" --check-checksums

    [ "$status" -eq 0 ]
    assert_output_contains "All checksums valid"
}

@test "handles missing baseline gracefully" {
    run bash "$DRIFT_DETECTOR" --check-checksums

    [ "$status" -eq 2 ]  # Different error code for missing baseline
    assert_output_contains "No baseline checksums found"
    assert_output_contains "Run --generate-baseline first"
}

@test "excludes ignored files from checksum generation" {
    # Create ignore file
    echo "*.tmp" > .living-docs/drift-ignore
    echo "temp/*" >> .living-docs/drift-ignore

    # Create files that should be ignored
    echo "temp content" > docs/temp.tmp
    mkdir -p temp
    echo "temp dir content" > temp/file.md

    run bash "$DRIFT_DETECTOR" --generate-baseline

    [ "$status" -eq 0 ]

    # Verify ignored files are not in baseline
    run cat .living-docs/checksums.baseline
    [[ "$output" != *"temp.tmp"* ]]
    [[ "$output" != *"temp/file.md"* ]]
}

# === AUTOMATIC DRIFT FIXING ===

@test "fixes drift by updating baseline checksums" {
    # Generate initial baseline
    bash "$DRIFT_DETECTOR" --generate-baseline

    # Modify files
    echo "Modified" >> docs/main.md
    echo "New file" > docs/new.md

    # Fix drift
    run bash "$DRIFT_DETECTOR" --fix-drift

    [ "$status" -eq 0 ]
    assert_output_contains "Updated baseline checksums"

    # Verify checksums now pass
    run bash "$DRIFT_DETECTOR" --check-checksums
    [ "$status" -eq 0 ]
}

@test "fixes drift by restoring from git" {
    git init
    git add .
    git commit -m "Initial commit"

    # Modify files
    echo "Unwanted changes" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --fix-drift --restore-from-git

    [ "$status" -eq 0 ]
    assert_output_contains "Restored from git"

    # Verify file is restored
    run cat docs/main.md
    [[ "$output" != *"Unwanted changes"* ]]
}

@test "provides dry-run option for drift fixing" {
    bash "$DRIFT_DETECTOR" --generate-baseline
    echo "Modified" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --fix-drift --dry-run

    [ "$status" -eq 0 ]
    assert_output_contains "DRY RUN"
    assert_output_contains "Would update baseline"

    # Verify nothing actually changed
    run bash "$DRIFT_DETECTOR" --check-checksums
    [ "$status" -eq 1 ]  # Should still fail
}

# === DRIFT REPORTING ===

@test "generates detailed drift report" {
    git init
    git add .
    git commit -m "Initial commit"

    # Create various types of drift
    echo "Modified" >> docs/main.md
    echo "New content" > docs/new.md
    rm docs/current.md

    run bash "$DRIFT_DETECTOR" --report

    [ "$status" -eq 1 ]
    assert_output_contains "DRIFT REPORT"
    assert_output_contains "Modified files: 1"
    assert_output_contains "Added files: 1"
    assert_output_contains "Removed files: 1"
    assert_output_contains "docs/main.md (MODIFIED)"
    assert_output_contains "docs/new.md (ADDED)"
    assert_output_contains "docs/current.md (REMOVED)"
}

@test "generates JSON report format" {
    git init
    git add .
    git commit -m "Initial commit"

    echo "Modified" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --report --format=json

    [ "$status" -eq 1 ]

    # Basic JSON validation
    echo "$output" | python3 -m json.tool > /dev/null
    [ $? -eq 0 ]

    assert_output_contains '"modified_files"'
    assert_output_contains '"docs/main.md"'
    assert_output_contains '"status": "MODIFIED"'
}

@test "saves report to file" {
    git init
    git add .
    git commit -m "Initial commit"

    echo "Modified" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --report --output=drift-report.txt

    [ "$status" -eq 1 ]
    assert_file_exists "drift-report.txt"

    run cat drift-report.txt
    assert_output_contains "DRIFT REPORT"
    assert_output_contains "docs/main.md"
}

# === INTEGRATION WITH LIVING-DOCS CONFIG ===

@test "respects living-docs configuration" {
    # Create config with custom ignore patterns
    cat > .living-docs/config.yml << EOF
drift:
  ignore:
    - "*.log"
    - "temp/*"
  baseline_path: "custom-baseline.sha256"
  auto_fix: false
EOF

    # Create files matching ignore patterns
    echo "log content" > debug.log
    mkdir -p temp
    echo "temp content" > temp/file.md

    run bash "$DRIFT_DETECTOR" --generate-baseline

    [ "$status" -eq 0 ]
    assert_file_exists ".living-docs/custom-baseline.sha256"

    # Verify ignored files are not tracked
    run cat .living-docs/custom-baseline.sha256
    [[ "$output" != *"debug.log"* ]]
    [[ "$output" != *"temp/file.md"* ]]
}

@test "validates configuration format" {
    # Create invalid config
    echo "invalid: yaml: content:" > .living-docs/config.yml

    run bash "$DRIFT_DETECTOR" --check-config

    [ "$status" -eq 1 ]
    assert_output_contains "Invalid configuration"
}

# === PERFORMANCE AND LARGE FILES ===

@test "handles large number of files efficiently" {
    # Create many files
    for i in {1..100}; do
        echo "Content $i" > "docs/file$i.md"
    done

    # Time the baseline generation
    start_time=$(date +%s)
    run bash "$DRIFT_DETECTOR" --generate-baseline
    end_time=$(date +%s)

    [ "$status" -eq 0 ]

    # Should complete within reasonable time (10 seconds)
    duration=$((end_time - start_time))
    [ "$duration" -lt 10 ]
}

@test "provides progress indication for large operations" {
    # Create many files
    for i in {1..50}; do
        echo "Content $i" > "docs/file$i.md"
    done

    run bash "$DRIFT_DETECTOR" --generate-baseline --verbose

    [ "$status" -eq 0 ]
    assert_output_contains "Processing"
    assert_output_contains "files"
}

# === ERROR HANDLING ===

@test "handles missing git repository gracefully" {
    # Remove git if it exists
    rm -rf .git

    run bash "$DRIFT_DETECTOR" --check-modified

    [ "$status" -eq 2 ]
    assert_output_contains "Not a git repository"
    assert_output_contains "Initialize git or use --no-git option"
}

@test "handles permission errors gracefully" {
    bash "$DRIFT_DETECTOR" --generate-baseline

    # Make baseline unwritable
    chmod 444 .living-docs/checksums.baseline

    echo "Modified" >> docs/main.md

    run bash "$DRIFT_DETECTOR" --fix-drift

    [ "$status" -eq 1 ]
    assert_output_contains "Permission denied"
    assert_output_contains "baseline"

    # Cleanup
    chmod 644 .living-docs/checksums.baseline
}

@test "validates command line arguments" {
    run bash "$DRIFT_DETECTOR" --invalid-option

    [ "$status" -eq 1 ]
    assert_output_contains "Unknown option"
    assert_output_contains "Usage:"
}

@test "shows help message" {
    run bash "$DRIFT_DETECTOR" --help

    [ "$status" -eq 0 ]
    assert_output_contains "Usage:"
    assert_output_contains "OPTIONS:"
    assert_output_contains "--check-modified"
    assert_output_contains "--generate-baseline"
    assert_output_contains "--fix-drift"
}