#!/bin/bash
# a11y/formatter.sh - Accessibility message formatting module
# Extracted from check.sh as part of DEBT-001 refactoring

set -euo pipefail

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Format error message
format_a11y_error() {
    local issue="${1:-}"
    local element="${2:-}"
    local line="${3:-0}"

    case "$issue" in
        missing-alt)
            echo "Missing alt attribute on <$element> at line $line"
            ;;
        missing-label)
            echo "Missing label for <$element> at line $line"
            ;;
        missing-lang)
            echo "Missing lang attribute on <$element> at line $line"
            ;;
        duplicate-id)
            echo "Duplicate ID '$element' found at line $line"
            ;;
        *)
            echo "Accessibility error: $issue on <$element> at line $line"
            ;;
    esac
}

# Format warning message
format_a11y_warning() {
    local issue="${1:-}"
    local element="${2:-}"
    local line="${3:-0}"

    case "$issue" in
        low-contrast)
            echo "Low contrast detected for $element at line $line"
            ;;
        heading-skip)
            echo "Heading hierarchy skipped at <$element> line $line"
            ;;
        empty-link)
            echo "Empty link text for <$element> at line $line"
            ;;
        *)
            echo "Accessibility warning: $issue on <$element> at line $line"
            ;;
    esac
}

# Colorize output based on severity
colorize_a11y_output() {
    local severity="${1:-}"
    local message="${2:-}"

    case "$severity" in
        critical|error)
            echo -e "${COLOR_RED}✗ $message${COLOR_RESET}"
            ;;
        warning)
            echo -e "${COLOR_YELLOW}⚠ $message${COLOR_RESET}"
            ;;
        info)
            echo -e "${COLOR_BLUE}ℹ $message${COLOR_RESET}"
            ;;
        success)
            echo -e "${COLOR_GREEN}✓ $message${COLOR_RESET}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Suggest fix for issue
suggest_a11y_fix() {
    local issue="${1:-}"

    case "$issue" in
        missing-alt)
            echo "Add alt=\"description\" to the img tag"
            ;;
        missing-label)
            echo "Add a <label for=\"id\"> or aria-label attribute"
            ;;
        missing-lang)
            echo "Add lang=\"en\" (or appropriate language) to html tag"
            ;;
        duplicate-id)
            echo "Ensure all ID attributes are unique"
            ;;
        low-contrast)
            echo "Increase contrast ratio to at least 4.5:1 for normal text"
            ;;
        heading-skip)
            echo "Use sequential heading levels (h1, h2, h3, etc.)"
            ;;
        empty-link)
            echo "Add descriptive text or aria-label to the link"
            ;;
        *)
            echo "Review accessibility guidelines for $issue"
            ;;
    esac
}

# Format issue for JSON output
format_json_issue() {
    local issue="${1:-}"
    local element="${2:-}"
    local line="${3:-0}"
    local severity="${4:-warning}"

    cat <<EOF
{
  "issue": "$issue",
  "element": "$element",
  "line": $line,
  "severity": "$severity",
  "message": "$(format_a11y_error "$issue" "$element" "$line")",
  "suggestion": "$(suggest_a11y_fix "$issue")"
}
EOF
}

# Format issue for CSV output
format_csv_issue() {
    local issue="${1:-}"
    local element="${2:-}"
    local line="${3:-0}"
    local severity="${4:-warning}"

    local message
    message=$(format_a11y_error "$issue" "$element" "$line")
    local suggestion
    suggestion=$(suggest_a11y_fix "$issue")

    echo "$issue,$element,$line,$severity,\"$message\",\"$suggestion\""
}

# Export functions
export -f format_a11y_error
export -f format_a11y_warning
export -f colorize_a11y_output
export -f suggest_a11y_fix
export -f format_json_issue
export -f format_csv_issue