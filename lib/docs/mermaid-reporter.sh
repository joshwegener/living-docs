#!/usr/bin/env bash
# Mermaid validation reporter module
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Output text results
output_text_results() {
    local results=("$@")
    local total=${#results[@]}
    local errors=0
    local warnings=0

    for result in "${results[@]}"; do
        if [[ "$result" =~ ERROR ]]; then
            ((errors++))
        elif [[ "$result" =~ WARNING ]]; then
            ((warnings++))
        fi
    done

    echo -e "${BLUE}=== Mermaid Validation Results ===${NC}"
    echo "Total diagrams checked: $total"
    echo -e "Errors: ${RED}$errors${NC}"
    echo -e "Warnings: ${YELLOW}$warnings${NC}"

    if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
        echo -e "${GREEN}✓ All diagrams valid${NC}"
    fi

    # Output detailed results
    for result in "${results[@]}"; do
        echo "$result"
    done
}

# Output JSON results with jq
output_json_results_with_jq() {
    local results=("$@")
    local json_array="[]"

    for result in "${results[@]}"; do
        # Parse result format: FILE:LINE:TYPE:MESSAGE
        local file="${result%%:*}"
        local rest="${result#*:}"
        local line="${rest%%:*}"
        rest="${rest#*:}"
        local type="${rest%%:*}"
        local message="${rest#*:}"

        # Add to JSON array
        json_array=$(echo "$json_array" | jq --arg file "$file" \
            --arg line "$line" \
            --arg type "$type" \
            --arg message "$message" \
            '. += [{file: $file, line: ($line | tonumber), type: $type, message: $message}]')
    done

    # Output final JSON
    echo "$json_array" | jq '{
        summary: {
            total: length,
            errors: [.[] | select(.type == "ERROR")] | length,
            warnings: [.[] | select(.type == "WARNING")] | length
        },
        results: .
    }'
}

# Output JSON results without jq
output_json_results_plain() {
    local results=("$@")
    local total=${#results[@]}
    local errors=0
    local warnings=0
    local json_results="["

    local first=true
    for result in "${results[@]}"; do
        if [[ "$result" =~ ERROR ]]; then
            ((errors++))
        elif [[ "$result" =~ WARNING ]]; then
            ((warnings++))
        fi

        # Parse result
        local file="${result%%:*}"
        local rest="${result#*:}"
        local line="${rest%%:*}"
        rest="${rest#*:}"
        local type="${rest%%:*}"
        local message="${rest#*:}"

        if [[ "$first" == false ]]; then
            json_results+=","
        fi
        first=false

        json_results+="{\"file\":\"$file\",\"line\":$line,\"type\":\"$type\",\"message\":\"$message\"}"
    done

    json_results+="]"

    # Output complete JSON
    cat <<EOF
{
    "summary": {
        "total": $total,
        "errors": $errors,
        "warnings": $warnings
    },
    "results": $json_results
}
EOF
}

# Output JUnit XML results
output_junit_results() {
    local results=("$@")
    local total=${#results[@]}
    local errors=0
    local warnings=0

    for result in "${results[@]}"; do
        if [[ "$result" =~ ERROR ]]; then
            ((errors++))
        elif [[ "$result" =~ WARNING ]]; then
            ((warnings++))
        fi
    done

    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="Mermaid Validation" tests="$total" errors="$errors" warnings="$warnings">
EOF

    for result in "${results[@]}"; do
        local file="${result%%:*}"
        local rest="${result#*:}"
        local line="${rest%%:*}"
        rest="${rest#*:}"
        local type="${rest%%:*}"
        local message="${rest#*:}"

        echo "  <testcase name=\"$file:$line\" classname=\"MermaidValidation\">"

        if [[ "$type" == "ERROR" ]]; then
            echo "    <error message=\"$message\" type=\"ValidationError\"/>"
        elif [[ "$type" == "WARNING" ]]; then
            echo "    <warning message=\"$message\" type=\"ValidationWarning\"/>"
        fi

        echo "  </testcase>"
    done

    echo "</testsuite>"
}

# Output CSV results
output_csv_results() {
    local results=("$@")

    # Header
    echo "File,Line,Type,Message"

    for result in "${results[@]}"; do
        # Parse result
        local file="${result%%:*}"
        local rest="${result#*:}"
        local line="${rest%%:*}"
        rest="${rest#*:}"
        local type="${rest%%:*}"
        local message="${rest#*:}"

        # Escape commas in message
        message="${message//,/\\,}"

        echo "$file,$line,$type,\"$message\""
    done
}

# Output markdown results
output_markdown_results() {
    local results=("$@")
    local total=${#results[@]}
    local errors=0
    local warnings=0

    for result in "${results[@]}"; do
        if [[ "$result" =~ ERROR ]]; then
            ((errors++))
        elif [[ "$result" =~ WARNING ]]; then
            ((warnings++))
        fi
    done

    cat <<EOF
# Mermaid Validation Report

## Summary
- **Total diagrams checked:** $total
- **Errors:** $errors
- **Warnings:** $warnings

## Results

| File | Line | Type | Message |
|------|------|------|---------|
EOF

    for result in "${results[@]}"; do
        local file="${result%%:*}"
        local rest="${result#*:}"
        local line="${rest%%:*}"
        rest="${rest#*:}"
        local type="${rest%%:*}"
        local message="${rest#*:}"

        local type_badge=""
        if [[ "$type" == "ERROR" ]]; then
            type_badge="🔴 ERROR"
        elif [[ "$type" == "WARNING" ]]; then
            type_badge="🟡 WARNING"
        else
            type_badge="✅ OK"
        fi

        echo "| \`$file\` | $line | $type_badge | $message |"
    done
}

# Main output function
output_results() {
    local format="${1:-text}"
    shift
    local results=("$@")

    case "$format" in
        text)
            output_text_results "${results[@]}"
            ;;
        json)
            if command -v jq &>/dev/null; then
                output_json_results_with_jq "${results[@]}"
            else
                output_json_results_plain "${results[@]}"
            fi
            ;;
        junit|xml)
            output_junit_results "${results[@]}"
            ;;
        csv)
            output_csv_results "${results[@]}"
            ;;
        markdown|md)
            output_markdown_results "${results[@]}"
            ;;
        *)
            log_error "Unknown output format: $format"
            return 1
            ;;
    esac
}

# Export functions
export -f output_text_results
export -f output_json_results_with_jq
export -f output_json_results_plain
export -f output_junit_results
export -f output_csv_results
export -f output_markdown_results
export -f output_results