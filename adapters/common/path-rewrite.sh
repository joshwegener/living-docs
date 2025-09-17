#!/bin/bash

# Path Rewriting Engine for Multi-Spec Adapters
# Handles dynamic path substitution based on user preferences

set -e

# Function to perform path substitution
rewrite_paths() {
    local file="$1"
    local living_docs_path="${2:-docs}"
    local ai_path="${3:-$living_docs_path}"
    local specs_path="${4:-$living_docs_path/specs}"
    local memory_path="${5:-$living_docs_path/memory}"
    local scripts_path="${6:-$living_docs_path/scripts}"

    # Detect OS for sed compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed requires -i ''
        sed -i '' \
            -e "s|{{LIVING_DOCS_PATH}}|${living_docs_path}|g" \
            -e "s|{{AI_PATH}}|${ai_path}|g" \
            -e "s|{{SPECS_PATH}}|${specs_path}|g" \
            -e "s|{{MEMORY_PATH}}|${memory_path}|g" \
            -e "s|{{SCRIPTS_PATH}}|${scripts_path}|g" \
            -e "s|docs/specs/|${specs_path}/|g" \
            -e "s|docs/memory/|${memory_path}/|g" \
            -e "s|docs/scripts/|${scripts_path}/|g" \
            "$file"
    else
        # Linux sed
        sed -i \
            -e "s|{{LIVING_DOCS_PATH}}|${living_docs_path}|g" \
            -e "s|{{AI_PATH}}|${ai_path}|g" \
            -e "s|{{SPECS_PATH}}|${specs_path}|g" \
            -e "s|{{MEMORY_PATH}}|${memory_path}|g" \
            -e "s|{{SCRIPTS_PATH}}|${scripts_path}|g" \
            -e "s|docs/specs/|${specs_path}/|g" \
            -e "s|docs/memory/|${memory_path}/|g" \
            -e "s|docs/scripts/|${scripts_path}/|g" \
            "$file"
    fi
}

# Function to rewrite all files in a directory
rewrite_directory() {
    local dir="$1"
    local living_docs_path="$2"
    local ai_path="$3"
    local specs_path="$4"
    local memory_path="$5"
    local scripts_path="$6"

    # Find all text files that might need rewriting
    find "$dir" -type f \( \
        -name "*.md" -o \
        -name "*.sh" -o \
        -name "*.yml" -o \
        -name "*.yaml" -o \
        -name "*.json" -o \
        -name "*.txt" \
    \) -print0 | while IFS= read -r -d '' file; do
        echo "  Rewriting: $(basename "$file")"
        rewrite_paths "$file" "$living_docs_path" "$ai_path" "$specs_path" "$memory_path" "$scripts_path"
    done
}

# Function to expand path variables in config
expand_path() {
    local path="$1"
    local living_docs_path="${2:-docs}"
    local ai_path="${3:-$living_docs_path}"
    local specs_path="${4:-$living_docs_path/specs}"
    local memory_path="${5:-$living_docs_path/memory}"
    local scripts_path="${6:-$living_docs_path/scripts}"

    echo "$path" | sed \
        -e "s|{{LIVING_DOCS_PATH}}|${living_docs_path}|g" \
        -e "s|{{AI_PATH}}|${ai_path}|g" \
        -e "s|{{SPECS_PATH}}|${specs_path}|g" \
        -e "s|{{MEMORY_PATH}}|${memory_path}|g" \
        -e "s|{{SCRIPTS_PATH}}|${scripts_path}|g"
}

# Export functions for use in other scripts
export -f rewrite_paths
export -f rewrite_directory
export -f expand_path