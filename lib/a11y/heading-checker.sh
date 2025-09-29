#!/usr/bin/env bash
# Heading hierarchy and structure checker module
# Validates heading accessibility and proper nesting

set -euo pipefail

# Check heading hierarchy
check_heading_hierarchy() {
    local file="$1"
    local line_num=0
    local prev_level=0
    local h1_count=0
    local heading_stack=()

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown headings
        if [[ "$line" =~ ^(#{1,6})[[:space:]](.+) ]]; then
            local level=${#BASH_REMATCH[1]}
            local heading_text="${BASH_REMATCH[2]}"

            # Count H1s
            if [[ $level -eq 1 ]]; then
                ((h1_count++))
                if [[ $h1_count -gt 1 ]]; then
                    log_warning "$file" "$line_num" "HEAD-MULTIPLE-H1" "Multiple H1 headings found (H1 #$h1_count)"
                fi
            fi

            # Check for skipped levels
            if [[ $prev_level -gt 0 ]] && [[ $level -gt $((prev_level + 1)) ]]; then
                log_error "$file" "$line_num" "HEAD-SKIP" "Heading level skipped (H$prev_level to H$level)"
            fi

            # Check for empty headings
            if [[ -z "$heading_text" ]] || [[ "$heading_text" =~ ^[[:space:]]+$ ]]; then
                log_error "$file" "$line_num" "HEAD-EMPTY" "Empty heading text"
            fi

            # Check heading length
            if [[ ${#heading_text} -gt 60 ]]; then
                log_warning "$file" "$line_num" "HEAD-LONG" "Heading exceeds 60 characters (${#heading_text} chars)"
            fi

            # Update heading stack for nesting validation
            heading_stack[$level]="$heading_text"
            for ((i=$((level+1)); i<=6; i++)); do
                unset heading_stack[$i] 2>/dev/null || true
            done

            prev_level=$level
        fi

        # Check HTML headings
        if [[ "$line" =~ \<h([1-6])[^\>]*\>(.*)\</h[1-6]\> ]]; then
            local html_level="${BASH_REMATCH[1]}"
            local html_text="${BASH_REMATCH[2]}"

            if [[ -z "$html_text" ]] || [[ "$html_text" =~ ^[[:space:]]*$ ]]; then
                log_error "$file" "$line_num" "HEAD-HTML-EMPTY" "Empty HTML heading"
            fi
        fi
    done < "$file"

    # Check if document has any H1
    if [[ $h1_count -eq 0 ]]; then
        log_error "$file" 0 "HEAD-NO-H1" "Document missing H1 heading"
    fi
}

# Check for heading consistency
check_heading_consistency() {
    local file="$1"
    local line_num=0
    local markdown_style=""
    local html_headings=false

    while IFS= read -r line; do
        ((line_num++))

        # Detect markdown heading style (ATX vs Setext)
        if [[ "$line" =~ ^#{1,6}[[:space:]] ]]; then
            if [[ -z "$markdown_style" ]]; then
                markdown_style="atx"
            fi
        elif [[ "$line" =~ ^(={3,}|
{3,})$ ]] && [[ $line_num -gt 1 ]]; then
            if [[ -z "$markdown_style" ]]; then
                markdown_style="setext"
            elif [[ "$markdown_style" == "atx" ]]; then
                log_info "$file" "$line_num" "HEAD-STYLE-MIX" "Mixed heading styles (ATX and Setext)"
            fi
        fi

        # Check for HTML headings mixed with markdown
        if [[ "$line" =~ \<h[1-6] ]]; then
            html_headings=true
            if [[ -n "$markdown_style" ]]; then
                log_info "$file" "$line_num" "HEAD-FORMAT-MIX" "Mixed HTML and Markdown headings"
            fi
        fi
    done < "$file"
}

# Check heading accessibility attributes
check_heading_accessibility() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for heading IDs (important for navigation)
        if [[ "$line" =~ ^#{1,6}[[:space:]](.+)[[:space:]]\{#([^}]+)\} ]]; then
            local heading_id="${BASH_REMATCH[2]}"

            # Validate ID format
            if [[ ! "$heading_id" =~ ^[a-z][a-z0-9-]*$ ]]; then
                log_warning "$file" "$line_num" "HEAD-ID-FORMAT" "Heading ID should use lowercase letters, numbers, and hyphens: $heading_id"
            fi
        fi

        # Check HTML headings for ARIA labels
        if [[ "$line" =~ \<h[1-6] ]]; then
            if [[ "$line" =~ aria-label ]] || [[ "$line" =~ aria-labelledby ]]; then
                log_info "$file" "$line_num" "HEAD-ARIA" "Heading uses ARIA labels (good practice)"
            fi
        fi
    done < "$file"
}

# Check for proper section structure
check_section_structure() {
    local file="$1"
    local in_nav=false
    local in_main=false
    local in_aside=false
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for semantic HTML5 sections
        if [[ "$line" =~ \<nav ]]; then
            in_nav=true
        elif [[ "$line" =~ \</nav ]]; then
            in_nav=false
        elif [[ "$line" =~ \<main ]]; then
            in_main=true
        elif [[ "$line" =~ \</main ]]; then
            in_main=false
        elif [[ "$line" =~ \<aside ]]; then
            in_aside=true
        elif [[ "$line" =~ \</aside ]]; then
            in_aside=false
        fi

        # Check heading placement within sections
        if [[ "$line" =~ \<h[1-6] ]] || [[ "$line" =~ ^#{1,6}[[:space:]] ]]; then
            if $in_nav; then
                log_info "$file" "$line_num" "HEAD-NAV" "Heading in navigation section"
            elif $in_aside; then
                log_info "$file" "$line_num" "HEAD-ASIDE" "Heading in aside section"
            fi
        fi
    done < "$file"
}

# Main heading accessibility check
check_headings_accessibility() {
    local file="$1"

    check_heading_hierarchy "$file"
    check_heading_consistency "$file"
    check_heading_accessibility "$file"
    check_section_structure "$file"
}

# Export functions
export -f check_heading_hierarchy
export -f check_heading_consistency
export -f check_heading_accessibility
export -f check_section_structure
export -f check_headings_accessibility