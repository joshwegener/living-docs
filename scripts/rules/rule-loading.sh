#!/bin/bash
# Rule Loading Service - Load and include framework-specific rules

# get_installed_specs() - Parse installed frameworks from config
# Output: Space-separated list of framework names
get_installed_specs() {
    local config="${LIVING_DOCS_CONFIG:-.living-docs.config}"

    if [ ! -f "$config" ]; then
        return 0
    fi

    # Extract INSTALLED_SPECS value and trim quotes
    local specs=$(grep "^INSTALLED_SPECS=" "$config" 2>/dev/null | cut -d'=' -f2- | tr -d '"')
    echo "$specs"
}

# discover_rule_files() - Find rule files for given frameworks
# Input: $1 = frameworks (space-separated)
# Output: Newline-separated list of rule file paths
discover_rule_files() {
    local frameworks="$1"

    if [ -z "$frameworks" ]; then
        return 0
    fi

    local rule_files=""
    for framework in $frameworks; do
        local rule_file="docs/rules/${framework}-rules.md"
        if [ -f "$rule_file" ]; then
            if [ -n "$rule_files" ]; then
                rule_files="${rule_files}\n${rule_file}"
            else
                rule_files="$rule_file"
            fi
        fi
    done

    if [ -n "$rule_files" ]; then
        echo -e "$rule_files"
    fi
}

# validate_rule_file() - Validate a rule file has required content
# Input: $1 = rule file path
# Output: "VALID" or error message
validate_rule_file() {
    local rule_file="$1"

    if [ ! -f "$rule_file" ]; then
        echo "ERROR: Rule file not found: $rule_file"
        return 1
    fi

    # Check if file is empty
    if [ ! -s "$rule_file" ]; then
        echo "ERROR: Rule file is empty: $rule_file"
        return 1
    fi

    # Check for Gate definitions (must have proper gate header)
    if ! grep -qi "^##.*gate" "$rule_file" && ! grep -qi "^### gate" "$rule_file"; then
        echo "ERROR: No gates defined in rule file: $rule_file"
        return 1
    fi

    # Check if it's a binary file
    if file "$rule_file" | grep -q "binary"; then
        echo "ERROR: Rule file appears to be binary: $rule_file"
        return 1
    fi

    echo "VALID"
}

# include_rules_in_bootstrap() - Update bootstrap with rule references
# Input: $1 = bootstrap file path, $2 = rule files (newline-separated)
# Output: "SUCCESS" or error message
include_rules_in_bootstrap() {
    local bootstrap="$1"
    local rule_files="$2"

    if [ ! -f "$bootstrap" ]; then
        echo "ERROR: Bootstrap file not found: $bootstrap"
        return 1
    fi

    # Check for markers
    if ! grep -q "<!-- RULES_START -->" "$bootstrap" || ! grep -q "<!-- RULES_END -->" "$bootstrap"; then
        echo "ERROR: RULES_START/RULES_END markers not found in bootstrap"
        return 1
    fi

    # Create temporary file for new content
    local temp_file=$(mktemp)

    # Build the content to insert
    if [ -n "$rule_files" ]; then
        while IFS= read -r file; do
            if [ -z "$file" ]; then continue; fi

            # Extract framework name from filename
            local framework=$(basename "$file" | sed 's/-rules\.md$//')

            # Create markdown link with description
            echo "- [${framework} Rules](./${file#docs/}) - Framework-specific rules and gates" >> "$temp_file"
        done <<< "$rule_files"
    fi

    # Create a new bootstrap file with updated content
    local new_bootstrap=$(mktemp)
    local in_rules_section=0

    while IFS= read -r line; do
        if [[ "$line" == *"<!-- RULES_START -->"* ]]; then
            echo "$line" >> "$new_bootstrap"
            in_rules_section=1
            # Insert new content
            if [ -s "$temp_file" ]; then
                cat "$temp_file" >> "$new_bootstrap"
            fi
        elif [[ "$line" == *"<!-- RULES_END -->"* ]]; then
            in_rules_section=0
            echo "$line" >> "$new_bootstrap"
        elif [ $in_rules_section -eq 0 ]; then
            echo "$line" >> "$new_bootstrap"
        fi
    done < "$bootstrap"

    # Replace original file
    mv "$new_bootstrap" "$bootstrap"
    rm -f "$temp_file"

    echo "SUCCESS"
}