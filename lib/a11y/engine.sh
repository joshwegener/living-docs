#!/bin/bash
# a11y/engine.sh - Accessibility rule engine module
# Extracted from check.sh as part of DEBT-001 refactoring

set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../security/input-sanitizer.sh" 2>/dev/null || true

# Check for missing alt attributes on images
check_missing_alt() {
    local content="${1:-}"
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        if echo "$line" | grep -q '<img[^>]*>'; then
            if ! [[ "$line" =~ alt[[:space:]]*= ]]; then
                issues+="missing-alt:img:line-$line_num:critical\n"
            fi
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check for missing labels on form inputs
check_missing_labels() {
    local content="${1:-}"
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        if echo "$line" | grep -qE '<(input|select|textarea)[^>]*>'; then
            # Check if it has an id attribute
            local input_id
            input_id=$(echo "$line" | sed -n 's/.*id[[:space:]]*=[[:space:]]*["'\'']*\([^"'\'']*\)["'\'']*[^>]*.*/\1/p')
            # Escape special regex characters
            input_id=$(escape_regex "$input_id")
            if [[ -n "$input_id" ]]; then
                # Look for corresponding label (with escaped id)
                if ! grep -qF "<label" <<< "$content" | grep -q "for=[\"']${input_id}[\"']"; then
                    issues+="missing-label:input:line-$line_num:critical\n"
                fi
            else
                # No id means no label can reference it
                issues+="missing-label:input:line-$line_num:critical\n"
            fi
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check for empty links
check_empty_links() {
    local content="${1:-}"
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        if echo "$line" | grep -q '<a[^>]*></a>'; then
            issues+="empty-link:a:line-$line_num:warning\n"
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check for missing heading hierarchy
check_heading_hierarchy() {
    local content="${1:-}"
    local prev_level=0
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        if echo "$line" | grep -qE '<h[1-6][^>]*>'; then
            local level
            level=$(echo "$line" | sed -n 's/.*<h\([1-6]\).*/\1/p')
            local level="${BASH_REMATCH[1]}"
            if [[ $prev_level -gt 0 ]] && [[ $((level - prev_level)) -gt 1 ]]; then
                issues+="heading-skip:h${level}:line-$line_num:warning\n"
            fi
            prev_level=$level
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check for missing lang attribute
check_lang_attribute() {
    local content="${1:-}"
    local issues=""

    if echo "$content" | grep -q '<html[^>]*>'; then
        if ! echo "$content" | grep -q '<html[^>]*lang[[:space:]]*='; then
            issues+="missing-lang:html:line-1:critical\n"
        fi
    fi

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check for duplicate IDs
check_duplicate_ids() {
    local content="${1:-}"
    local issues=""
    declare -A seen_ids

    local line_num=1
    while IFS= read -r line; do
        local id
        id=$(echo "$line" | sed -n 's/.*id[[:space:]]*=[[:space:]]*["'\'']*\([^"'\'']*\)["'\'']*[^>]*.*/\1/p')
        if [[ -n "$id" ]]; then
            if [[ -n "${seen_ids[$id]:-}" ]]; then
                issues+="duplicate-id:${id}:line-$line_num:critical\n"
            else
                seen_ids[$id]=$line_num
            fi
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Check color contrast (simplified check)
check_color_contrast() {
    local content="${1:-}"
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        # Check for low contrast color combinations
        if echo "$line" | grep -q 'color:[[:space:]]*#[cdefCDEF]' && echo "$line" | grep -qE 'background(-color)?:[[:space:]]*#[89abAB]'; then
            issues+="low-contrast:style:line-$line_num:warning\n"
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Run all accessibility checks
run_all_a11y_checks() {
    local content="${1:-}"
    local all_issues=""

    # Run each check and collect results
    local result

    result=$(check_missing_alt "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_missing_labels "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_empty_links "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_heading_hierarchy "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_lang_attribute "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_duplicate_ids "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    result=$(check_color_contrast "$content")
    [[ -n "$result" ]] && all_issues+="$result\n"

    [[ -n "$all_issues" ]] && echo -e "${all_issues%\\n}"
    return 0
}

# Check ARIA attributes
check_aria_attributes() {
    local content="${1:-}"
    local line_num=1
    local issues=""

    while IFS= read -r line; do
        # Check for role without proper ARIA attributes
        local role
        role=$(echo "$line" | sed -n 's/.*role[[:space:]]*=[[:space:]]*["'\'']*\([^"'\'']*\)["'\'']*[^>]*.*/\1/p')
        if [[ -n "$role" ]]; then
            case "$role" in
                button)
                    if ! [[ "$line" =~ aria-pressed ]] && ! [[ "$line" =~ aria-expanded ]]; then
                        issues+="incomplete-aria:$role:line-$line_num:warning\n"
                    fi
                    ;;
                navigation)
                    if ! [[ "$line" =~ aria-label ]]; then
                        issues+="missing-aria-label:$role:line-$line_num:warning\n"
                    fi
                    ;;
            esac
        fi
        ((line_num++))
    done <<< "$content"

    [[ -n "$issues" ]] && echo -e "${issues%\\n}"
    return 0
}

# Export functions
export -f check_missing_alt
export -f check_missing_labels
export -f check_empty_links
export -f check_heading_hierarchy
export -f check_lang_attribute
export -f check_duplicate_ids
export -f check_color_contrast
export -f run_all_a11y_checks
export -f check_aria_attributes