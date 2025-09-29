#!/bin/bash
set -euo pipefail
# Complete Removal Functions for Adapter Installation System
# Handles complete removal using manifest tracking

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manifest.sh" 2>/dev/null || true
source "$SCRIPT_DIR/prefix.sh" 2>/dev/null || true

# Main removal function
remove_adapter() {
    local adapter_name="$1"
    local options="${2:-}"

    if [[ -z "$adapter_name" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    # Parse options
    local dry_run=false
    local force=false
    local keep_config=false

    for opt in $options; do
        case $opt in
            --dry-run) dry_run=true ;;
            --force) force=true ;;
            --keep-config) keep_config=true ;;
        esac
    done

    echo "Removing adapter: $adapter_name"

    # Check if adapter exists
    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Adapter $adapter_name not found or not installed" >&2
        echo "Available adapters:"
        list_installed_adapters
        return 1
    fi

    # Load manifest data
    local manifest_data
    if ! manifest_data=$(load_manifest "$adapter_name"); then
        echo "Error: Failed to load manifest for $adapter_name" >&2
        return 1
    fi

    # Backup manifest before removal
    local backup_path
    if [[ "$dry_run" != "true" ]]; then
        backup_path=$(backup_manifest "$adapter_name")
        echo "Manifest backed up to: $backup_path"
    fi

    # Remove files tracked in manifest
    if ! remove_files "$adapter_name" "$dry_run"; then
        echo "Error: Failed to remove all files" >&2
        if [[ -n "$backup_path" ]]; then
            echo "Manifest backup available at: $backup_path"
        fi
        return 1
    fi

    # Clean up empty directories
    if ! cleanup_directories "$adapter_name" "$dry_run"; then
        echo "Warning: Some directories could not be removed" >&2
    fi

    # Remove adapter directory and manifest
    if [[ "$dry_run" != "true" ]]; then
        local adapter_dir="${PROJECT_ROOT:-$(pwd)}/adapters/$adapter_name"

        if [[ "$keep_config" == "true" ]]; then
            # Keep config files but remove everything else
            find "$adapter_dir" -type f ! -name "config.yml" ! -name "config.yaml" ! -name ".living-docs-manifest.json" -delete 2>/dev/null
            echo "Kept configuration files in $adapter_dir"
        else
            # Remove entire adapter directory
            if [[ -d "$adapter_dir" ]]; then
                rm -rf "$adapter_dir"
                echo "Removed adapter directory: $adapter_dir"
            fi
        fi
    fi

    echo " Adapter $adapter_name removed successfully"
    return 0
}

# Load manifest and return structured data
load_manifest() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Validate manifest before processing
    if ! validate_manifest "$adapter_name"; then
        echo "Error: Invalid manifest for adapter $adapter_name" >&2
        return 1
    fi

    # Return manifest content
    cat "$manifest_path"
}

# Remove all files tracked in manifest
remove_files() {
    local adapter_name="$1"
    local dry_run="${2:-false}"

    echo "Removing tracked files..."

    local files_to_remove
    files_to_remove=$(list_manifest_files "$adapter_name")

    if [[ -z "$files_to_remove" ]]; then
        echo "No files to remove"
        return 0
    fi

    local files_removed=0
    local files_not_found=0
    local errors=0

    while IFS= read -r file_path; do
        # Skip empty lines
        [[ -z "$file_path" ]] && continue

        # Convert relative paths to absolute
        if [[ ! "$file_path" =~ ^/ ]]; then
            file_path="${PROJECT_ROOT:-$(pwd)}/$file_path"
        fi

        if [[ "$dry_run" == "true" ]]; then
            if [[ -f "$file_path" ]]; then
                echo "Would remove: $file_path"
            else
                echo "Would remove (not found): $file_path"
            fi
        else
            if [[ -f "$file_path" ]]; then
                if rm "$file_path" 2>/dev/null; then
                    echo "   Removed: $file_path"
                    ((files_removed++))
                else
                    echo "   Failed to remove: $file_path" >&2
                    ((errors++))
                fi
            else
                echo "  - Not found (already removed): $file_path"
                ((files_not_found++))
            fi
        fi
    done <<< "$files_to_remove"

    if [[ "$dry_run" != "true" ]]; then
        echo "Files removed: $files_removed"
        echo "Files not found: $files_not_found"
        if [[ $errors -gt 0 ]]; then
            echo "Errors: $errors"
        fi
    fi

    return $errors
}

# Clean up empty directories left after file removal
cleanup_directories() {
    local adapter_name="$1"
    local dry_run="${2:-false}"

    echo "Cleaning up empty directories..."

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local directories_to_check=()

    # Get AI command directory
    local ai_dir
    ai_dir=$(get_ai_command_dir 2>/dev/null)
    if [[ -n "$ai_dir" ]]; then
        directories_to_check+=("$project_root/$ai_dir")
    fi

    # Add adapter-specific directories
    directories_to_check+=(
        "$project_root/adapters/$adapter_name/templates"
        "$project_root/adapters/$adapter_name/scripts"
        "$project_root/adapters/$adapter_name"
    )

    local cleaned=0
    local errors=0

    for dir in "${directories_to_check[@]}"; do
        if [[ -d "$dir" ]]; then
            # Check if directory is empty
            if [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo "Would remove empty directory: $dir"
                else
                    if rmdir "$dir" 2>/dev/null; then
                        echo "   Removed empty directory: $dir"
                        ((cleaned++))
                    else
                        echo "  - Could not remove directory: $dir" >&2
                        ((errors++))
                    fi
                fi
            fi
        fi
    done

    if [[ "$dry_run" != "true" ]]; then
        echo "Empty directories cleaned: $cleaned"
        if [[ $errors -gt 0 ]]; then
            echo "Directory cleanup errors: $errors"
        fi
    fi

    return 0
}

# List all installed adapters
list_installed_adapters() {
    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local adapters_dir="$project_root/adapters"

    if [[ ! -d "$adapters_dir" ]]; then
        echo "No adapters installed"
        return 0
    fi

    echo "Installed adapters:"
    while IFS= read -r manifest; do
        if [[ -f "$manifest" ]]; then
            local adapter_dir
            adapter_dir=$(dirname "$manifest")
            local adapter_name
            adapter_name=$(basename "$adapter_dir")

            local version
            version=$(read_manifest "$adapter_name" "version" 2>/dev/null || echo "unknown")

            local prefix
            prefix=$(read_manifest "$adapter_name" "prefix" 2>/dev/null || echo "none")

            echo "  - $adapter_name (v$version) [prefix: $prefix]"
        fi
    done < <(find "$adapters_dir" -name ".living-docs-manifest.json" 2>/dev/null)
}

# Remove specific file types from adapter
remove_file_type() {
    local adapter_name="$1"
    local file_type="$2"
    local dry_run="${3:-false}"

    if [[ -z "$adapter_name" || -z "$file_type" ]]; then
        echo "Error: adapter_name and file_type required" >&2
        return 1
    fi

    echo "Removing $file_type files for adapter: $adapter_name"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Extract files of specific type from manifest
    local files_to_remove
    files_to_remove=$(awk -v type="$file_type" '
    /"file_type"[[:space:]]*:[[:space:]]*"'"$file_type"'"/ {
        # Look backward for the file path
        for (i = NR-10; i < NR; i++) {
            if (line[i] ~ /"[^"]*"[[:space:]]*:[[:space:]]*{/) {
                gsub(/^[[:space:]]*"/, "", line[i])
                gsub(/"[[:space:]]*:[[:space:]]*{.*/, "", line[i])
                print line[i]
                break
            }
        }
    }
    { line[NR] = $0 }
    ' "$manifest_path")

    if [[ -z "$files_to_remove" ]]; then
        echo "No $file_type files found for adapter $adapter_name"
        return 0
    fi

    local removed=0
    local errors=0

    while IFS= read -r file_path; do
        [[ -z "$file_path" ]] && continue

        # Convert relative paths to absolute
        if [[ ! "$file_path" =~ ^/ ]]; then
            file_path="${PROJECT_ROOT:-$(pwd)}/$file_path"
        fi

        if [[ "$dry_run" == "true" ]]; then
            echo "Would remove $file_type file: $file_path"
        else
            if [[ -f "$file_path" ]]; then
                if rm "$file_path"; then
                    echo "   Removed $file_type file: $file_path"
                    ((removed++))
                else
                    echo "   Failed to remove: $file_path" >&2
                    ((errors++))
                fi
            else
                echo "  - $file_type file not found: $file_path"
            fi
        fi
    done <<< "$files_to_remove"

    if [[ "$dry_run" != "true" ]]; then
        echo "Removed $removed $file_type files with $errors errors"
    fi

    return $errors
}

# Verify removal completeness
verify_removal() {
    local adapter_name="$1"

    echo "Verifying removal of adapter: $adapter_name"

    local issues=0
    local project_root="${PROJECT_ROOT:-$(pwd)}"

    # Check if manifest still exists
    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")
    if [[ -f "$manifest_path" ]]; then
        echo "Issue: Manifest still exists: $manifest_path"
        ((issues++))
    fi

    # Check if adapter directory still exists
    local adapter_dir="$project_root/adapters/$adapter_name"
    if [[ -d "$adapter_dir" ]]; then
        echo "Issue: Adapter directory still exists: $adapter_dir"
        local remaining_files
        remaining_files=$(find "$adapter_dir" -type f | wc -l)
        echo "  Files remaining: $remaining_files"
        ((issues++))
    fi

    # Check for orphaned command files with adapter prefix
    local ai_dir
    ai_dir=$(get_ai_command_dir 2>/dev/null)
    if [[ -n "$ai_dir" && -d "$ai_dir" ]]; then
        local prefix
        prefix=$(echo "$adapter_name" | tr '[:upper:]' '[:lower:]' | tr -d '-')

        local orphaned_commands
        orphaned_commands=$(find "$ai_dir" -name "${prefix}_*.md" 2>/dev/null)
        if [[ -n "$orphaned_commands" ]]; then
            echo "Issue: Orphaned command files found:"
            echo "$orphaned_commands" | sed 's/^/  /'
            ((issues++))
        fi
    fi

    if [[ $issues -eq 0 ]]; then
        echo " Removal verification passed - adapter completely removed"
        return 0
    else
        echo " Removal verification failed - $issues issues found"
        return 1
    fi
}

# Export functions for use by other scripts
export -f remove_adapter
export -f load_manifest
export -f remove_files
export -f cleanup_directories
export -f list_installed_adapters
export -f remove_file_type
export -f verify_removal