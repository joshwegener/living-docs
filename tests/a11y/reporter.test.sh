#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source test framework
source "$PROJECT_ROOT/tests/test-framework.sh"

# Source module to test
source "$PROJECT_ROOT/lib/a11y/reporter.sh"

# Test generate_report
test_generate_report() {
    local test_output_dir="$TEST_TMP_DIR/report_output"
    mkdir -p "$test_output_dir"

    local test_issues="Missing alt text:img:10:critical
Poor color contrast:div:20:warning
Consider heading hierarchy:h3:5:info"

    generate_report "$test_output_dir" "text" "$test_issues"

    # Check if report file exists with timestamp
    local report_files
    report_files=$(ls "$test_output_dir"/accessibility_report_*.txt 2>/dev/null | head -1)

    assert_not_empty "$report_files" \
        "Text report should be generated"

    local content
    content=$(cat "$report_files")
    assert_contains "$content" "Accessibility Report" \
        "Report should have title"
    assert_contains "$content" "Critical" \
        "Report should contain critical issues"
}

# Test generate_html_report
test_generate_html_report() {
    local test_output_dir="$TEST_TMP_DIR/html_output"
    mkdir -p "$test_output_dir"

    local test_file="$test_output_dir/test.html"
    local test_issues="Missing alt text:img:10:critical"

    generate_html_report "$test_file" "$test_issues"

    assert_file_exists "$test_file" \
        "HTML report should be generated"

    local content
    content=$(cat "$test_file")
    assert_contains "$content" "<!DOCTYPE html>" \
        "Should be valid HTML"
    assert_contains "$content" "Accessibility Report" \
        "Should have title"
}

# Test generate_json_report
test_generate_json_report() {
    local test_output_dir="$TEST_TMP_DIR/json_output"
    mkdir -p "$test_output_dir"

    local test_issues="Missing alt text:img:10:critical"

    local json_output
    json_output=$(generate_a11y_report_json "$test_issues")

    assert_contains "$json_output" '"timestamp"' \
        "JSON should contain timestamp"
    assert_contains "$json_output" '"accessibility"' \
        "JSON should contain accessibility object"
}

# Test generate_csv_report
test_generate_csv_report() {
    local test_output_dir="$TEST_TMP_DIR/csv_output"
    mkdir -p "$test_output_dir"

    local test_file="$test_output_dir/test.csv"
    local test_issues="Missing alt text:img:10:critical"

    generate_csv_report "$test_file" "$test_issues"

    assert_file_exists "$test_file" \
        "CSV report should be generated"

    local content
    content=$(cat "$test_file")
    assert_contains "$content" "Issue,Element,Line,Severity" \
        "CSV should have headers"
}

# Test generate_text_report
test_generate_text_report() {
    local test_output_dir="$TEST_TMP_DIR/text_output"
    mkdir -p "$test_output_dir"

    local test_file="$test_output_dir/test.txt"
    local test_issues="Missing alt text:img:10:critical"

    generate_text_report "$test_file" "$test_issues"

    assert_file_exists "$test_file" \
        "Text report should be generated"

    local content
    content=$(cat "$test_file")
    assert_contains "$content" "Accessibility Report" \
        "Should have title"
}

# Test report format selection
test_report_format_selection() {
    local test_output_dir="$TEST_TMP_DIR/format_test"
    mkdir -p "$test_output_dir"

    local test_issues="Missing alt text:img:10:critical"

    # Test each format
    for format in text html json csv; do
        generate_report "$test_output_dir" "$format" "$test_issues"

        # Check that at least one report file was created
        local report_count
        report_count=$(ls "$test_output_dir"/accessibility_report_* 2>/dev/null | wc -l)
        assert_gt "$report_count" 0 "Report should be generated for format: $format"

        rm -f "$test_output_dir"/accessibility_report_*
    done
}

# Run tests
run_test_suite "A11y Reporter Tests" \
    test_generate_report \
    test_generate_html_report \
    test_generate_json_report \
    test_generate_csv_report \
    test_generate_text_report \
    test_report_format_selection