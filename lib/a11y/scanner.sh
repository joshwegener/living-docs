#!/usr/bin/env bash
# Core accessibility scanner module
# Handles file scanning and issue detection

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Scan markdown file for accessibility issues
scan_markdown_file() {
    local file="$1"
    local issues=()

    # Initialize line counter
    local line_num=0

    # Read file line by line
    while IFS= read -r line; do
        ((line_num++))

        # Check for various accessibility issues
        check_line_for_issues "$file" "$line_num" "$line" issues
    done < "$file"

    # Return issues array
    printf '%s\n' "${issues[@]}"
}

# Check single line for accessibility issues
check_line_for_issues() {
    local file="$1"
    local line_num="$2"
    local line="$3"
    local -n issues_ref=$4

    # Check for missing alt text in images
    if [[ "$line" == *"!["*"]("*")"* ]]; then
        local temp="${line#*![}"
        local alt_text="${temp%%]*}"

        if [[ -z "$alt_text" || "$alt_text" == "image" || "$alt_text" == "img" ]]; then
            issues_ref+=("${file}:${line_num}:ERROR:IMG_ALT:Missing or generic alt text")
        fi
    fi

    # Check for link text issues
    if [[ "$line" == *"["*"]("*")"* ]] && [[ "$line" != *"!["* ]]; then
        local temp="${line#*[}"
        local link_text="${temp%%]*}"

        if [[ "$link_text" == "click here" || "$link_text" == "here" || "$link_text" == "link" ]]; then
            issues_ref+=("${file}:${line_num}:WARNING:LINK_TEXT:Non-descriptive link text")
        fi
    fi

    # Check for heading structure
    if [[ "$line" =~ ^#+ ]]; then
        local heading_level="${line%%[^#]*}"
        check_heading_structure "$file" "$line_num" "${#heading_level}" issues_ref
    fi
}

# Check heading structure for proper hierarchy
check_heading_structure() {
    local file="$1"
    local line_num="$2"
    local level="$3"
    local -n issues_ref=$4

    # Store previous heading level
    if [[ -z "${PREV_HEADING_LEVEL:-}" ]]; then
        PREV_HEADING_LEVEL=0
    fi

    # Check for skipped heading levels
    if [[ $level -gt $((PREV_HEADING_LEVEL + 1)) ]] && [[ $PREV_HEADING_LEVEL -ne 0 ]]; then
        issues_ref+=("${file}:${line_num}:ERROR:HEADING_SKIP:Skipped heading level from H${PREV_HEADING_LEVEL} to H${level}")
    fi

    PREV_HEADING_LEVEL=$level
}

# Scan directory recursively
scan_directory() {
    local dir="${1:-.}"
    local pattern="${2:-*.md}"
    local all_issues=()

    # Find all matching files
    while IFS= read -r file; do
        local issues
        issues=$(scan_markdown_file "$file")
        if [[ -n "$issues" ]]; then
            all_issues+=("$issues")
        fi
    done < <(find "$dir" -type f -name "$pattern" 2>/dev/null)

    # Output all issues
    printf '%s\n' "${all_issues[@]}"
}

# Export functions
export -f scan_markdown_file
export -f check_line_for_issues
export -f check_heading_structure
export -f scan_directory