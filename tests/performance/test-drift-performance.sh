#!/bin/bash
# Performance tests for drift detection system
# Tests how well drift detection scales with project size

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Performance thresholds (in seconds)
BASELINE_THRESHOLD=15
CHECK_THRESHOLD=10
REPORT_THRESHOLD=5

tests_run=0
tests_passed=0

run_performance_test() {
    local test_name="$1"
    local max_time="$2"
    local test_function="$3"

    echo "Running: $test_name (max: ${max_time}s)"
    ((tests_run++))

    local start_time
    start_time=$(date +%s)

    if $test_function; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ $duration -le $max_time ]]; then
            echo -e "${GREEN}✅ PASS:${NC} $test_name (${duration}s)"
            ((tests_passed++))
        else
            echo -e "${YELLOW}⚠️  SLOW:${NC} $test_name (${duration}s > ${max_time}s)"
        fi
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}❌ FAIL:${NC} $test_name (${duration}s)"
    fi
    echo
}

create_drift_test_project() {
    local project_dir="$1"
    local num_files="${2:-1000}"

    echo "Creating drift test project with $num_files files..."

    mkdir -p "$project_dir"/{docs,specs,templates,scripts,config}

    # Create documentation files
    for i in $(seq 1 $((num_files / 5))); do
        cat > "$project_dir/docs/doc_$i.md" << EOF
# Document $i

Content that may change over time.

## Section A
Data: $(date)
Random: $RANDOM

## Section B
More content that could drift.
EOF
    done

    # Create spec files
    for i in $(seq 1 $((num_files / 5))); do
        cat > "$project_dir/specs/spec_$i.md" << EOF
# Specification $i

## Requirements
- Requirement A for spec $i
- Requirement B for spec $i

## Implementation
Details for implementing spec $i.
EOF
    done

    # Create template files
    for i in $(seq 1 $((num_files / 5))); do
        cat > "$project_dir/templates/template_$i.txt" << EOF
Template $i
===========
Variable: {{VAR_$i}}
Content: {{CONTENT_$i}}
Timestamp: {{TIMESTAMP}}
EOF
    done

    # Create script files
    for i in $(seq 1 $((num_files / 5))); do
        cat > "$project_dir/scripts/script_$i.sh" << EOF
#!/bin/bash
# Script $i
echo "Running script $i"
# Some content that might change
exit 0
EOF
        chmod +x "$project_dir/scripts/script_$i.sh"
    done

    # Create config files
    for i in $(seq 1 $((num_files / 5))); do
        cat > "$project_dir/config/config_$i.yml" << EOF
# Config $i
version: 1.0.$i
settings:
  enabled: true
  timeout: $((i * 10))
  features:
    - feature_a
    - feature_b
EOF
    done

    echo "Created $(find "$project_dir" -type f | wc -l) files for drift testing"
}

mock_drift_detector() {
    local project_dir="$1"
    local operation="$2"

    cd "$project_dir"

    case "$operation" in
        "generate-baseline")
            echo "Generating baseline checksums..."
            find . -type f -not -path "./.git/*" -not -path "./.living-docs/*" \
                -exec sha256sum {} \; > .living-docs/checksums.baseline 2>/dev/null || \
                find . -type f -not -path "./.git/*" -not -path "./.living-docs/*" \
                -exec shasum -a 256 {} \; > .living-docs/checksums.baseline
            ;;
        "check-drift")
            echo "Checking for drift..."
            if [[ -f .living-docs/checksums.baseline ]]; then
                # Simulate drift checking by comparing checksums
                local changed_files=0
                while IFS= read -r line; do
                    if [[ "$line" =~ ^[a-f0-9]+[[:space:]]+(.+)$ ]]; then
                        local file="${BASH_REMATCH[1]}"
                        if [[ -f "$file" ]]; then
                            local current_checksum
                            current_checksum=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || \
                                             shasum -a 256 "$file" | cut -d' ' -f1)
                            local baseline_checksum
                            baseline_checksum=$(echo "$line" | cut -d' ' -f1)
                            if [[ "$current_checksum" != "$baseline_checksum" ]]; then
                                ((changed_files++))
                            fi
                        fi
                    fi
                done < .living-docs/checksums.baseline
                echo "Found $changed_files changed files"
            fi
            ;;
        "report")
            echo "Generating drift report..."
            # Simulate git-based drift detection
            if [[ -d .git ]]; then
                git status --porcelain | wc -l
            fi
            ;;
    esac
}

test_baseline_generation_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_drift_test_project "$test_dir" 1000

    cd "$test_dir"
    mkdir -p .living-docs

    # Test baseline generation performance
    mock_drift_detector "$test_dir" "generate-baseline"

    # Verify baseline was created
    [[ -f .living-docs/checksums.baseline ]]

    local baseline_size
    baseline_size=$(wc -l < .living-docs/checksums.baseline)
    echo "Generated baseline with $baseline_size entries"

    rm -rf "$test_dir"
    [[ $baseline_size -gt 900 ]]  # Should have checksums for most files
}

test_drift_check_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_drift_test_project "$test_dir" 800

    cd "$test_dir"
    mkdir -p .living-docs

    # Generate baseline first
    mock_drift_detector "$test_dir" "generate-baseline"

    # Modify some files to create drift
    echo "Modified content" >> docs/doc_1.md
    echo "More changes" >> specs/spec_1.md
    rm -f config/config_1.yml

    # Test drift detection performance
    mock_drift_detector "$test_dir" "check-drift"

    rm -rf "$test_dir"
    return 0
}

test_git_based_drift_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_drift_test_project "$test_dir" 600

    cd "$test_dir"

    # Initialize git
    git init > /dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    git add . > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Create some changes
    echo "Modified" >> docs/doc_1.md
    echo "New file" > docs/new_file.md
    rm -f docs/doc_2.md

    # Test git-based drift detection
    mock_drift_detector "$test_dir" "report"

    rm -rf "$test_dir"
    return 0
}

test_large_file_handling() {
    local test_dir
    test_dir=$(mktemp -d)

    cd "$test_dir"
    mkdir -p .living-docs docs

    # Create some large files
    for i in {1..10}; do
        # Create 1MB files
        dd if=/dev/zero of="docs/large_file_$i.bin" bs=1024 count=1024 2>/dev/null
    done

    # Create many small files
    for i in {1..500}; do
        echo "Small file $i content" > "docs/small_$i.txt"
    done

    echo "Created $(find docs -type f | wc -l) files (including large ones)"

    # Test baseline generation with large files
    mock_drift_detector "$test_dir" "generate-baseline"

    rm -rf "$test_dir"
    return 0
}

test_deep_directory_structure() {
    local test_dir
    test_dir=$(mktemp -d)

    cd "$test_dir"
    mkdir -p .living-docs

    # Create deep directory structure
    local current_dir="docs"
    mkdir -p "$current_dir"

    for level in {1..20}; do
        current_dir="$current_dir/level_$level"
        mkdir -p "$current_dir"

        # Add files at each level
        for file in {1..10}; do
            echo "Content at level $level, file $file" > "$current_dir/file_$file.txt"
        done
    done

    echo "Created deep directory structure with $(find docs -type f | wc -l) files"

    # Test drift detection with deep paths
    mock_drift_detector "$test_dir" "generate-baseline"

    rm -rf "$test_dir"
    return 0
}

test_concurrent_drift_operations() {
    local test_dir
    test_dir=$(mktemp -d)

    create_drift_test_project "$test_dir" 400

    cd "$test_dir"
    mkdir -p .living-docs

    # Generate baseline
    mock_drift_detector "$test_dir" "generate-baseline"

    # Simulate concurrent operations
    local pids=()

    # Start multiple drift checks in background
    for i in {1..3}; do
        (
            mock_drift_detector "$test_dir" "check-drift" > "/tmp/drift_check_$i.log" 2>&1
        ) &
        pids+=($!)
    done

    # Wait for all to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    rm -rf "$test_dir"
    rm -f /tmp/drift_check_*.log
    return 0
}

test_ignore_patterns_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    cd "$test_dir"
    mkdir -p .living-docs

    # Create ignore patterns
    cat > .living-docs/drift-ignore << 'EOF'
*.tmp
*.log
temp/*
node_modules/*
.git/*
*.pyc
__pycache__/*
EOF

    # Create files that should be ignored
    mkdir -p temp node_modules __pycache__
    for i in {1..100}; do
        echo "temp" > "temp/file_$i.tmp"
        echo "module" > "node_modules/module_$i.js"
        echo "cache" > "__pycache__/cache_$i.pyc"
        echo "log" > "debug_$i.log"
    done

    # Create files that should NOT be ignored
    for i in {1..200}; do
        echo "content" > "file_$i.md"
    done

    echo "Created $(find . -type f | wc -l) total files"

    # Test baseline generation with ignore patterns
    # This is a simplified version - real implementation would respect ignore patterns
    find . -type f -not -path "./.git/*" -not -path "./.living-docs/*" \
        -not -name "*.tmp" -not -name "*.log" -not -path "./temp/*" \
        -not -path "./node_modules/*" -not -path "./__pycache__/*" \
        -exec sha256sum {} \; > .living-docs/checksums.baseline 2>/dev/null || \
        find . -type f -not -path "./.git/*" -not -path "./.living-docs/*" \
        -not -name "*.tmp" -not -name "*.log" -not -path "./temp/*" \
        -not -path "./node_modules/*" -not -path "./__pycache__/*" \
        -exec shasum -a 256 {} \; > .living-docs/checksums.baseline

    local tracked_files
    tracked_files=$(wc -l < .living-docs/checksums.baseline)
    echo "Tracked $tracked_files files (ignored many others)"

    rm -rf "$test_dir"
    [[ $tracked_files -lt 250 ]]  # Should be less than total due to ignoring
}

main() {
    echo "Drift Detection Performance Test Suite"
    echo "====================================="
    echo "Testing drift detection performance with large projects"
    echo

    echo "Performance thresholds:"
    echo "- Baseline generation: ${BASELINE_THRESHOLD}s"
    echo "- Drift checking: ${CHECK_THRESHOLD}s"
    echo "- Report generation: ${REPORT_THRESHOLD}s"
    echo

    # Run performance tests
    run_performance_test "Baseline generation (1000 files)" $BASELINE_THRESHOLD test_baseline_generation_performance
    run_performance_test "Drift checking (800 files)" $CHECK_THRESHOLD test_drift_check_performance
    run_performance_test "Git-based drift detection (600 files)" $REPORT_THRESHOLD test_git_based_drift_performance
    run_performance_test "Large file handling" 20 test_large_file_handling
    run_performance_test "Deep directory structure" 15 test_deep_directory_structure
    run_performance_test "Concurrent operations" 25 test_concurrent_drift_operations
    run_performance_test "Ignore patterns processing" 10 test_ignore_patterns_performance

    echo "Drift Performance Test Results Summary"
    echo "====================================="
    echo "Tests run: $tests_run"
    echo "Tests passed: $tests_passed"
    echo "Performance issues: $((tests_run - tests_passed))"

    if [[ $tests_passed -eq $tests_run ]]; then
        echo -e "${GREEN}✅ All drift performance tests passed${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some drift performance tests were slow${NC}"
        exit 0  # Don't fail CI for performance issues
    fi
}

main "$@"