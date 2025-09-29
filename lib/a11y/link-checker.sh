#!/usr/bin/env bash
# Link accessibility checker module
# Validates link text, descriptions, and accessibility

set -euo pipefail

# Check link text quality
check_link_text() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown links [text](url)
        if [[ "$line" =~ \[([^\]]*)\]\(([^\)]+)\) ]]; then
            local link_text="${BASH_REMATCH[1]}"
            local link_url="${BASH_REMATCH[2]}"

            # Check for empty link text
            if [[ -z "$link_text" ]]; then
                log_error "$file" "$line_num" "LINK-TEXT-EMPTY" "Link has no text"
            # Check for generic link text
            elif [[ "$link_text" =~ ^(click[[:space:]]here|here|link|more|read[[:space:]]more)$ ]]; then
                log_warning "$file" "$line_num" "LINK-TEXT-GENERIC" "Generic link text: '$link_text'"
            # Check for URL as link text
            elif [[ "$link_text" =~ ^https?:// ]]; then
                log_warning "$file" "$line_num" "LINK-TEXT-URL" "URL used as link text"
            # Check link text length
            elif [[ ${#link_text} -lt 4 ]]; then
                log_warning "$file" "$line_num" "LINK-TEXT-SHORT" "Link text too short (${#link_text} chars)"
            elif [[ ${#link_text} -gt 100 ]]; then
                log_warning "$file" "$line_num" "LINK-TEXT-LONG" "Link text too long (${#link_text} chars)"
            fi

            # Check for broken fragment links
            if [[ "$link_url" =~ ^# ]] && [[ ${#link_url} -eq 1 ]]; then
                log_error "$file" "$line_num" "LINK-FRAGMENT-EMPTY" "Empty fragment link"
            fi
        fi

        # Check HTML links
        if [[ "$line" =~ \<a[[:space:]] ]]; then
            # Extract link text
            if [[ "$line" =~ \<a[^\>]*\>(.*)\</a\> ]]; then
                local html_link_text="${BASH_REMATCH[1]}"

                if [[ -z "$html_link_text" ]] || [[ "$html_link_text" =~ ^[[:space:]]*$ ]]; then
                    log_error "$file" "$line_num" "LINK-HTML-EMPTY" "HTML link has no text"
                fi
            fi

            # Check for title attribute
            if [[ ! "$line" =~ title= ]] && [[ ! "$line" =~ aria-label= ]]; then
                log_info "$file" "$line_num" "LINK-TITLE-MISSING" "Consider adding title or aria-label attribute"
            fi
        fi
    done < "$file"
}

# Check for link context
check_link_context() {
    local file="$1"
    local line_num=0
    local prev_line=""

    while IFS= read -r line; do
        ((line_num++))

        # Check if link is within a list (good for navigation)
        if [[ "$prev_line" =~ ^[*+-]|^[0-9]+\. ]] && [[ "$line" =~ \[[^\]]+\]\([^\)]+\) ]]; then
            log_info "$file" "$line_num" "LINK-IN-LIST" "Link properly structured in list"
        fi

        # Check for links opening in new window
        if [[ "$line" =~ target=[\"\'_]blank ]]; then
            if [[ ! "$line" =~ (opens?[[:space:]]in[[:space:]]new|new[[:space:]]window|new[[:space:]]tab) ]]; then
                log_warning "$file" "$line_num" "LINK-NEW-WINDOW" "Link opens in new window without warning"
            fi
        fi

        prev_line="$line"
    done < "$file"
}

# Check for link consistency
check_link_consistency() {
    local file="$1"
    local link_styles=()
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Track link styles (markdown vs HTML)
        if [[ "$line" =~ \[[^\]]+\]\([^\)]+\) ]]; then
            link_styles+=("markdown:$line_num")
        fi

        if [[ "$line" =~ \<a[[:space:]] ]]; then
            link_styles+=("html:$line_num")
        fi
    done < "$file"

    # Check for mixed styles
    local has_markdown=false
    local has_html=false
    for style in "${link_styles[@]}"; do
        [[ "$style" =~ ^markdown: ]] && has_markdown=true
        [[ "$style" =~ ^html: ]] && has_html=true
    done

    if [[ "$has_markdown" == true ]] && [[ "$has_html" == true ]]; then
        log_info "$file" 0 "LINK-STYLE-MIX" "Document uses both Markdown and HTML links"
    fi
}

# Check for link accessibility attributes
check_link_accessibility() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for download links
        if [[ "$line" =~ \.(pdf|doc|docx|xls|xlsx|zip|tar|gz) ]] && [[ "$line" =~ \[[^\]]+\]\([^\)]+\) ]]; then
            if [[ ! "$line" =~ (download|PDF|document|file) ]]; then
                log_warning "$file" "$line_num" "LINK-DOWNLOAD" "Download link should indicate file type"
            fi
        fi

        # Check for email links
        if [[ "$line" =~ mailto: ]]; then
            if [[ ! "$line" =~ (email|contact|mail) ]]; then
                log_info "$file" "$line_num" "LINK-EMAIL" "Email link should be clearly indicated"
            fi
        fi

        # Check for phone links
        if [[ "$line" =~ tel: ]]; then
            if [[ ! "$line" =~ (phone|call|tel) ]]; then
                log_info "$file" "$line_num" "LINK-PHONE" "Phone link should be clearly indicated"
            fi
        fi
    done < "$file"
}

# Main link accessibility check
check_links_accessibility() {
    local file="$1"

    check_link_text "$file"
    check_link_context "$file"
    check_link_consistency "$file"
    check_link_accessibility "$file"
}

# Export functions
export -f check_link_text
export -f check_link_context
export -f check_link_consistency
export -f check_link_accessibility
export -f check_links_accessibility