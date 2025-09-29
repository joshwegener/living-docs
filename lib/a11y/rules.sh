#!/usr/bin/env bash
# Accessibility rules and validators
# Defines all accessibility checking rules

set -euo pipefail

# Rule definitions
declare -A A11Y_RULES

# Initialize rules
init_a11y_rules() {
    # Image rules
    A11Y_RULES[IMG_ALT]="Images must have descriptive alt text"
    A11Y_RULES[IMG_DECORATIVE]="Decorative images should have empty alt text"
    A11Y_RULES[IMG_CAPTION]="Complex images should have captions"

    # Link rules
    A11Y_RULES[LINK_TEXT]="Links must have descriptive text"
    A11Y_RULES[LINK_CONTEXT]="Link purpose must be clear from context"
    A11Y_RULES[LINK_REPETITIVE]="Avoid repetitive link text"

    # Heading rules
    A11Y_RULES[HEADING_SKIP]="Don't skip heading levels"
    A11Y_RULES[HEADING_EMPTY]="Headings must contain text"
    A11Y_RULES[HEADING_SINGLE_H1]="Only one H1 per document"

    # Table rules
    A11Y_RULES[TABLE_HEADERS]="Tables must have headers"
    A11Y_RULES[TABLE_CAPTION]="Complex tables need captions"
    A11Y_RULES[TABLE_SCOPE]="Use scope attributes for headers"

    # Color contrast rules
    A11Y_RULES[COLOR_CONTRAST]="Ensure sufficient color contrast"
    A11Y_RULES[COLOR_ONLY]="Don't rely on color alone"

    # Language rules
    A11Y_RULES[LANG_ATTR]="Specify document language"
    A11Y_RULES[LANG_CHANGE]="Mark language changes"

    # Navigation rules
    A11Y_RULES[NAV_SKIP]="Provide skip navigation links"
    A11Y_RULES[NAV_LANDMARKS]="Use proper landmarks"

    # Form rules
    A11Y_RULES[FORM_LABELS]="Form inputs need labels"
    A11Y_RULES[FORM_REQUIRED]="Mark required fields clearly"
    A11Y_RULES[FORM_ERRORS]="Error messages must be clear"

    # Media rules
    A11Y_RULES[MEDIA_TRANSCRIPT]="Provide transcripts for audio"
    A11Y_RULES[MEDIA_CAPTIONS]="Videos need captions"
}

# Get rule description
get_rule_description() {
    local rule="$1"
    echo "${A11Y_RULES[$rule]:-Unknown rule}"
}

# Check if rule is enabled
is_rule_enabled() {
    local rule="$1"
    local config_file="${2:-}"

    # Default: all rules enabled
    if [[ -z "$config_file" ]] || [[ ! -f "$config_file" ]]; then
        return 0
    fi

    # Check config for rule status
    if grep -q "^${rule}=disabled" "$config_file" 2>/dev/null; then
        return 1
    fi

    return 0
}

# Get rule severity
get_rule_severity() {
    local rule="$1"

    case "$rule" in
        IMG_ALT|HEADING_SKIP|TABLE_HEADERS|FORM_LABELS)
            echo "ERROR"
            ;;
        LINK_TEXT|HEADING_EMPTY|COLOR_CONTRAST)
            echo "WARNING"
            ;;
        *)
            echo "INFO"
            ;;
    esac
}

# Validate against WCAG 2.1 Level AA
validate_wcag_aa() {
    local file="$1"
    local issues=()

    # Required for WCAG 2.1 Level AA
    local required_rules=(
        "IMG_ALT"
        "LINK_TEXT"
        "HEADING_SKIP"
        "TABLE_HEADERS"
        "COLOR_CONTRAST"
        "LANG_ATTR"
        "FORM_LABELS"
        "MEDIA_CAPTIONS"
    )

    for rule in "${required_rules[@]}"; do
        if ! check_rule_compliance "$file" "$rule"; then
            issues+=("${rule}:${file}:Non-compliant with WCAG 2.1 Level AA")
        fi
    done

    printf '%s\n' "${issues[@]}"
}

# Check rule compliance
check_rule_compliance() {
    local file="$1"
    local rule="$2"

    # Rule-specific compliance checks
    case "$rule" in
        IMG_ALT)
            ! grep -q '!\[\]' "$file"
            ;;
        LINK_TEXT)
            ! grep -qE '\[(click here|here|link)\]' "$file"
            ;;
        HEADING_SKIP)
            check_heading_hierarchy "$file"
            ;;
        *)
            return 0
            ;;
    esac
}

# Check heading hierarchy
check_heading_hierarchy() {
    local file="$1"
    local prev_level=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^#+ ]]; then
            local heading="${line%%[^#]*}"
            local level="${#heading}"

            if [[ $level -gt $((prev_level + 1)) ]] && [[ $prev_level -ne 0 ]]; then
                return 1
            fi
            prev_level=$level
        fi
    done < "$file"

    return 0
}

# Initialize rules on source
init_a11y_rules

# Export functions
export -f get_rule_description
export -f is_rule_enabled
export -f get_rule_severity
export -f validate_wcag_aa
export -f check_rule_compliance
export -f check_heading_hierarchy