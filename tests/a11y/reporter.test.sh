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

    local test_issues="
file.md:10:ERROR:Missing alt text
file.md:20:WARNING:Poor color contrast
other.md:5:INFO:Consider heading hierarchy"

    echo "$test_issues" | generate_report "$test_output_dir" "text"

    assert_file_exists "$test_output_dir/accessibility-report.txt" \
        "Text report should be generated"

    local content
    content=$(cat "$test_output_dir/accessibility-report.txt")
    assert_contains "$content" "Accessibility Report" \
        "Report should have title"
    assert_contains "$content" "ERROR" \
        "Report should contain errors"
}

# Test generate_html_report
test_generate_html_report() {
    local test_output_dir="$TEST_TMP_DIR/html_output"
    mkdir -p "$test_output_dir"

    local test_issues="file.md:10:ERROR:Missing alt text"

    echo "$test_issues" | generate_html_report "$test_output_dir"

    assert_file_exists "$test_output_dir/accessibility-report.html" \
        "HTML report should be generated"

    local content
    content=$(cat "$test_output_dir/accessibility-report.html")
    assert_contains "$content" "<!DOCTYPE html>" \
        "Should be valid HTML"
    assert_contains "$content" "Accessibility Report" \
        "Should have title"
    assert_contains "$content" "Missing alt text" \
        "Should contain issue text"
}

# Test generate_json_report
test_generate_json_report() {
    local test_output_dir="$TEST_TMP_DIR/json_output"
    mkdir -p "$test_output_dir"

    local test_issues="file.md:10:ERROR:Missing alt text"

    echo "$test_issues" | generate_json_report "$test_output_dir"

    assert_file_exists "$test_output_dir/accessibility-report.json" \
        "JSON report should be generated"

    local content
    content=$(cat "$test_output_dir/accessibility-report.json")
    assert_contains "$content" '"timestamp"' \
        "JSON should contain timestamp"
    assert_contains "$content" '"issues"' \
        "JSON should contain issues array"
    assert_contains "$content" '"severity": "ERROR"' \
        "JSON should contain severity field"
}

# Test generate_csv_report
test_generate_csv_report() {
    local test_output_dir="$TEST_TMP_DIR/csv_output"
    mkdir -p "$test_output_dir"

    local test_issues="file.md:10:ERROR:Missing alt text"

    echo "$test_issues" | generate_csv_report "$test_output_dir"

    assert_file_exists "$test_output_dir/accessibility-report.csv" \
        "CSV report should be generated"

    local content
    content=$(cat "$test_output_dir/accessibility-report.csv")
    assert_contains "$content" "File,Line,Severity,Issue" \
        "CSV should have headers"
    assert_contains "$content" "file.md,10,ERROR" \
        "CSV should contain issue data"
}

# Test generate_text_report
test_generate_text_report() {
    local test_output_dir="$TEST_TMP_DIR/text_output"
    mkdir -p "$test_output_dir"

    local test_issues="
file.md:10:ERROR:Missing alt text
file.md:20:WARNING:Poor contrast"

    echo "$test_issues" | generate_text_report "$test_output_dir"

    assert_file_exists "$test_output_dir/accessibility-report.txt" \
        "Text report should be generated"

    local content
    content=$(cat "$test_output_dir/accessibility-report.txt")
    assert_contains "$content" "Total Issues:" \
        "Should show issue count"
    assert_contains "$content" "ERROR" \
        "Should categorize by severity"
}

# Test report format selection
test_report_format_selection() {
    local test_output_dir="$TEST_TMP_DIR/format_test"
    mkdir -p "$test_output_dir"

    local test_issues="file.md:10:ERROR:Test issue"

    # Test each format
    for format in text html json csv; do
        echo "$test_issues" | generate_report "$test_output_dir" "$format"

        case "$format" in
            text) assert_file_exists "$test_output_dir/accessibility-report.txt" ;;
            html) assert_file_exists "$test_output_dir/accessibility-report.html" ;;
            json) assert_file_exists "$test_output_dir/accessibility-report.json" ;;
            csv) assert_file_exists "$test_output_dir/accessibility-report.csv" ;;
        esac

        rm -f "$test_output_dir"/accessibility-report.*
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