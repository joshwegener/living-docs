#!/bin/bash
# Path Validation Functions for Adapter Installation System
# Handles validation of paths in templates and configurations

# Valid path variables that should be used in templates (bash 3.2+ compatible)
is_valid_path_variable() {
    local var="$1"
    case "$var" in
        "{{SCRIPTS_PATH}}"|"{{SPECS_PATH}}"|"{{MEMORY_PATH}}"|"{{AI_PATH}}"|"{{PROJECT_ROOT}}") return 0 ;;
        *) return 1 ;;
    esac
}

get_path_variable_description() {
    local var="$1"
    case "$var" in
        "{{SCRIPTS_PATH}}") echo "scripts" ;;
        "{{SPECS_PATH}}") echo "specs or .spec" ;;
        "{{MEMORY_PATH}}") echo "memory" ;;
        "{{AI_PATH}}") echo "AI assistant directory (.claude, .cursor, etc.)" ;;
        "{{PROJECT_ROOT}}") echo "project root directory" ;;
        *) echo "unknown" ;;
    esac
}

# Path patterns that should be flagged as potential issues
declare -a DANGEROUS_PATTERNS=(
    "../"              # Path traversal
    "~/"               # Home directory reference
    "/tmp/"            # Temp directory reference
    "/var/"            # System directory reference
    "/usr/"            # System directory reference
    "/etc/"            # System directory reference
    "\$HOME"           # Environment variable reference
    "\${HOME}"         # Environment variable reference
)

# Validate that a file or directory contains no absolute paths
validate_no_absolute() {
    local target="$1"
    local report_file="${2:-/dev/stdout}"
    local errors=0
    local warnings=0

    if [[ ! -e "$target" ]]; then
        echo "Error: Target not found: $target" >&2
        return 1
    fi

    {
        echo "Absolute Path Validation Report"
        echo "=============================="
        echo "Target: $target"
        echo "Date: $(date)"
        echo ""
        echo "Errors:"
    } > "$report_file"

    # Check for absolute paths
    if [[ -f "$target" ]]; then
        check_file_absolute_paths "$target" "$report_file"
        local file_errors=$?
        ((errors += file_errors))
    elif [[ -d "$target" ]]; then
        while IFS= read -r file; do
            check_file_absolute_paths "$file" "$report_file"
            local file_errors=$?
            ((errors += file_errors))
        done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" \))
    fi

    # Add warnings section
    {
        echo ""
        echo "Warnings:"
    } >> "$report_file"

    # Check for dangerous patterns
    if [[ -f "$target" ]]; then
        check_file_dangerous_patterns "$target" "$report_file"
        local file_warnings=$?
        ((warnings += file_warnings))
    elif [[ -d "$target" ]]; then
        while IFS= read -r file; do
            check_file_dangerous_patterns "$file" "$report_file"
            local file_warnings=$?
            ((warnings += file_warnings))
        done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" \))
    fi

    {
        echo ""
        echo "Summary:"
        echo "  Errors: $errors"
        echo "  Warnings: $warnings"
        echo "  Status: $(if [[ $errors -eq 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"
    } >> "$report_file"

    return $errors
}

# Check a single file for absolute paths
check_file_absolute_paths() {
    local file="$1"
    local report_file="$2"
    local errors=0

    # Look for lines that appear to be absolute paths
    local line_num=1
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            ((line_num++))
            continue
        fi

        # Check for absolute paths (starts with / followed by non-space, or starts with ~/)
        # Extract potential paths from the line
        local words=($line)
        for word in "${words[@]}"; do
            # Check if word starts with / (absolute) or ~/ (home)
            if [[ "$word" =~ ^/[^/] ]] || [[ "$word" =~ ^~/ ]]; then
                # Exclude if it's part of a variable substitution
                if [[ ! "$line" =~ \{\{.*$word.*\}\} ]]; then
                    echo "  $file:$line_num - Absolute path found: $word" >> "$report_file"
                    ((errors++))
                    break
                fi
            fi
        done

        ((line_num++))
    done < "$file"

    return $errors
}

# Check a single file for dangerous path patterns
check_file_dangerous_patterns() {
    local file="$1"
    local report_file="$2"
    local warnings=0

    local line_num=1
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            ((line_num++))
            continue
        fi

        # Check for dangerous patterns
        for pattern in "${DANGEROUS_PATTERNS[@]}"; do
            if [[ "$line" =~ $pattern ]]; then
                echo "  $file:$line_num - Dangerous pattern '$pattern': $(echo "$line" | sed 's/^[[:space:]]*//')" >> "$report_file"
                ((warnings++))
            fi
        done

        ((line_num++))
    done < "$file"

    return $warnings
}

# Check that path variables are properly formatted
check_variables() {
    local target="$1"
    local report_file="${2:-/dev/stdout}"
    local errors=0
    local warnings=0

    if [[ ! -e "$target" ]]; then
        echo "Error: Target not found: $target" >&2
        return 1
    fi

    {
        echo "Path Variable Validation Report"
        echo "=============================="
        echo "Target: $target"
        echo "Date: $(date)"
        echo ""
        echo "Valid Variables:"
        for var in "{{SCRIPTS_PATH}}" "{{SPECS_PATH}}" "{{MEMORY_PATH}}" "{{AI_PATH}}" "{{PROJECT_ROOT}}"; do
            echo "  $var - $(get_path_variable_description "$var")"
        done
        echo ""
        echo "Issues Found:"
    } > "$report_file"

    if [[ -f "$target" ]]; then
        check_file_variables "$target" "$report_file"
        local file_issues=$?
        ((errors += file_issues))
    elif [[ -d "$target" ]]; then
        while IFS= read -r file; do
            check_file_variables "$file" "$report_file"
            local file_issues=$?
            ((errors += file_issues))
        done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" \))
    fi

    {
        echo ""
        echo "Summary:"
        echo "  Issues: $errors"
        echo "  Status: $(if [[ $errors -eq 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"
    } >> "$report_file"

    return $errors
}

# Check a single file for path variable issues
check_file_variables() {
    local file="$1"
    local report_file="$2"
    local issues=0

    local line_num=1
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            ((line_num++))
            continue
        fi

        # Look for malformed variables (e.g., {VARIABLE} instead of {{VARIABLE}})
        if [[ "$line" =~ \{[A-Z_]+\} ]] && [[ ! "$line" =~ \{\{[A-Z_]+\}\} ]]; then
            echo "  $file:$line_num - Malformed variable (use {{VARIABLE}}): $(echo "$line" | sed 's/^[[:space:]]*//')" >> "$report_file"
            ((issues++))
        fi

        # Look for unknown variables
        while [[ "$line" =~ \{\{([A-Z_]+)\}\} ]]; do
            local var_name="${BASH_REMATCH[1]}"
            local full_var="{{${var_name}}}"

            # Check if this is a known variable
            if ! is_valid_path_variable "$full_var"; then
                echo "  $file:$line_num - Unknown variable '$full_var': $(echo "$line" | sed 's/^[[:space:]]*//')" >> "$report_file"
                ((issues++))
            fi

            # Remove this match and continue checking
            line="${line/${BASH_REMATCH[0]}/}"
        done

        ((line_num++))
    done < "$file"

    return $issues
}

# Verify that path references in files actually exist or are valid
verify_references() {
    local target="$1"
    local base_dir="${2:-.}"
    local report_file="${3:-/dev/stdout}"
    local errors=0

    if [[ ! -e "$target" ]]; then
        echo "Error: Target not found: $target" >&2
        return 1
    fi

    {
        echo "Path Reference Validation Report"
        echo "==============================="
        echo "Target: $target"
        echo "Base Directory: $base_dir"
        echo "Date: $(date)"
        echo ""
        echo "Issues Found:"
    } > "$report_file"

    if [[ -f "$target" ]]; then
        check_file_references "$target" "$base_dir" "$report_file"
        local file_errors=$?
        ((errors += file_errors))
    elif [[ -d "$target" ]]; then
        while IFS= read -r file; do
            check_file_references "$file" "$base_dir" "$report_file"
            local file_errors=$?
            ((errors += file_errors))
        done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" -o -name "*.yml" -o -name "*.yaml" \))
    fi

    {
        echo ""
        echo "Summary:"
        echo "  Errors: $errors"
        echo "  Status: $(if [[ $errors -eq 0 ]]; then echo "PASS"; else echo "WARN"; fi)"
    } >> "$report_file"

    return $errors
}

# Check a single file for path reference issues
check_file_references() {
    local file="$1"
    local base_dir="$2"
    local report_file="$3"
    local errors=0

    local line_num=1
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            ((line_num++))
            continue
        fi

        # Look for potential file references (not variables)
        # This is a basic check for common patterns
        if [[ "$line" =~ [[:space:]]([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+\.[a-zA-Z0-9]+)[[:space:]] ]]; then
            local potential_path="${BASH_REMATCH[1]}"

            # Skip if it's a variable
            if [[ ! "$potential_path" =~ \{\{ ]]; then
                local full_path="$base_dir/$potential_path"
                if [[ ! -e "$full_path" ]]; then
                    echo "  $file:$line_num - Referenced file not found: $potential_path" >> "$report_file"
                    ((errors++))
                fi
            fi
        fi

        ((line_num++))
    done < "$file"

    return $errors
}

# Generate comprehensive path validation report
generate_path_validation_report() {
    local target="$1"
    local base_dir="${2:-.}"
    local report_file="${3:-/tmp/path_validation_report.txt}"

    {
        echo "Comprehensive Path Validation Report"
        echo "==================================="
        echo "Target: $target"
        echo "Base Directory: $base_dir"
        echo "Date: $(date)"
        echo ""
    } > "$report_file"

    # Run all validations
    local temp_dir
    temp_dir=$(mktemp -d)

    echo "Running absolute path validation..." >> "$report_file"
    validate_no_absolute "$target" "$temp_dir/absolute.txt"
    local absolute_errors=$?

    echo "Running variable validation..." >> "$report_file"
    check_variables "$target" "$temp_dir/variables.txt"
    local variable_errors=$?

    echo "Running reference validation..." >> "$report_file"
    verify_references "$target" "$base_dir" "$temp_dir/references.txt"
    local reference_errors=$?

    # Combine all reports
    {
        echo ""
        echo "=== ABSOLUTE PATH VALIDATION ==="
        cat "$temp_dir/absolute.txt"
        echo ""
        echo "=== VARIABLE VALIDATION ==="
        cat "$temp_dir/variables.txt"
        echo ""
        echo "=== REFERENCE VALIDATION ==="
        cat "$temp_dir/references.txt"
        echo ""
        echo "=== OVERALL SUMMARY ==="
        echo "Absolute Path Errors: $absolute_errors"
        echo "Variable Errors: $variable_errors"
        echo "Reference Errors: $reference_errors"
        echo "Total Errors: $((absolute_errors + variable_errors + reference_errors))"
        echo "Overall Status: $(if [[ $((absolute_errors + variable_errors + reference_errors)) -eq 0 ]]; then echo "PASS"; else echo "FAIL"; fi)"
    } >> "$report_file"

    # Clean up
    rm -rf "$temp_dir"

    echo "$report_file"
}

# Quick validation check (returns 0 for pass, 1 for fail)
quick_validate() {
    local target="$1"
    local temp_file
    temp_file=$(mktemp)

    validate_no_absolute "$target" "$temp_file" >/dev/null 2>&1
    local absolute_result=$?

    check_variables "$target" "$temp_file" >/dev/null 2>&1
    local variable_result=$?

    rm -f "$temp_file"

    # Return 0 only if both checks pass
    if [[ $absolute_result -eq 0 && $variable_result -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Export functions for use by other scripts
export -f validate_no_absolute
export -f check_variables
export -f verify_references
export -f check_file_absolute_paths
export -f check_file_dangerous_patterns
export -f check_file_variables
export -f check_file_references
export -f generate_path_validation_report
export -f quick_validate