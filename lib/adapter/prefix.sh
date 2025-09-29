#!/bin/bash
set -euo pipefail
# Command Namespacing Functions for Adapter Installation System
# Handles prefix generation, application, and conflict detection

# Get AI command directory based on the current setup
get_ai_command_dir() {
    local ai_type="${1:-auto}"

    # Use AI_PATH if set
    if [[ -n "$AI_PATH" ]]; then
        echo "${AI_PATH}/commands"
        return 0
    fi

    # Auto-detect AI type from environment or existing directories
    if [[ "$ai_type" == "auto" ]]; then
        if [[ -d ".claude" ]]; then
            ai_type="claude"
        elif [[ -d ".cursor" ]]; then
            ai_type="cursor"
        elif [[ -d ".aider" ]]; then
            ai_type="aider"
        elif [[ -d ".github/copilot" ]]; then
            ai_type="copilot"
        elif [[ -d ".continue" ]]; then
            ai_type="continue"
        else
            # Default to claude if none found
            ai_type="claude"
        fi
    fi

    case "$ai_type" in
        claude)
            echo ".claude/commands"
            ;;
        cursor)
            echo ".cursor/commands"
            ;;
        aider)
            echo ".aider/commands"
            ;;
        copilot)
            echo ".github/copilot/commands"
            ;;
        continue)
            echo ".continue/commands"
            ;;
        *)
            echo "Error: Unknown AI type: $ai_type" >&2
            return 1
            ;;
    esac
}

# Generate prefix for an adapter to avoid conflicts
generate_prefix() {
    local adapter_name="$1"
    local existing_prefixes=("${@:2}")

    if [[ -z "$adapter_name" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    # Clean adapter name for prefix (remove hyphens, convert to lowercase)
    local base_prefix
    base_prefix=$(echo "$adapter_name" | tr '[:upper:]' '[:lower:]' | tr -d '-')

    # Check if base prefix conflicts with existing ones
    local prefix="$base_prefix"
    local counter=1

    while [[ " ${existing_prefixes[*]} " =~ " ${prefix} " ]]; do
        prefix="${base_prefix}${counter}"
        ((counter++))
    done

    echo "$prefix"
}

# Check for existing command conflicts in AI directories
check_conflicts() {
    local command_files=("$@")
    local conflicts=()

    # Get all AI command directories that exist
    local ai_dirs=()
    for ai_type in claude cursor aider copilot continue; do
        local ai_dir
        ai_dir=$(get_ai_command_dir "$ai_type" 2>/dev/null)
        if [[ -d "$ai_dir" ]]; then
            ai_dirs+=("$ai_dir")
        fi
    done

    # Check each command file against existing files in AI directories
    for cmd_file in "${command_files[@]}"; do
        local base_name
        base_name=$(basename "$cmd_file")

        for ai_dir in "${ai_dirs[@]}"; do
            if [[ -f "$ai_dir/$base_name" ]]; then
                conflicts+=("$ai_dir/$base_name")
            fi
        done
    done

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        printf "%s\n" "${conflicts[@]}"
        return 1
    fi

    return 0
}

# Apply prefix to command files
apply_prefix() {
    local prefix="$1"
    local source_dir="$2"
    local dest_dir="$3"
    local dry_run="${4:-false}"

    if [[ -z "$prefix" || -z "$source_dir" || -z "$dest_dir" ]]; then
        echo "Error: prefix, source_dir, and dest_dir required" >&2
        return 1
    fi

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Source directory not found: $source_dir" >&2
        return 1
    fi

    # Create destination directory if it doesn't exist (unless dry run)
    if [[ "$dry_run" != "true" && ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir"
    fi

    local files_processed=0
    local errors=0

    # Process all markdown files in source directory
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local base_name
            base_name=$(basename "$file")
            local prefixed_name="${prefix}_${base_name}"
            local dest_file="$dest_dir/$prefixed_name"

            if [[ "$dry_run" == "true" ]]; then
                echo "Would copy: $file -> $dest_file"
            else
                if cp "$file" "$dest_file"; then
                    echo "Applied prefix: $base_name -> $prefixed_name"
                    ((files_processed++))
                else
                    echo "Error: Failed to copy $file to $dest_file" >&2
                    ((errors++))
                fi
            fi
        fi
    done < <(find "$source_dir" -type f -name "*.md")

    if [[ "$dry_run" != "true" ]]; then
        echo "Processed $files_processed files with $errors errors"
    fi

    return $errors
}

# Check if prefixing is needed based on existing files and environment
should_apply_prefix() {
    local adapter_name="$1"
    local command_files=("${@:2}")

    # Check environment variable override
    if [[ "${LIVING_DOCS_NO_PREFIX}" == "true" ]]; then
        echo "false"
        return 0
    fi

    # If no command files to install, no prefix needed
    if [[ ${#command_files[@]} -eq 0 ]]; then
        echo "false"
        return 0
    fi

    # Check for conflicts
    local conflicts
    conflicts=$(check_conflicts "${command_files[@]}")
    local conflict_status=$?

    if [[ $conflict_status -eq 0 ]]; then
        # No conflicts found
        echo "false"
    else
        # Conflicts found, prefixing needed
        echo "true"
    fi

    return 0
}

# Get list of existing prefixes from installed adapters
get_existing_prefixes() {
    local prefixes=()

    # Check all adapter manifests for existing prefixes
    if [[ -d "adapters" ]]; then
        while IFS= read -r manifest; do
            if [[ -f "$manifest" ]]; then
                local prefix
                # Extract prefix from manifest JSON (basic parsing)
                prefix=$(grep '"prefix"' "$manifest" 2>/dev/null | sed 's/.*"prefix"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
                if [[ -n "$prefix" && "$prefix" != "null" ]]; then
                    prefixes+=("$prefix")
                fi
            fi
        done < <(find adapters -name ".living-docs-manifest.json" 2>/dev/null)
    fi

    printf "%s\n" "${prefixes[@]}"
}

# Remove prefix from command files (for uninstall)
remove_prefix() {
    local prefix="$1"
    local command_dir="$2"
    local dry_run="${3:-false}"

    if [[ -z "$prefix" || -z "$command_dir" ]]; then
        echo "Error: prefix and command_dir required" >&2
        return 1
    fi

    if [[ ! -d "$command_dir" ]]; then
        echo "Warning: Command directory not found: $command_dir" >&2
        return 0
    fi

    local files_removed=0
    local errors=0

    # Find and remove files with the given prefix
    while IFS= read -r file; do
        local base_name
        base_name=$(basename "$file")

        # Check if file starts with our prefix
        if [[ "$base_name" =~ ^${prefix}_.* ]]; then
            if [[ "$dry_run" == "true" ]]; then
                echo "Would remove: $file"
            else
                if rm "$file"; then
                    echo "Removed prefixed file: $file"
                    ((files_removed++))
                else
                    echo "Error: Failed to remove $file" >&2
                    ((errors++))
                fi
            fi
        fi
    done < <(find "$command_dir" -type f -name "${prefix}_*.md" 2>/dev/null)

    if [[ "$dry_run" != "true" ]]; then
        echo "Removed $files_removed files with $errors errors"
    fi

    return $errors
}

# Validate prefix format
validate_prefix() {
    local prefix="$1"

    if [[ -z "$prefix" ]]; then
        echo "Error: Empty prefix" >&2
        return 1
    fi

    # Check prefix format (alphanumeric, no spaces, reasonable length)
    if [[ ! "$prefix" =~ ^[a-z0-9]+$ ]]; then
        echo "Error: Invalid prefix format. Use lowercase letters and numbers only." >&2
        return 1
    fi

    if [[ ${#prefix} -gt 20 ]]; then
        echo "Error: Prefix too long (max 20 characters)" >&2
        return 1
    fi

    if [[ ${#prefix} -lt 2 ]]; then
        echo "Error: Prefix too short (min 2 characters)" >&2
        return 1
    fi

    return 0
}

# Generate prefix report for debugging
generate_prefix_report() {
    local adapter_name="$1"
    local report_file="${2:-/dev/stdout}"

    {
        echo "Prefix Report for Adapter: $adapter_name"
        echo "========================================"
        echo "Date: $(date)"
        echo ""
        echo "Environment:"
        echo "  LIVING_DOCS_NO_PREFIX: ${LIVING_DOCS_NO_PREFIX:-false}"
        echo ""
        echo "AI Directories Found:"
        for ai_type in claude cursor aider copilot continue; do
            local ai_dir
            ai_dir=$(get_ai_command_dir "$ai_type" 2>/dev/null)
            if [[ -d "$ai_dir" ]]; then
                echo "  - $ai_type: $ai_dir"
                echo "    Files: $(find "$ai_dir" -name "*.md" 2>/dev/null | wc -l)"
            fi
        done
        echo ""
        echo "Existing Prefixes:"
        local existing_prefixes
        readarray -t existing_prefixes < <(get_existing_prefixes)
        if [[ ${#existing_prefixes[@]} -gt 0 ]]; then
            printf "  - %s\n" "${existing_prefixes[@]}"
        else
            echo "  (none)"
        fi
        echo ""
        echo "Suggested Prefix:"
        local suggested_prefix
        suggested_prefix=$(generate_prefix "$adapter_name" "${existing_prefixes[@]}")
        echo "  $suggested_prefix"
        echo ""
        echo "Prefix Valid: $(validate_prefix "$suggested_prefix" >/dev/null 2>&1 && echo "Yes" || echo "No")"

    } > "$report_file"

    echo "$report_file"
}

# Export functions for use by other scripts
export -f get_ai_command_dir
export -f generate_prefix
export -f check_conflicts
export -f apply_prefix
export -f should_apply_prefix
export -f get_existing_prefixes
export -f remove_prefix
export -f validate_prefix
export -f generate_prefix_report