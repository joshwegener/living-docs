#!/usr/bin/env bash
# Accessibility compliance checker for markdown documentation
# Comprehensive tool to ensure documentation is accessible to all users

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source security module
# shellcheck source=../security/sanitize.sh
source "${SCRIPT_DIR}/../security/sanitize.sh"

# Source UI module for progress indicators
# shellcheck source=../ui/progress.sh
source "${SCRIPT_DIR}/../ui/progress.sh"

# Configuration
readonly A11Y_VERSION="1.0.0"
readonly A11Y_CONFIG_FILE=".a11y-config"
readonly DEFAULT_OUTPUT_DIR="reports/accessibility"
readonly DEFAULT_OUTPUT_FORMAT="html"

# Color definitions (respect NO_COLOR)
setup_a11y_colors() {
    if [[ -n "${NO_COLOR:-}" ]]; then
        A11Y_RED=""
        A11Y_YELLOW=""
        A11Y_GREEN=""
        A11Y_BLUE=""
        A11Y_BOLD=""
        A11Y_RESET=""
    else
        A11Y_RED="\033[31m"
        A11Y_YELLOW="\033[33m"
        A11Y_GREEN="\033[32m"
        A11Y_BLUE="\033[34m"
        A11Y_BOLD="\033[1m"
        A11Y_RESET="\033[0m"
    fi
}

setup_a11y_colors

# Issue tracking
A11Y_ERRORS=()
A11Y_WARNINGS=()
A11Y_INFO=()
A11Y_FILE_STATS=""

# Log functions
log_error() {
    local file="$1"
    local line="$2"
    local rule="$3"
    local message="$4"

    A11Y_ERRORS+=("${file}:${line}:ERROR:${rule}:${message}")
    echo -e "${A11Y_RED}ERROR${A11Y_RESET} ${file}:${line} [${rule}] ${message}" >&2
}

log_warning() {
    local file="$1"
    local line="$2"
    local rule="$3"
    local message="$4"

    A11Y_WARNINGS+=("${file}:${line}:WARNING:${rule}:${message}")
    echo -e "${A11Y_YELLOW}WARNING${A11Y_RESET} ${file}:${line} [${rule}] ${message}" >&2
}

log_info() {
    local file="$1"
    local line="$2"
    local rule="$3"
    local message="$4"

    A11Y_INFO+=("${file}:${line}:INFO:${rule}:${message}")
    if [[ "${VERBOSE:-}" == "1" ]]; then
        echo -e "${A11Y_BLUE}INFO${A11Y_RESET} ${file}:${line} [${rule}] ${message}" >&2
    fi
}

# Rule checkers

# Check for missing alt text on images
check_image_alt_text() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown images ![alt](src)
        if [[ "$line" == *"!["*"]("*")"* ]]; then
            # Extract alt text using parameter expansion (bash 3.2 compatible)
            local temp="${line#*![}"
            local alt_text="${temp%%]*}"

            # Empty alt text
            if [[ -z "$alt_text" ]]; then
                log_error "$file" "$line_num" "IMG_NO_ALT" "Image missing alt text"
            # Redundant alt text
            elif [[ "$alt_text" == "image" ]] || [[ "$alt_text" == "picture" ]] || [[ "$alt_text" == "photo" ]] || [[ "$alt_text" == "graphic" ]] || [[ "$alt_text" == "diagram" ]]; then
                log_warning "$file" "$line_num" "IMG_REDUNDANT_ALT" "Alt text is redundant: '$alt_text'"
            # Filename as alt text
            elif [[ "$alt_text" == *".png" ]] || [[ "$alt_text" == *".jpg" ]] || [[ "$alt_text" == *".jpeg" ]] || [[ "$alt_text" == *".gif" ]] || [[ "$alt_text" == *".svg" ]] || [[ "$alt_text" == *".webp" ]]; then
                log_warning "$file" "$line_num" "IMG_FILENAME_ALT" "Alt text appears to be filename: '$alt_text'"
            # Good alt text
            elif [[ ${#alt_text} -gt 100 ]]; then
                log_warning "$file" "$line_num" "IMG_ALT_TOO_LONG" "Alt text is quite long (${#alt_text} chars). Consider shortening."
            fi
        fi

        # Check HTML images
        if [[ "$line" == *"<img"* ]]; then
            if [[ "$line" != *"alt="* ]]; then
                log_error "$file" "$line_num" "HTML_IMG_NO_ALT" "HTML image missing alt attribute"
            elif [[ "$line" == *'alt=""'* ]]; then
                # Empty alt is OK for decorative images, but check if it's intentional
                log_info "$file" "$line_num" "HTML_IMG_EMPTY_ALT" "HTML image has empty alt (decorative image?)"
            fi
        fi

    done < "$file"
}

# Check heading hierarchy (no skipped levels)
check_heading_hierarchy() {
    local file="$1"
    local line_num=0
    local last_level=0
    local has_h1=false

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown headings
        if [[ "$line" == "#"* ]] && [[ "$line" == *" "* ]]; then
            # Count the hash symbols
            local temp="${line%%[! #]*}"
            local current_level=${#temp}

            # Check for H1
            if [[ $current_level -eq 1 ]]; then
                if [[ "$has_h1" == "true" ]]; then
                    log_warning "$file" "$line_num" "HEADING_MULTIPLE_H1" "Multiple H1 headings found"
                fi
                has_h1=true
            fi

            # Check for skipped levels
            if [[ $last_level -gt 0 && $current_level -gt $((last_level + 1)) ]]; then
                log_error "$file" "$line_num" "HEADING_SKIPPED_LEVEL" "Heading level skipped (from H${last_level} to H${current_level})"
            fi

            # Check for empty headings
            local heading_text="${line#"$temp"}"
            heading_text="${heading_text# }" # trim leading space
            if [[ -z "$heading_text" ]]; then
                log_error "$file" "$line_num" "HEADING_EMPTY" "Empty heading"
            fi

            last_level=$current_level
        fi

        # Check HTML headings
        if [[ "$line" == *"<h"[1-6]* ]] && [[ "$line" == *"</h"[1-6]">"* ]]; then
            # Extract content between tags (simplified)
            if [[ "$line" == *"></"* ]]; then
                log_error "$file" "$line_num" "HTML_HEADING_EMPTY" "Empty HTML heading"
            fi
        fi

    done < "$file"

    # Check if document has H1
    if [[ "$has_h1" == "false" ]]; then
        log_warning "$file" "1" "NO_H1" "Document missing H1 heading"
    fi
}

# Check link text quality
check_link_text() {
    local file="$1"
    local line_num=0

    # Problematic link text patterns
    local bad_patterns=(
        "click here"
        "read more"
        "more info"
        "this link"
        "here"
        "link"
        "download"
        "view"
        "see"
    )

    while IFS= read -r line; do
        ((line_num++))

        # Check markdown links [text](url)
        if [[ "$line" == *"["*"]("*")"* ]]; then
            # Extract link text (simplified approach)
            local temp="${line#*[}"
            local link_text="${temp%%]*}"

            # Convert to lowercase for checking (bash 3.2 compatible)
            local link_text_lower
            link_text_lower=$(echo "$link_text" | tr '[:upper:]' '[:lower:]')

            # Check for problematic patterns
            for pattern in "${bad_patterns[@]}"; do
                if [[ "$link_text_lower" == *"$pattern"* ]]; then
                    log_warning "$file" "$line_num" "LINK_BAD_TEXT" "Non-descriptive link text: '$link_text'"
                    break
                fi
            done

            # Check for URL as link text
            if [[ "$link_text" == "http"* ]]; then
                log_warning "$file" "$line_num" "LINK_URL_AS_TEXT" "URL used as link text (not descriptive)"
            fi

            # Check for very short link text
            if [[ ${#link_text} -lt 3 ]]; then
                log_warning "$file" "$line_num" "LINK_TEXT_TOO_SHORT" "Link text very short: '$link_text'"
            fi
        fi

        # Check HTML links
        if [[ "$line" == *"<a"* ]] && [[ "$line" == *"</a>"* ]]; then
            # Extract link text between tags (simplified)
            local temp="${line#*>}"
            local link_text="${temp%%<*}"
            local link_text_lower
            link_text_lower=$(echo "$link_text" | tr '[:upper:]' '[:lower:]')

            for pattern in "${bad_patterns[@]}"; do
                if [[ "$link_text_lower" == *"$pattern"* ]]; then
                    log_warning "$file" "$line_num" "HTML_LINK_BAD_TEXT" "Non-descriptive HTML link text: '$link_text'"
                    break
                fi
            done
        fi

    done < "$file"
}

# Check color contrast in code blocks
check_color_contrast() {
    local file="$1"
    local line_num=0
    local in_code_block=false

    while IFS= read -r line; do
        ((line_num++))

        # Track code block boundaries
        if [[ "$line" == '```'* ]] || [[ "$line" == '~~~'* ]]; then
            if [[ "$in_code_block" == "true" ]]; then
                in_code_block=false
            else
                in_code_block=true
            fi
        fi

        # Check for color usage in code blocks
        if [[ "$in_code_block" == "true" ]]; then
            # Check for color codes that might have poor contrast
            if [[ "$line" == *"#"* ]] && [[ "$line" == *[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]* ]]; then
                log_info "$file" "$line_num" "COLOR_IN_CODE" "Color code found in code block - verify contrast ratio"
            fi

            # Check for ANSI color codes
            if [[ "$line" == *"\\033["*"m"* ]] || [[ "$line" == *"\033["*"m"* ]]; then
                log_info "$file" "$line_num" "ANSI_COLOR_IN_CODE" "ANSI color code found - verify contrast"
            fi
        fi

        # Check for color references in regular text
        if [[ "$in_code_block" == "false" ]]; then
            if [[ "$line" == *"red text"* ]] || [[ "$line" == *"green text"* ]] || [[ "$line" == *"blue text"* ]] ||
               [[ "$line" == *"yellow text"* ]] || [[ "$line" == *"red color"* ]] || [[ "$line" == *"green color"* ]] ||
               [[ "$line" == *"blue color"* ]] || [[ "$line" == *"yellow color"* ]]; then
                log_warning "$file" "$line_num" "COLOR_ONLY_INFO" "Color-only information detected - ensure alternative indicators"
            fi
        fi

    done < "$file"
}

# Check table accessibility
check_table_headers() {
    local file="$1"
    local line_num=0
    local in_table=false
    local table_start_line=0
    local has_headers=false

    while IFS= read -r line; do
        ((line_num++))

        # Detect table start (markdown tables)
        if [[ "$line" == *"|"* ]]; then
            if [[ "$in_table" == "false" ]]; then
                in_table=true
                table_start_line=$line_num
                has_headers=false
            fi

            # Check if this is a header separator line
            if [[ "$line" == *"---"* ]] || [[ "$line" == *":--"* ]] || [[ "$line" == *"--:"* ]]; then
                has_headers=true
            fi
        else
            # End of table
            if [[ "$in_table" == "true" ]]; then
                if [[ "$has_headers" == "false" ]]; then
                    log_error "$file" "$table_start_line" "TABLE_NO_HEADERS" "Table missing header row"
                fi
                in_table=false
            fi
        fi

        # Check HTML tables
        if [[ "$line" == *"<table"* ]]; then
            log_info "$file" "$line_num" "HTML_TABLE_FOUND" "HTML table found - verify it has proper th elements"
        fi

        if [[ "$line" == *"<th"* ]]; then
            if [[ "$line" != *"scope="* ]]; then
                log_warning "$file" "$line_num" "TABLE_TH_NO_SCOPE" "Table header missing scope attribute"
            fi
        fi

    done < "$file"

    # Check if we ended inside a table
    if [[ "$in_table" == "true" && "$has_headers" == "false" ]]; then
        log_error "$file" "$table_start_line" "TABLE_NO_HEADERS" "Table missing header row"
    fi
}

# Check for language attributes
check_language_attributes() {
    local file="$1"
    local line_num=0
    local has_lang_attr=false

    while IFS= read -r line; do
        ((line_num++))

        # Check for HTML lang attribute
        if [[ "$line" == *"<html"* ]] && [[ "$line" == *"lang="* ]]; then
            has_lang_attr=true
        fi

        # Check for lang attributes on specific elements
        if [[ "$line" == *"lang="* ]]; then
            log_info "$file" "$line_num" "LANG_ATTR_FOUND" "Language attribute found"
        fi

        # Check for foreign language content that might need lang attributes
        # This is a heuristic - look for common foreign words
        if [[ "$line" == *"bonjour"* ]] || [[ "$line" == *"hola"* ]] || [[ "$line" == *"guten"* ]] ||
           [[ "$line" == *"konnichiwa"* ]] || [[ "$line" == *"namaste"* ]] || [[ "$line" == *"shalom"* ]]; then
            log_info "$file" "$line_num" "FOREIGN_LANG_DETECTED" "Possible foreign language content - consider lang attribute"
        fi

    done < "$file"

    # For HTML files, check if lang attribute is present
    if [[ "$file" == *".html" ]] || [[ "$file" == *".htm" ]]; then
        if [[ "$has_lang_attr" == "false" ]]; then
            log_warning "$file" "1" "HTML_NO_LANG" "HTML document missing lang attribute"
        fi
    fi
}

# Check for ARIA labels and accessibility attributes
check_aria_labels() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for ARIA attributes
        if [[ "$line" == *"aria-"* ]]; then
            log_info "$file" "$line_num" "ARIA_ATTR_FOUND" "ARIA attribute found"

            # Check for common ARIA mistakes
            if [[ "$line" == *'aria-label=""'* ]]; then
                log_warning "$file" "$line_num" "ARIA_LABEL_EMPTY" "Empty aria-label attribute"
            fi
        fi

        # Check for role attributes
        if [[ "$line" == *"role="* ]]; then
            log_info "$file" "$line_num" "ROLE_ATTR_FOUND" "Role attribute found"
        fi

        # Check for elements that might need ARIA labels
        if [[ "$line" == *"<button"* ]] && [[ "$line" == *"></button>"* ]]; then
            log_warning "$file" "$line_num" "BUTTON_NO_TEXT" "Button with no text content - needs aria-label"
        fi

        if [[ "$line" == *"<input"* ]] && [[ "$line" == *'type="button"'* ]]; then
            if [[ "$line" != *"value="* ]] && [[ "$line" != *"aria-label="* ]]; then
                log_warning "$file" "$line_num" "INPUT_BUTTON_NO_LABEL" "Input button needs value or aria-label"
            fi
        fi

    done < "$file"
}

# Check for accessibility best practices
check_accessibility_best_practices() {
    local file="$1"
    local line_num=0
    local word_count=0

    while IFS= read -r line; do
        ((line_num++))

        # Count words for readability
        word_count=$((word_count + $(echo "$line" | wc -w)))

        # Check for overly long paragraphs
        local line_word_count
        line_word_count=$(echo "$line" | wc -w)
        if [[ $line_word_count -gt 50 ]]; then
            log_info "$file" "$line_num" "LONG_PARAGRAPH" "Long paragraph ($line_word_count words) - consider breaking up"
        fi

        # Check for accessibility-related keywords that might indicate good practices
        if [[ "$line" == *"accessibility"* ]] || [[ "$line" == *"a11y"* ]] || [[ "$line" == *"screen reader"* ]] ||
           [[ "$line" == *"keyboard navigation"* ]] || [[ "$line" == *"high contrast"* ]]; then
            log_info "$file" "$line_num" "A11Y_CONTENT_FOUND" "Accessibility-related content found"
        fi

        # Check for potentially problematic content
        if [[ "$line" == *"blink"* ]] || [[ "$line" == *"flash"* ]] || [[ "$line" == *"strobe"* ]]; then
            log_warning "$file" "$line_num" "SEIZURE_RISK" "Content may pose seizure risk - verify accessibility"
        fi

        # Check for autoplay references
        if [[ "$line" == *"autoplay"* ]]; then
            log_warning "$file" "$line_num" "AUTOPLAY_DETECTED" "Autoplay detected - ensure user control"
        fi

    done < "$file"

    # Overall document metrics
    local avg_words_per_line=$((word_count / line_num))
    if [[ $avg_words_per_line -gt 20 ]]; then
        log_info "$file" "1" "DOCUMENT_DENSE" "Document is quite dense ($avg_words_per_line words/line avg)"
    fi
}

# Main checking function for a single file
check_file_accessibility() {
    local file="$1"

    # Basic file path validation (less restrictive than security module)
    if [[ -z "$file" ]]; then
        echo "Error: Empty file path" >&2
        return 1
    fi

    # Convert to absolute path if relative
    if [[ "$file" != /* ]]; then
        file="$(pwd)/$file"
    fi

    # Check if file exists and is readable
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        echo "Error: Cannot read file: $file" >&2
        return 1
    fi

    # Initialize stats for this file (add to list)
    A11Y_FILE_STATS="$A11Y_FILE_STATS $file"

    echo "Checking accessibility: $file"

    # Run all checks
    check_image_alt_text "$file"
    check_heading_hierarchy "$file"
    check_link_text "$file"
    check_color_contrast "$file"
    check_table_headers "$file"
    check_language_attributes "$file"
    check_aria_labels "$file"
    check_accessibility_best_practices "$file"
}

# Generate accessibility report
generate_report() {
    local output_dir="${1:-$DEFAULT_OUTPUT_DIR}"
    local format="${2:-$DEFAULT_OUTPUT_FORMAT}"

    # Create output directory
    mkdir -p "$output_dir"

    local timestamp
    timestamp=$(date "+%Y-%m-%d_%H-%M-%S")
    local report_file="${output_dir}/accessibility_report_${timestamp}"

    # Generate report based on format
    case "$format" in
        "html")
            generate_html_report "${report_file}.html"
            ;;
        "json")
            generate_json_report "${report_file}.json"
            ;;
        "csv")
            generate_csv_report "${report_file}.csv"
            ;;
        "text"|*)
            generate_text_report "${report_file}.txt"
            ;;
    esac

    echo "Report generated: ${report_file}.${format}"
}

generate_html_report() {
    local output_file="$1"

    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accessibility Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 2em; line-height: 1.6; }
        .summary { background: #f5f5f5; padding: 1em; border-radius: 5px; margin-bottom: 2em; }
        .error { color: #d32f2f; }
        .warning { color: #f57c00; }
        .info { color: #1976d2; }
        .issue { margin: 0.5em 0; padding: 0.5em; border-left: 3px solid #ccc; }
        .issue.error { border-left-color: #d32f2f; background: #ffebee; }
        .issue.warning { border-left-color: #f57c00; background: #fff3e0; }
        .issue.info { border-left-color: #1976d2; background: #e3f2fd; }
        .file-path { font-family: monospace; background: #f5f5f5; padding: 0.2em 0.5em; border-radius: 3px; }
        .rule-id { font-weight: bold; font-size: 0.9em; }
        .stats { display: flex; gap: 2em; margin: 1em 0; }
        .stat { text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Accessibility Compliance Report</h1>

EOF

    # Add timestamp
    echo "    <p><strong>Generated:</strong> $(date)</p>" >> "$output_file"

    # Add summary statistics
    cat >> "$output_file" << EOF
    <div class="summary">
        <h2>Summary</h2>
        <div class="stats">
            <div class="stat">
                <div class="stat-number error">${#A11Y_ERRORS[@]}</div>
                <div>Errors</div>
            </div>
            <div class="stat">
                <div class="stat-number warning">${#A11Y_WARNINGS[@]}</div>
                <div>Warnings</div>
            </div>
            <div class="stat">
                <div class="stat-number info">${#A11Y_INFO[@]}</div>
                <div>Info</div>
            </div>
            <div class="stat">
                <div class="stat-number">$(echo "$A11Y_FILE_STATS" | wc -w)</div>
                <div>Files Checked</div>
            </div>
        </div>
    </div>
EOF

    # Add issues
    if [[ ${#A11Y_ERRORS[@]} -gt 0 ]]; then
        echo "    <h2>Errors</h2>" >> "$output_file"
        for issue in "${A11Y_ERRORS[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            cat >> "$output_file" << EOF
    <div class="issue error">
        <div class="file-path">$file:$line</div>
        <div class="rule-id">$rule</div>
        <div>$message</div>
    </div>
EOF
        done
    fi

    if [[ ${#A11Y_WARNINGS[@]} -gt 0 ]]; then
        echo "    <h2>Warnings</h2>" >> "$output_file"
        for issue in "${A11Y_WARNINGS[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            cat >> "$output_file" << EOF
    <div class="issue warning">
        <div class="file-path">$file:$line</div>
        <div class="rule-id">$rule</div>
        <div>$message</div>
    </div>
EOF
        done
    fi

    if [[ ${#A11Y_INFO[@]} -gt 0 ]]; then
        echo "    <h2>Information</h2>" >> "$output_file"
        for issue in "${A11Y_INFO[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            cat >> "$output_file" << EOF
    <div class="issue info">
        <div class="file-path">$file:$line</div>
        <div class="rule-id">$rule</div>
        <div>$message</div>
    </div>
EOF
        done
    fi

    cat >> "$output_file" << 'EOF'
</body>
</html>
EOF
}

generate_json_report() {
    local output_file="$1"

    cat > "$output_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "errors": ${#A11Y_ERRORS[@]},
    "warnings": ${#A11Y_WARNINGS[@]},
    "info": ${#A11Y_INFO[@]},
    "files_checked": $(echo "$A11Y_FILE_STATS" | wc -w)
  },
  "issues": {
    "errors": [
EOF

    # Add errors
    local first=true
    for issue in "${A11Y_ERRORS[@]}"; do
        IFS=':' read -r file line level rule message <<< "$issue"
        if [[ "$first" != "true" ]]; then
            echo "," >> "$output_file"
        fi
        cat >> "$output_file" << EOF
      {
        "file": "$file",
        "line": $line,
        "level": "$level",
        "rule": "$rule",
        "message": "$message"
      }
EOF
        first=false
    done

    cat >> "$output_file" << EOF
    ],
    "warnings": [
EOF

    # Add warnings
    first=true
    for issue in "${A11Y_WARNINGS[@]}"; do
        IFS=':' read -r file line level rule message <<< "$issue"
        if [[ "$first" != "true" ]]; then
            echo "," >> "$output_file"
        fi
        cat >> "$output_file" << EOF
      {
        "file": "$file",
        "line": $line,
        "level": "$level",
        "rule": "$rule",
        "message": "$message"
      }
EOF
        first=false
    done

    cat >> "$output_file" << EOF
    ],
    "info": [
EOF

    # Add info
    first=true
    for issue in "${A11Y_INFO[@]}"; do
        IFS=':' read -r file line level rule message <<< "$issue"
        if [[ "$first" != "true" ]]; then
            echo "," >> "$output_file"
        fi
        cat >> "$output_file" << EOF
      {
        "file": "$file",
        "line": $line,
        "level": "$level",
        "rule": "$rule",
        "message": "$message"
      }
EOF
        first=false
    done

    cat >> "$output_file" << EOF
    ]
  }
}
EOF
}

generate_csv_report() {
    local output_file="$1"

    # CSV Header
    echo "File,Line,Level,Rule,Message" > "$output_file"

    # Add all issues
    for issue in "${A11Y_ERRORS[@]}" "${A11Y_WARNINGS[@]}" "${A11Y_INFO[@]}"; do
        IFS=':' read -r file line level rule message <<< "$issue"
        # Escape quotes in CSV
        message="${message//\"/\"\"}"
        echo "\"$file\",$line,\"$level\",\"$rule\",\"$message\"" >> "$output_file"
    done
}

generate_text_report() {
    local output_file="$1"

    cat > "$output_file" << EOF
ACCESSIBILITY COMPLIANCE REPORT
Generated: $(date)

SUMMARY
=======
Errors:   ${#A11Y_ERRORS[@]}
Warnings: ${#A11Y_WARNINGS[@]}
Info:     ${#A11Y_INFO[@]}
Files:    $(echo "$A11Y_FILE_STATS" | wc -w)

EOF

    if [[ ${#A11Y_ERRORS[@]} -gt 0 ]]; then
        echo "ERRORS" >> "$output_file"
        echo "======" >> "$output_file"
        for issue in "${A11Y_ERRORS[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            echo "$file:$line [$rule] $message" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi

    if [[ ${#A11Y_WARNINGS[@]} -gt 0 ]]; then
        echo "WARNINGS" >> "$output_file"
        echo "========" >> "$output_file"
        for issue in "${A11Y_WARNINGS[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            echo "$file:$line [$rule] $message" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi

    if [[ ${#A11Y_INFO[@]} -gt 0 ]]; then
        echo "INFORMATION" >> "$output_file"
        echo "===========" >> "$output_file"
        for issue in "${A11Y_INFO[@]}"; do
            IFS=':' read -r file line level rule message <<< "$issue"
            echo "$file:$line [$rule] $message" >> "$output_file"
        done
        echo "" >> "$output_file"
    fi
}

# Usage information
show_usage() {
    cat << EOF
Accessibility Compliance Checker v${A11Y_VERSION}

USAGE:
    $(basename "$0") [OPTIONS] [FILES...]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress progress indicators
    -r, --report-dir DIR    Report output directory (default: $DEFAULT_OUTPUT_DIR)
    -f, --format FORMAT     Report format: html, json, csv, text (default: $DEFAULT_OUTPUT_FORMAT)
    --no-color              Disable colored output
    --config FILE           Use custom config file

EXAMPLES:
    # Check all markdown files in current directory
    $(basename "$0") *.md

    # Check specific files with HTML report
    $(basename "$0") -f html docs/*.md

    # Check all files recursively with verbose output
    find . -name "*.md" -exec $(basename "$0") -v {} +

CHECKS PERFORMED:
    - Image alt text validation
    - Heading hierarchy compliance
    - Link text quality assessment
    - Color contrast in code blocks
    - Table header verification
    - Language attribute checking
    - ARIA label validation
    - General accessibility best practices

REPORT FORMATS:
    html    - Interactive HTML report with styling
    json    - Machine-readable JSON format
    csv     - Spreadsheet-compatible CSV format
    text    - Plain text summary report

EXIT CODES:
    0       - No accessibility errors found
    1       - Accessibility errors found
    2       - Script error or invalid usage

For more information, see: https://github.com/your-org/living-docs
EOF
}

# Main function
main() {
    local files=()
    local report_dir="$DEFAULT_OUTPUT_DIR"
    local format="$DEFAULT_OUTPUT_FORMAT"
    local verbose=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                export VERBOSE=1
                verbose=true
                shift
                ;;
            -q|--quiet)
                export QUIET=1
                shift
                ;;
            -r|--report-dir)
                report_dir="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                if [[ ! "$format" =~ ^(html|json|csv|text)$ ]]; then
                    echo "Error: Invalid format '$format'. Use: html, json, csv, text" >&2
                    exit 2
                fi
                shift 2
                ;;
            --no-color)
                export NO_COLOR=1
                setup_a11y_colors
                shift
                ;;
            --config)
                # TODO: Implement config file loading
                echo "Config file support not yet implemented" >&2
                shift 2
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                show_usage >&2
                exit 2
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # If no files specified, look for markdown files
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No files specified. Looking for markdown files..."
        mapfile -t files < <(find . -name "*.md" -type f 2>/dev/null)

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No markdown files found." >&2
            exit 2
        fi
    fi

    echo "Checking ${#files[@]} files for accessibility compliance..."

    # Process files with progress indication
    local current=0
    local total=${#files[@]}

    for file in "${files[@]}"; do
        ((current++))

        if [[ "${QUIET:-}" != "1" ]]; then
            step_progress "$current" "$total" "$(basename "$file")"
        fi

        check_file_accessibility "$file"
    done

    # Generate summary
    echo ""
    echo "Accessibility check complete:"
    echo "  Files checked: $(echo "$A11Y_FILE_STATS" | wc -w)"
    echo "  Errors: ${#A11Y_ERRORS[@]}"
    echo "  Warnings: ${#A11Y_WARNINGS[@]}"
    echo "  Info: ${#A11Y_INFO[@]}"

    # Generate report
    generate_report "$report_dir" "$format"

    # Exit with appropriate code
    if [[ ${#A11Y_ERRORS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${A11Y_RED}Accessibility errors found!${A11Y_RESET}"
        exit 1
    else
        echo ""
        echo -e "${A11Y_GREEN}No accessibility errors found.${A11Y_RESET}"
        exit 0
    fi
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi