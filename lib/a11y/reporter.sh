#!/bin/bash
# a11y/reporter.sh - Accessibility report generation module
# Extracted from check.sh as part of DEBT-001 refactoring

set -euo pipefail

# Configuration
readonly DEFAULT_OUTPUT_DIR="reports/accessibility"

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Generate accessibility report (main entry)
generate_a11y_report() {
    local issues="${1:-}"

    if [[ -z "$issues" ]]; then
        echo "=== Accessibility Report ==="
        echo "No accessibility issues found ✓"
        return 0
    fi

    echo "=== Accessibility Report ==="
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""

    local critical_count=0
    local warning_count=0
    local info_count=0

    while IFS=: read -r issue element line severity; do
        case "${severity:-warning}" in
            critical) ((critical_count++)) ;;
            warning) ((warning_count++)) ;;
            info) ((info_count++)) ;;
        esac
    done <<< "$issues"

    echo "Summary:"
    echo "  Critical: $critical_count"
    echo "  Warnings: $warning_count"
    echo "  Info: $info_count"
    echo ""

    if [[ $critical_count -gt 0 ]]; then
        echo "Critical Issues:"
        echo "$issues" | grep ":critical$" | while IFS=: read -r issue element line severity; do
            echo "  ✗ $issue on $element at $line"
        done
        echo ""
    fi

    if [[ $warning_count -gt 0 ]]; then
        echo "Warning Issues:"
        echo "$issues" | grep ":warning$" | while IFS=: read -r issue element line severity; do
            echo "  ⚠ $issue on $element at $line"
        done
        echo ""
    fi

    return 0
}

# Generate JSON accessibility report
generate_a11y_report_json() {
    local issues="${1:-}"

    echo "{"
    echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
    echo '  "accessibility": {'

    if [[ -z "$issues" ]]; then
        echo '    "passed": true,'
        echo '    "issues": []'
        echo '  }'
        echo "}"
        return 0
    fi

    echo '    "passed": false,'
    echo '    "issues": ['

    local first=true
    while IFS=: read -r issue element line severity; do
        if [[ "$first" != "true" ]]; then
            echo ","
        fi
        echo -n '      {"issue": "'$issue'", "element": "'$element'", "line": "'${line:-0}'", "severity": "'${severity:-warning}'"}'
        first=false
    done <<< "$issues"

    echo ""
    echo '    ]'
    echo '  }'
    echo "}"

    return 0
}

# Generate HTML report
generate_html_report() {
    local output_file="$1"
    local issues="${2:-}"

    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Accessibility Report</title>
    <style>
        body { font-family: sans-serif; margin: 40px; }
        h1 { color: #333; }
        .summary { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .critical { color: #d00; }
        .warning { color: #f60; }
        .info { color: #06c; }
        .issue { margin: 10px 0; padding: 10px; background: #fff; border-left: 4px solid; }
        .issue.critical { border-color: #d00; }
        .issue.warning { border-color: #f60; }
        .issue.info { border-color: #06c; }
    </style>
</head>
<body>
    <h1>Accessibility Report</h1>
EOF

    echo "    <p><strong>Generated:</strong> $(date)</p>" >> "$output_file"

    if [[ -z "$issues" ]]; then
        echo "    <div class='summary'>✓ No accessibility issues found</div>" >> "$output_file"
    else
        # Parse and display issues
        local critical_count=0
        local warning_count=0

        while IFS=: read -r issue element line severity; do
            case "${severity:-warning}" in
                critical) ((critical_count++)) ;;
                warning) ((warning_count++)) ;;
            esac
        done <<< "$issues"

        cat >> "$output_file" << EOF
    <div class="summary">
        <h2>Summary</h2>
        <p>Critical Issues: <span class="critical">$critical_count</span></p>
        <p>Warnings: <span class="warning">$warning_count</span></p>
    </div>

    <h2>Issues</h2>
EOF

        while IFS=: read -r issue element line severity; do
            echo "    <div class='issue ${severity:-warning}'>" >> "$output_file"
            echo "        <strong>$issue</strong> on &lt;$element&gt; at line $line" >> "$output_file"
            echo "    </div>" >> "$output_file"
        done <<< "$issues"
    fi

    cat >> "$output_file" << 'EOF'
</body>
</html>
EOF
}

# Generate CSV report
generate_csv_report() {
    local output_file="$1"
    local issues="${2:-}"

    # Header
    echo "Issue,Element,Line,Severity,Timestamp" > "$output_file"

    if [[ -n "$issues" ]]; then
        while IFS=: read -r issue element line severity; do
            echo "$issue,$element,${line:-0},${severity:-warning},$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$output_file"
        done <<< "$issues"
    fi
}

# Generate text report
generate_text_report() {
    local output_file="$1"
    local issues="${2:-}"

    generate_a11y_report "$issues" > "$output_file"
}

# Generate report in specified format
generate_report() {
    local output_dir="${1:-$DEFAULT_OUTPUT_DIR}"
    local format="${2:-text}"
    local issues="${3:-}"

    # Create output directory
    mkdir -p "$output_dir"

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="${output_dir}/accessibility_report_${timestamp}"

    # Generate report based on format
    case "$format" in
        html)
            generate_html_report "${report_file}.html" "$issues"
            echo "Report generated: ${report_file}.html"
            ;;
        json)
            generate_a11y_report_json "$issues" > "${report_file}.json"
            echo "Report generated: ${report_file}.json"
            ;;
        csv)
            generate_csv_report "${report_file}.csv" "$issues"
            echo "Report generated: ${report_file}.csv"
            ;;
        text|*)
            generate_text_report "${report_file}.txt" "$issues"
            echo "Report generated: ${report_file}.txt"
            ;;
    esac

    return 0
}

# Export functions
export -f generate_a11y_report
export -f generate_a11y_report_json
export -f generate_html_report
export -f generate_csv_report
export -f generate_text_report
export -f generate_report