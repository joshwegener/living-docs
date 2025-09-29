#!/bin/bash
set -euo pipefail
# Manifest Management Functions for Adapter Installation System
# Handles creation, reading, updating, and validation of adapter manifests

# Source security functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../security/input-validation.sh"

# Get manifest path for an adapter
get_manifest_path() {
    local adapter_name="$1"

    # Validate adapter name to prevent path traversal
    adapter_name=$(validate_adapter_name "$adapter_name") || return 1

    echo "${PROJECT_ROOT:-$(pwd)}/adapters/${adapter_name}/.living-docs-manifest.json"
}

# Create a new manifest for an installed adapter
create_manifest() {
    local adapter_name="$1"
    local version="$2"
    local prefix="$3"

    # Validate all inputs
    adapter_name=$(validate_adapter_name "$adapter_name") || return 1
    version=$(validate_version "$version") || return 1
    prefix=$(validate_prefix "$prefix") || return 1

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    # Create adapter directory if it doesn't exist
    mkdir -p "$(dirname "$manifest_path")"

    # Create manifest with initial structure
    cat > "$manifest_path" <<EOF
{
    "adapter": "$adapter_name",
    "version": "$version",
    "installed": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "prefix": "$prefix",
    "files": {},
    "commands": [],
    "agents": []
}
EOF

    # Generate and store integrity checksum
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$script_dir/../security/manifest-integrity.sh" ]]; then
        source "$script_dir/../security/manifest-integrity.sh"
        store_manifest_checksum "$manifest_path" 2>/dev/null || true
    fi

    echo "${manifest_path}"
}

# Read manifest and return specific field
read_manifest() {
    local adapter_name="$1"
    local field="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    if [[ -z "${field}" ]]; then
        # Return entire manifest
        cat "$manifest_path"
    else
        # Return specific field using simple JSON parsing
        grep "\"$field\"" "$manifest_path" | head -1 | sed 's/.*"'"$field"'"\s*:\s*"\?\([^",]*\)"\?.*/\1/'
    fi
}

# Update manifest with new file entry
update_manifest() {
    local adapter_name="$1"
    local file_path="$2"
    local checksum="$3"
    local original_path="$4"
    local file_type="${5:-script}"

    # Validate and escape inputs
    adapter_name=$(validate_adapter_name "$adapter_name") || return 1
    file_path=$(sanitize_path "$file_path") || return 1
    file_path=$(escape_awk "$file_path")
    checksum=$(echo "$checksum" | grep -E '^[a-f0-9]{64}$') || {
        echo "Error: Invalid checksum format" >&2
        return 1
    }
    original_path=$(sanitize_path "$original_path") || return 1
    original_path=$(escape_awk "$original_path")

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Create temporary file for manifest update
    local temp_manifest
    temp_manifest=$(mktemp)

    # Read existing manifest and add file entry using awk for simple JSON manipulation
    awk -v file="$file_path" -v sum="$checksum" -v orig="$original_path" -v type="$file_type" '
    /"files"/ {
        print
        getline
        if ($0 ~ /^\s*\{\s*\}/) {
            print "        \"" file "\": {"
            print "            \"checksum\": \"" sum "\","
            print "            \"customized\": false,"
            print "            \"original_path\": \"" orig "\","
            print "            \"file_type\": \"" type "\""
            print "        }"
        } else {
            print
            # Add to existing files
            print "        ,\"" file "\": {"
            print "            \"checksum\": \"" sum "\","
            print "            \"customized\": false,"
            print "            \"original_path\": \"" orig "\","
            print "            \"file_type\": \"" type "\""
            print "        }"
        }
        next
    }
    { print }
    ' "$manifest_path" > "$temp_manifest"

    # Replace original manifest
    mv "$temp_manifest" "$manifest_path"
}

# Add command to manifest
add_command_to_manifest() {
    local adapter_name="$1"
    local command_name="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Update commands array
    local temp_manifest
    temp_manifest=$(mktemp)

    awk -v cmd="$command_name" '
    /"commands"/ {
        print
        getline
        if ($0 ~ /\[\s*\]/) {
            print "        \"" cmd "\""
            print "    ]"
            next
        } else {
            # Add to existing commands
            gsub(/\]/, ", \"" cmd "\"]", $0)
            print
            next
        }
    }
    { print }
    ' "$manifest_path" > "$temp_manifest"

    mv "$temp_manifest" "$manifest_path"
}

# Add agent to manifest
add_agent_to_manifest() {
    local adapter_name="$1"
    local agent_name="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Update agents array similarly to commands
    local temp_manifest
    temp_manifest=$(mktemp)

    awk -v agent="$agent_name" '
    /"agents"/ {
        print
        getline
        if ($0 ~ /\[\s*\]/) {
            print "        \"" agent "\""
            print "    ]"
            next
        } else {
            # Add to existing agents
            gsub(/\]/, ", \"" agent "\"]", $0)
            print
            next
        }
    }
    { print }
    ' "$manifest_path" > "$temp_manifest"

    mv "$temp_manifest" "$manifest_path"
}

# Mark file as customized in manifest
mark_customized() {
    local adapter_name="$1"
    local file_path="$2"
    local original_checksum="$3"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Update customized flag and store original checksum
    local temp_manifest
    temp_manifest=$(mktemp)

    awk -v file="$file_path" -v orig_sum="$original_checksum" '
    /"'"$file_path"'"/ {
        found = 1
    }
    found && /"customized"/ {
        sub(/"customized": false/, "\"customized\": true")
        print
        if (orig_sum != "") {
            print "            ,\"original_checksum\": \"" orig_sum "\""
        }
        found = 0
        next
    }
    { print }
    ' "$manifest_path" > "$temp_manifest"

    mv "$temp_manifest" "$manifest_path"
}

# Validate manifest against schema
validate_manifest() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Basic validation (check required fields)
    local errors=0

    # Check required fields
    for field in adapter version installed files; do
        if ! grep -q "\"$field\"" "$manifest_path"; then
            echo "Error: Missing required field: $field" >&2
            ((errors++))
        fi
    done

    # Check adapter name format
    local adapter_field
    adapter_field=$(read_manifest "$adapter_name" "adapter")
    if ! [[ "$adapter_field" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo "Error: Invalid adapter name format: $adapter_field" >&2
        ((errors++))
    fi

    # Check version format
    local version_field
    version_field=$(read_manifest "$adapter_name" "version")
    if ! [[ "$version_field" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo "Error: Invalid version format: $version_field" >&2
        ((errors++))
    fi

    return $errors
}

# List all files in manifest
list_manifest_files() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Extract file paths from manifest
    grep -o '"[^"]*":.*{' "$manifest_path" | grep -v '"files"' | sed 's/"\([^"]*\)".*/\1/' | grep -v '^[[:space:]]*$'
}

# Get file checksum from manifest
get_file_checksum() {
    local adapter_name="$1"
    local file_path="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        return 1
    fi

    # Extract checksum for specific file
    awk -v file="$file_path" '
    /"'"$file_path"'"/ { found = 1 }
    found && /"checksum"/ {
        gsub(/.*"checksum"[[:space:]]*:[[:space:]]*"/, "")
        gsub(/".*/, "")
        print
        exit
    }
    ' "$manifest_path"
}

# Check if file is customized
is_file_customized() {
    local adapter_name="$1"
    local file_path="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        return 1
    fi

    # Check customized flag for specific file
    awk -v file="$file_path" '
    /"'"$file_path"'"/ { found = 1 }
    found && /"customized"/ {
        if ($0 ~ /"customized"[[:space:]]*:[[:space:]]*true/) {
            exit 0
        } else {
            exit 1
        }
    }
    END { exit 1 }
    ' "$manifest_path"
}

# Backup manifest before updates
backup_manifest() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    local backup_path="${manifest_path}.backup"
    cp "$manifest_path" "$backup_path"
    echo "${backup_path}"
}

# Restore manifest from backup
restore_manifest() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")
    local backup_path="${manifest_path}.backup"

    if [[ ! -f "$backup_path" ]]; then
        echo "Error: Backup not found for adapter $adapter_name" >&2
        return 1
    fi

    mv "$backup_path" "$manifest_path"
    echo "Manifest restored for ${adapter_name}"
}

# Calculate SHA256 checksum for a file
calculate_checksum() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi

    # Use shasum or sha256sum depending on availability
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file_path" | cut -d' ' -f1
    else
        echo "Error: No SHA256 tool available" >&2
        return 1
    fi
}

# Export functions for use by other scripts
export -f get_manifest_path
export -f create_manifest
export -f read_manifest
export -f update_manifest
export -f add_command_to_manifest
export -f add_agent_to_manifest
export -f mark_customized
export -f validate_manifest
export -f list_manifest_files
export -f get_file_checksum
export -f is_file_customized
export -f backup_manifest
export -f restore_manifest
export -f calculate_checksum