#!/bin/bash
set -euo pipefail
# Smart Update Functions for Adapter Installation System
# Handles updates while preserving user customizations

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manifest.sh" 2>/dev/null || true
source "$SCRIPT_DIR/rewrite.sh" 2>/dev/null || true
source "$SCRIPT_DIR/prefix.sh" 2>/dev/null || true
source "$SCRIPT_DIR/install.sh" 2>/dev/null || true

# Main update function
update_adapter() {
    local adapter_name="$1"
    local options="${2:-}"

    if [[ -z "${adapter_name}" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    # Parse options
    local dry_run=false
    local force_update=false
    local source_dir=""
    local show_diffs=true
    local backup_customizations=true

    for opt in $options; do
        case $opt in
            --dry-run) dry_run=true ;;
            --force) force_update=true ;;
            --source=*) source_dir="${opt#*=}" ;;
            --no-diffs) show_diffs=false ;;
            --no-backup) backup_customizations=false ;;
        esac
    done

    echo "Updating adapter: ${adapter_name}"

    # Check if adapter is installed
    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Adapter $adapter_name is not installed" >&2
        echo "Use install command instead"
        return 1
    fi

    # Get current version
    local current_version
    current_version=$(read_manifest "$adapter_name" "version")
    echo "Current version: ${current_version}"

    # Fetch upstream changes
    local upstream_dir
    if ! upstream_dir=$(fetch_upstream "$adapter_name" "$source_dir"); then
        echo "Error: Failed to fetch upstream changes" >&2
        return 1
    fi

    # Get new version
    local new_version
    new_version=$(get_adapter_version "$upstream_dir")
    echo "Upstream version: ${new_version}"

    # Check if update is needed
    if [[ "$current_version" == "$new_version" && "$force_update" != "true" ]]; then
        echo "Already up to date (use --force to update anyway)"
        rm -rf "$upstream_dir"
        return 0
    fi

    # Compare checksums and identify customized files
    echo "Analyzing changes..."
    local customized_files
    local changed_files
    local new_files

    if ! compare_checksums "$adapter_name" "$upstream_dir" customized_files changed_files new_files; then
        echo "Error: Failed to analyze changes" >&2
        rm -rf "$upstream_dir"
        return 1
    fi

    # Show what will be updated
    show_update_summary customized_files changed_files new_files "$show_diffs"

    # Backup customizations if requested
    local backup_dir=""
    if [[ "$backup_customizations" == "true" && ${#customized_files[@]} -gt 0 ]]; then
        backup_dir=$(backup_customizations "$adapter_name" "${customized_files[@]}")
        echo "Customizations backed up to: ${backup_dir}"
    fi

    # Perform the update
    if [[ "$dry_run" == "true" ]]; then
        echo "Dry run mode - no changes made"
        rm -rf "$upstream_dir"
        return 0
    fi

    if ! merge_changes "$adapter_name" "$upstream_dir" customized_files changed_files new_files; then
        echo "Error: Failed to merge changes" >&2
        if [[ -n "${backup_dir}" ]]; then
            echo "Customizations backup available at: ${backup_dir}"
        fi
        rm -rf "$upstream_dir"
        return 1
    fi

    # Update manifest
    update_manifest_version "$adapter_name" "$new_version"

    # Clean up
    rm -rf "$upstream_dir"

    echo " Adapter ${adapter_name} updated successfully"
    return 0
}

# Fetch upstream changes into temporary directory
fetch_upstream() {
    local adapter_name="$1"
    local source_dir="$2"

    local temp_dir
    temp_dir=$(mktemp -d)

    if [[ -n "${source_dir}" ]]; then
        # Use provided source directory
        if [[ ! -d "$source_dir" ]]; then
            echo "Error: Source directory not found: $source_dir" >&2
            rm -rf "$temp_dir"
            return 1
        fi

        echo "Using source: ${source_dir}"
        if ! cp -R "$source_dir"/* "$temp_dir/" 2>/dev/null; then
            echo "Error: Failed to copy from source directory" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    else
        # Try to fetch from common locations
        local project_root="${PROJECT_ROOT:-$(pwd)}"
        local possible_sources=(
            "$project_root/tmp/$adapter_name"
            "$project_root/downloads/$adapter_name"
            "$project_root/../$adapter_name"
        )

        local found_source=""
        for src in "${possible_sources[@]}"; do
            if [[ -d "$src" ]]; then
                found_source="$src"
                break
            fi
        done

        if [[ -z "${found_source}" ]]; then
            echo "Error: No upstream source found" >&2
            echo "Please specify source with --source=/path/to/upstream"
            rm -rf "$temp_dir"
            return 1
        fi

        echo "Using upstream source: ${found_source}"
        if ! cp -R "$found_source"/* "$temp_dir/" 2>/dev/null; then
            echo "Error: Failed to copy from upstream source" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    echo "${temp_dir}"
}

# Compare checksums between installed and upstream versions
compare_checksums() {
    local adapter_name="$1"
    local upstream_dir="$2"
    local -n customized_ref=$3
    local -n changed_ref=$4
    local -n new_ref=$5

    customized_ref=()
    changed_ref=()
    new_ref=()

    echo "Comparing file checksums..."

    # Get all files from manifest
    local manifest_files
    manifest_files=$(list_manifest_files "$adapter_name")

    # Check existing files
    while IFS= read -r file_path; do
        [[ -z "${file_path}" ]] && continue

        # Convert to absolute path
        if [[ ! "$file_path" =~ ^/ ]]; then
            file_path="${PROJECT_ROOT:-$(pwd)}/$file_path"
        fi

        # Get current checksum
        local current_checksum
        current_checksum=$(calculate_checksum "$file_path" 2>/dev/null)

        # Get manifest checksum
        local manifest_checksum
        manifest_checksum=$(get_file_checksum "$adapter_name" "$file_path")

        # Check if file is customized
        if [[ "$current_checksum" != "$manifest_checksum" ]]; then
            customized_ref+=("$file_path")
            echo "  Customized: $(basename "$file_path")"
        else
            # Check if upstream has changes
            local upstream_file
            upstream_file=$(find_upstream_file "$file_path" "$upstream_dir")

            if [[ -n "${upstream_file}" ]]; then
                local upstream_checksum
                upstream_checksum=$(calculate_checksum "$upstream_file")

                if [[ "$manifest_checksum" != "$upstream_checksum" ]]; then
                    changed_ref+=("$file_path:$upstream_file")
                    echo "  Changed: $(basename "$file_path")"
                fi
            fi
        fi
    done <<< "$manifest_files"

    # Check for new files in upstream
    local upstream_files
    upstream_files=$(find "$upstream_dir" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.txt" \))

    while IFS= read -r upstream_file; do
        [[ -z "${upstream_file}" ]] && continue

        local installed_file
        installed_file=$(find_installed_file "$upstream_file" "$upstream_dir")

        if [[ -z "$installed_file" || ! -f "$installed_file" ]]; then
            new_ref+=("$upstream_file")
            echo "  New: $(basename "$upstream_file")"
        fi
    done <<< "$upstream_files"

    return 0
}

# Find corresponding upstream file for installed file
find_upstream_file() {
    local installed_file="$1"
    local upstream_dir="$2"

    local basename_file
    basename_file=$(basename "$installed_file")

    # Remove prefix if present
    local prefix
    prefix=$(read_manifest "$(basename "$(dirname "$(dirname "$installed_file")")")" "prefix" 2>/dev/null)

    if [[ -n "$prefix" && "$basename_file" =~ ^${prefix}_.* ]]; then
        basename_file="${basename_file#${prefix}_}"
    fi

    # Look for file in upstream directories
    local possible_paths=(
        "$upstream_dir/commands/$basename_file"
        "$upstream_dir/templates/$basename_file"
        "$upstream_dir/scripts/$basename_file"
        "$upstream_dir/$basename_file"
    )

    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "${path}"
            return 0
        fi
    done

    return 1
}

# Find corresponding installed file for upstream file
find_installed_file() {
    local upstream_file="$1"
    local upstream_dir="$2"

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local adapter_name
    adapter_name=$(basename "$upstream_dir")

    local basename_file
    basename_file=$(basename "$upstream_file")

    # Determine likely installed location
    local upstream_subdir
    upstream_subdir=$(dirname "${upstream_file#$upstream_dir/}")

    local prefix
    prefix=$(read_manifest "$adapter_name" "prefix" 2>/dev/null)

    case "$upstream_subdir" in
        commands)
            local ai_dir
            ai_dir=$(get_ai_command_dir)
            if [[ -n "${prefix}" ]]; then
                echo "$project_root/$ai_dir/${prefix}_${basename_file}"
            else
                echo "$project_root/$ai_dir/${basename_file}"
            fi
            ;;
        templates)
            echo "$project_root/adapters/$adapter_name/templates/${basename_file}"
            ;;
        scripts)
            echo "$project_root/adapters/$adapter_name/scripts/${basename_file}"
            ;;
        *)
            echo "$project_root/adapters/$adapter_name/${basename_file}"
            ;;
    esac
}

# Show update summary
show_update_summary() {
    local -n customized_ref=$1
    local -n changed_ref=$2
    local -n new_ref=$3
    local show_diffs="$4"

    echo ""
    echo "Update Summary:"
    echo "==============="

    if [[ ${#customized_ref[@]} -gt 0 ]]; then
        echo "Customized files (will be preserved):"
        for file in "${customized_ref[@]}"; do
            echo "  - $(basename "$file")"
        done
        echo ""
    fi

    if [[ ${#changed_ref[@]} -gt 0 ]]; then
        echo "Changed files (will be updated):"
        for entry in "${changed_ref[@]}"; do
            local installed_file="${entry%:*}"
            local upstream_file="${entry#*:}"
            echo "  - $(basename "$installed_file")"

            if [[ "$show_diffs" == "true" ]]; then
                echo "    Diff preview:"
                diff -u "$installed_file" "$upstream_file" 2>/dev/null | head -10 | sed 's/^/      /' || true
                echo ""
            fi
        done
        echo ""
    fi

    if [[ ${#new_ref[@]} -gt 0 ]]; then
        echo "New files (will be added):"
        for file in "${new_ref[@]}"; do
            echo "  - $(basename "$file")"
        done
        echo ""
    fi

    local total_changes=$((${#changed_ref[@]} + ${#new_ref[@]}))
    echo "Total changes: ${total_changes} files"
    echo "Customized files preserved: ${#customized_ref[@]}"
}

# Backup customized files
backup_customizations() {
    local adapter_name="$1"
    shift
    local customized_files=("$@")

    if [[ ${#customized_files[@]} -eq 0 ]]; then
        return 0
    fi

    local backup_base_dir="${PROJECT_ROOT:-$(pwd)}/.living-docs-backups"
    local backup_dir="$backup_base_dir/$adapter_name/$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$backup_dir"

    echo "Backing up customized files..."

    for file in "${customized_files[@]}"; do
        local backup_file="$backup_dir/$(basename "$file")"
        if cp "$file" "$backup_file"; then
            echo "   Backed up: $(basename "$file")"
        else
            echo "   Failed to backup: $(basename "$file")" >&2
        fi
    done

    echo "${backup_dir}"
}

# Merge changes while preserving customizations
merge_changes() {
    local adapter_name="$1"
    local upstream_dir="$2"
    local -n customized_ref=$3
    local -n changed_ref=$4
    local -n new_ref=$5

    echo "Merging changes..."

    local errors=0

    # Update changed files (skip customized ones)
    for entry in "${changed_ref[@]}"; do
        local installed_file="${entry%:*}"
        local upstream_file="${entry#*:}"

        # Skip if file is customized
        local is_customized=false
        for custom_file in "${customized_ref[@]}"; do
            if [[ "$installed_file" == "$custom_file" ]]; then
                is_customized=true
                break
            fi
        done

        if [[ "$is_customized" == "true" ]]; then
            echo "  - Skipped (customized): $(basename "$installed_file")"
            continue
        fi

        # Update the file
        if cp "$upstream_file" "$installed_file"; then
            # Update checksum in manifest
            local new_checksum
            new_checksum=$(calculate_checksum "$installed_file")
            update_manifest "$adapter_name" "$installed_file" "$new_checksum" "" ""

            echo "   Updated: $(basename "$installed_file")"
        else
            echo "   Failed to update: $(basename "$installed_file")" >&2
            ((errors++))
        fi
    done

    # Install new files
    for upstream_file in "${new_ref[@]}"; do
        local installed_file
        installed_file=$(find_installed_file "$upstream_file" "$upstream_dir")

        # Create directory if needed
        local install_dir
        install_dir=$(dirname "$installed_file")
        mkdir -p "$install_dir"

        if cp "$upstream_file" "$installed_file"; then
            # Add to manifest
            local checksum
            checksum=$(calculate_checksum "$installed_file")
            local file_type="script"

            # Determine file type
            case "$(dirname "${upstream_file#$upstream_dir/}")" in
                commands) file_type="command" ;;
                templates) file_type="template" ;;
                scripts) file_type="script" ;;
            esac

            update_manifest "$adapter_name" "$installed_file" "$checksum" "" "$file_type"

            echo "   Added: $(basename "$installed_file")"
        else
            echo "   Failed to add: $(basename "$installed_file")" >&2
            ((errors++))
        fi
    done

    # Show summary for customized files
    if [[ ${#customized_ref[@]} -gt 0 ]]; then
        echo ""
        echo "Customized files preserved (manual merge may be needed):"
        for file in "${customized_ref[@]}"; do
            echo "  - $(basename "$file")"

            # Mark as customized in manifest if not already marked
            if ! is_file_customized "$adapter_name" "$file"; then
                local original_checksum
                original_checksum=$(get_file_checksum "$adapter_name" "$file")
                mark_customized "$adapter_name" "$file" "$original_checksum"
            fi
        done
    fi

    return $errors
}

# Update manifest version
update_manifest_version() {
    local adapter_name="$1"
    local new_version="$2"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found" >&2
        return 1
    fi

    # Update version using simple sed replacement
    local temp_file
    temp_file=$(mktemp)

    sed 's/"version"[[:space:]]*:[[:space:]]*"[^"]*"/"version": "'"$new_version"'"/' "$manifest_path" > "$temp_file"

    if mv "$temp_file" "$manifest_path"; then
        echo "Updated manifest version to: ${new_version}"
        return 0
    else
        echo "Error: Failed to update manifest version" >&2
        rm -f "$temp_file"
        return 1
    fi
}

# Check for available updates
check_updates() {
    local adapter_name="$1"
    local source_dir="$2"

    if [[ -z "${adapter_name}" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Adapter ${adapter_name} is not installed"
        return 1
    fi

    local current_version
    current_version=$(read_manifest "$adapter_name" "version")

    # Try to get upstream version
    local upstream_dir
    if upstream_dir=$(fetch_upstream "$adapter_name" "$source_dir" 2>/dev/null); then
        local upstream_version
        upstream_version=$(get_adapter_version "$upstream_dir")

        echo "Adapter: ${adapter_name}"
        echo "Current: ${current_version}"
        echo "Available: ${upstream_version}"

        if [[ "$current_version" != "$upstream_version" ]]; then
            echo "Status: Update available"
            rm -rf "$upstream_dir"
            return 0
        else
            echo "Status: Up to date"
            rm -rf "$upstream_dir"
            return 1
        fi
    else
        echo "Adapter: ${adapter_name}"
        echo "Current: ${current_version}"
        echo "Status: Cannot check (upstream not available)"
        return 2
    fi
}

# Export functions for use by other scripts
export -f update_adapter
export -f fetch_upstream
export -f compare_checksums
export -f find_upstream_file
export -f find_installed_file
export -f show_update_summary
export -f backup_customizations
export -f merge_changes
export -f update_manifest_version
export -f check_updates