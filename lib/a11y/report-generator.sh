#!/usr/bin/env bash
# Accessibility report generator module
# Creates reports in various formats (HTML, JSON, CSV, text)

set -euo pipefail

# Generate summary statistics
generate_summary_stats() {
    local error_count="${#A11Y_ERRORS[@]}"
    local warning_count="${#A11Y_WARNINGS[@]}"
    local info_count="${#A11Y_INFO[@]}"

    echo "Errors: $error_count | Warnings: $warning_count | Info: $info_count"
}

# Generate HTML report
generate_html_report() {
    local output_file="${1:-report.html}"

    cat > "$output_file" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accessibility Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        .info { color: #17a2b8; }
        .issue {
            margin: 10px 0;
            padding: 10px;
            border-left: 4px solid;
            background: #fff;
        }
        .issue.error { border-color: #dc3545; background: #f8d7da; }
        .issue.warning { border-color: #ffc107; background: #fff3cd; }
        .issue.info { border-color: #17a2b8; background: #d1ecf1; }
        .location { font-family: monospace; font-size: 0.9em; }
        .rule { font-weight: bold; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>Accessibility Report</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>$(generate_summary_stats)</p>
        <p class="timestamp">Generated: $(date)</p>
    </div>
EOF

    # Add errors section
    if [[ ${#A11Y_ERRORS[@]} -gt 0 ]]; then
        echo "<h2 class='error'>Errors</h2>" >> "$output_file"
        for error in "${A11Y_ERRORS[@]}"; do
            IFS=':' read -r file line type rule message <<< "$error"
            cat >> "$output_file" <<EOF
    <div class="issue error">
        <span class="location">$file:$line</span>
        <span class="rule">[$rule]</span>
        <span class="message">$message</span>
    </div>
EOF
        done
    fi

    # Add warnings section
    if [[ ${#A11Y_WARNINGS[@]} -gt 0 ]]; then
        echo "<h2 class='warning'>Warnings</h2>" >> "$output_file"
        for warning in "${A11Y_WARNINGS[@]}"; do
            IFS=':' read -r file line type rule message <<< "$warning"
            cat >> "$output_file" <<EOF
    <div class="issue warning">
        <span class="location">$file:$line</span>
        <span class="rule">[$rule]</span>
        <span class="message">$message</span>
    </div>
EOF
        done
    fi

    # Add info section if verbose
    if [[ "${VERBOSE:-}" == "1" ]] && [[ ${#A11Y_INFO[@]} -gt 0 ]]; then
        echo "<h2 class='info'>Information</h2>" >> "$output_file"
        for info in "${A11Y_INFO[@]}"; do
            IFS=':' read -r file line type rule message <<< "$info"
            cat >> "$output_file" <<EOF
    <div class="issue info">
        <span class="location">$file:$line</span>
        <span class="rule">[$rule]</span>
        <span class="message">$message</span>
    </div>
EOF
        done
    fi

    echo "</body></html>" >> "$output_file"
}

# Generate JSON report
generate_json_report() {
    local output_file="${1:-report.json}"

    cat > "$output_file" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "errors": ${#A11Y_ERRORS[@]},
    "warnings": ${#A11Y_WARNINGS[@]},
    "info": ${#A11Y_INFO[@]}
  },
  "errors": [
EOF

    local first=true
    for error in "${A11Y_ERRORS[@]}"; do
        IFS=':' read -r file line type rule message <<< "$error"
        [[ "$first" == false ]] && echo "," >> "$output_file"
        cat >> "$output_file" <<EOF
    {
      "file": "$file",
      "line": $line,
      "rule": "$rule",
      "message": "$message"
    }
EOF
        first=false
    done

    cat >> "$output_file" <<EOF
  ],
  "warnings": [
EOF

    first=true
    for warning in "${A11Y_WARNINGS[@]}"; do
        IFS=':' read -r file line type rule message <<< "$warning"
        [[ "$first" == false ]] && echo "," >> "$output_file"
        cat >> "$output_file" <<EOF
    {
      "file": "$file",
      "line": $line,
      "rule": "$rule",
      "message": "$message"
    }
EOF
        first=false
    done

    cat >> "$output_file" <<EOF
  ]
}
EOF
}

# Generate CSV report
generate_csv_report() {
    local output_file="${1:-report.csv}"

    echo "Type,File,Line,Rule,Message" > "$output_file"

    for error in "${A11Y_ERRORS[@]}"; do
        IFS=':' read -r file line type rule message <<< "$error"
        echo "ERROR,$file,$line,$rule,\"$message\"" >> "$output_file"
    done

    for warning in "${A11Y_WARNINGS[@]}"; do
        IFS=':' read -r file line type rule message <<< "$warning"
        echo "WARNING,$file,$line,$rule,\"$message\"" >> "$output_file"
    done

    if [[ "${VERBOSE:-}" == "1" ]]; then
        for info in "${A11Y_INFO[@]}"; do
            IFS=':' read -r file line type rule message <<< "$info"
            echo "INFO,$file,$line,$rule,\"$message\"" >> "$output_file"
        done
    fi
}

# Generate text report
generate_text_report() {
    local output_file="${1:-report.txt}"

    {
        echo "ACCESSIBILITY REPORT"
        echo "==================="
        echo "Generated: $(date)"
        echo ""
        echo "SUMMARY"
        echo "-------"
        generate_summary_stats
        echo ""

        if [[ ${#A11Y_ERRORS[@]} -gt 0 ]]; then
            echo "ERRORS"
            echo "------"
            for error in "${A11Y_ERRORS[@]}"; do
                IFS=':' read -r file line type rule message <<< "$error"
                echo "  $file:$line [$rule] $message"
            done
            echo ""
        fi

        if [[ ${#A11Y_WARNINGS[@]} -gt 0 ]]; then
            echo "WARNINGS"
            echo "--------"
            for warning in "${A11Y_WARNINGS[@]}"; do
                IFS=':' read -r file line type rule message <<< "$warning"
                echo "  $file:$line [$rule] $message"
            done
            echo ""
        fi

        if [[ "${VERBOSE:-}" == "1" ]] && [[ ${#A11Y_INFO[@]} -gt 0 ]]; then
            echo "INFORMATION"
            echo "-----------"
            for info in "${A11Y_INFO[@]}"; do
                IFS=':' read -r file line type rule message <<< "$info"
                echo "  $file:$line [$rule] $message"
            done
        fi
    } > "$output_file"
}

# Main report generation function
generate_report() {
    local format="${1:-text}"
    local output_file="${2:-}"

    case "$format" in
        html)
            generate_html_report "$output_file"
            ;;
        json)
            generate_json_report "$output_file"
            ;;
        csv)
            generate_csv_report "$output_file"
            ;;
        text|*)
            generate_text_report "$output_file"
            ;;
    esac

    echo "Report generated: ${output_file:-stdout}"
}

# Export functions
export -f generate_summary_stats
export -f generate_html_report
export -f generate_json_report
export -f generate_csv_report
export -f generate_text_report
export -f generate_report