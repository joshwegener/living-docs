#!/bin/bash
set -euo pipefail
# Path Rewriting Engine for Adapter Installation System
# Handles detection and rewriting of hardcoded paths to use variables

# Define path mappings (bash 3.2 compatible)
# Format: search_pattern|replacement
PATH_MAPPINGS="
scripts/bash/|{{SCRIPTS_PATH}}/bash/
scripts/|{{SCRIPTS_PATH}}/
.spec/|{{SPECS_PATH}}/
memory/|{{MEMORY_PATH}}/
.claude/commands/|{{AI_PATH}}/commands/
.claude/agents/|{{AI_PATH}}/agents/
.github/copilot-agents/|{{AI_PATH}}/agents/
specs/|{{SPECS_PATH}}/
"

# Detect hardcoded paths in a file or directory
detect_paths() {
    local target="$1"
    local report_file="${2:-/dev/stdout}"

    local paths_found=0

    # Process single file or directory
    if [[ -f "$target" ]]; then
        check_file_for_paths "$target" "$report_file"
        paths_found=$?
    elif [[ -d "$target" ]]; then
        # Process all files in directory
        while IFS= read -r file; do
            if check_file_for_paths "$file" "$report_file"; then
                ((paths_found++))
            fi
        done < <(find "$target" -type f -name "*.md" -o -name "*.sh" -o -name "*.txt")
    else
        echo "Error: Target not found: $target" >&2
        return 1
    fi

    return $paths_found
}

# Check single file for hardcoded paths
check_file_for_paths() {
    local file="$1"
    local report_file="${2:-/dev/stdout}"

    local found=0

    while IFS='|' read -r pattern replacement; do
        [[ -z "${pattern}" ]] && continue
        if grep -q "$pattern" "$file"; then
            echo "Found hardcoded path in $file: $pattern" >> "$report_file"
            ((found++))
        fi
    done <<< "$PATH_MAPPINGS"

    return $found
}

# Create path mappings for rewriting
create_mappings() {
    local mappings_file="${1:-/tmp/path_mappings.txt}"

    # Generate sed script for path replacements
    {
        while IFS='|' read -r pattern replacement; do
            [[ -z "${pattern}" ]] && continue
            # Escape special characters for sed
            escaped_pattern=$(echo "$pattern" | sed 's/[[\.*^$(){}?+|]/\\&/g')
            escaped_replacement=$(echo "$replacement" | sed 's/[[\.*^$(){}?+|]/\\&/g')
            echo "s|$escaped_pattern|${escaped_replacement}|g"
        done <<< "$PATH_MAPPINGS"
    } > "$mappings_file"

    echo "${mappings_file}"
}

# Apply path rewrites to a file or directory
apply_rewrites() {
    local target="$1"
    local custom_paths="${2:-false}"

    # Create temporary directory for safe rewriting
    local temp_dir
    temp_dir=$(mktemp -d)

    # Create mappings file
    local mappings_file
    mappings_file=$(create_mappings)

    # Apply custom path substitutions if enabled
    if [[ "$custom_paths" == "true" ]]; then
        mappings_file=$(apply_custom_paths "$mappings_file")
    fi

    local success=0

    if [[ -f "$target" ]]; then
        # Process single file
        rewrite_file "$target" "$mappings_file" "$temp_dir"
        success=$?
    elif [[ -d "$target" ]]; then
        # Process directory
        rewrite_directory "$target" "$mappings_file" "$temp_dir"
        success=$?
    else
        echo "Error: Target not found: $target" >&2
        rm -rf "$temp_dir"
        rm -f "$mappings_file"
        return 1
    fi

    # Clean up
    rm -f "$mappings_file"
    rm -rf "$temp_dir"

    return $success
}

# Rewrite paths in a single file
rewrite_file() {
    local file="$1"
    local mappings_file="$2"
    local temp_dir="$3"

    local filename
    filename=$(basename "$file")
    local temp_file="$temp_dir/$filename"

    # Apply sed transformations
    if sed -f "$mappings_file" "$file" > "$temp_file"; then
        # Check if file changed
        if ! cmp -s "$file" "$temp_file"; then
            cp "$temp_file" "$file"
            echo "Rewritten: ${file}"
        fi
        return 0
    else
        echo "Error: Failed to rewrite $file" >&2
        return 1
    fi
}

# Rewrite paths in all files in a directory
rewrite_directory() {
    local dir="$1"
    local mappings_file="$2"
    local temp_dir="$3"

    local errors=0

    # Process all relevant files
    while IFS= read -r file; do
        if ! rewrite_file "$file" "$mappings_file" "$temp_dir"; then
            ((errors++))
        fi
    done < <(find "$dir" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" \))

    return $errors
}

# Apply custom path substitutions based on environment variables
apply_custom_paths() {
    local mappings_file="$1"
    local custom_mappings_file
    custom_mappings_file=$(mktemp)

    # Source sanitization library
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$script_dir/../security/sanitize-paths.sh" ]]; then
        source "$script_dir/../security/sanitize-paths.sh"
    else
        echo "Warning: Sanitization library not found, using defaults" >&2
        sanitize_path() { echo "$1" | tr -cd '[:alnum:]/_.-'; }
    fi

    # Create custom substitutions
    cat "$mappings_file" > "$custom_mappings_file"

    # Replace placeholders with sanitized paths
    local scripts_path specs_path memory_path ai_path
    scripts_path=$(sanitize_path "${SCRIPTS_PATH:-scripts}")
    specs_path=$(sanitize_path "${SPECS_PATH:-.spec}")
    memory_path=$(sanitize_path "${MEMORY_PATH:-memory}")
    ai_path=$(sanitize_path "${AI_PATH:-.claude}")

    echo "s|{{SCRIPTS_PATH}}|${scripts_path}|g" >> "$custom_mappings_file"
    echo "s|{{SPECS_PATH}}|${specs_path}|g" >> "$custom_mappings_file"
    echo "s|{{MEMORY_PATH}}|${memory_path}|g" >> "$custom_mappings_file"
    echo "s|{{AI_PATH}}|${ai_path}|g" >> "$custom_mappings_file"

    echo "${custom_mappings_file}"
}

# Validate that all paths use variables after rewriting
validate_rewritten_paths() {
    local target="$1"

    local validation_errors=0

    # Check for any remaining hardcoded paths
    while IFS='|' read -r pattern replacement; do
        [[ -z "${pattern}" ]] && continue
        if [[ -f "$target" ]]; then
            if grep -q "$pattern" "$target"; then
                echo "Validation Error: Hardcoded path still present in $target: $pattern" >&2
                ((validation_errors++))
            fi
        elif [[ -d "$target" ]]; then
            while IFS= read -r file; do
                if grep -q "$pattern" "$file"; then
                    echo "Validation Error: Hardcoded path still present in $file: $pattern" >&2
                    ((validation_errors++))
                fi
            done < <(find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" \))
        fi
    done <<< "$PATH_MAPPINGS"

    return $validation_errors
}

# Generate path rewrite report
generate_rewrite_report() {
    local target="$1"
    local report_file="${2:-/tmp/rewrite_report.txt}"

    {
        echo "Path Rewrite Report"
        echo "=================="
        echo "Target: ${target}"
        echo "Date: $(date)"
        echo ""
        echo "Configured Paths:"
        echo "  SCRIPTS_PATH: ${SCRIPTS_PATH:-scripts (default)}"
        echo "  SPECS_PATH: ${SPECS_PATH:-.spec (default)}"
        echo "  MEMORY_PATH: ${MEMORY_PATH:-memory (default)}"
        echo "  AI_PATH: ${AI_PATH:-.claude (default)}"
        echo ""
        echo "Files to Process:"

        if [[ -f "$target" ]]; then
            echo "  - ${target}"
        elif [[ -d "$target" ]]; then
            find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" \) | while read -r file; do
                echo "  - ${file}"
            done
        fi

        echo ""
        echo "Hardcoded Paths Found:"
        detect_paths "$target" "/dev/stdout" | sed 's/^/  /'

    } > "$report_file"

    echo "${report_file}"
}

# Reverse path rewrites (for uninstalling)
reverse_rewrites() {
    local target="$1"
    local original_paths_file="$2"

    if [[ ! -f "$original_paths_file" ]]; then
        echo "Error: Original paths file not found" >&2
        return 1
    fi

    # Apply reverse mappings from file
    while IFS='|' read -r rewritten original; do
        if [[ -f "$target" ]]; then
            sed -i.bak "s|$rewritten|$original|g" "$target"
        elif [[ -d "$target" ]]; then
            find "$target" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" \) -exec sed -i.bak "s|$rewritten|$original|g" {} \;
        fi
    done < "$original_paths_file"

    return 0
}

# Export functions for use by other scripts
export -f detect_paths
export -f check_file_for_paths
export -f create_mappings
export -f apply_rewrites
export -f rewrite_file
export -f rewrite_directory
export -f apply_custom_paths
export -f validate_rewritten_paths
export -f generate_rewrite_report
export -f reverse_rewrites