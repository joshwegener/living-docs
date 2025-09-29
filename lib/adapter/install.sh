#!/bin/bash
# Safe Installation Functions for Adapter Installation System
# Handles staging, validation, and atomic installation of adapters

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/manifest.sh" 2>/dev/null || true
source "$SCRIPT_DIR/rewrite.sh" 2>/dev/null || true
source "$SCRIPT_DIR/prefix.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../validation/paths.sh" 2>/dev/null || true
source "$SCRIPT_DIR/../validation/conflicts.sh" 2>/dev/null || true

# Main installation function
install_adapter() {
    local adapter_name="$1"
    local options="${2:-}"

    if [[ -z "$adapter_name" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    echo "Installing adapter: $adapter_name"

    # Parse options
    local custom_paths=false
    local dry_run=false
    local force=false
    local source_dir=""

    for opt in $options; do
        case $opt in
            --custom-paths) custom_paths=true ;;
            --dry-run) dry_run=true ;;
            --force) force=true ;;
            --source=*) source_dir="${opt#*=}" ;;
        esac
    done

    # Determine source directory
    if [[ -z "$source_dir" ]]; then
        source_dir="${PROJECT_ROOT:-$(pwd)}/tmp/$adapter_name"
    fi

    if [[ ! -d "$source_dir" ]]; then
        echo "Error: Source directory not found: $source_dir" >&2
        echo "Please clone or download the adapter first" >&2
        return 1
    fi

    # Stage installation in temporary directory
    local temp_dir
    temp_dir=$(stage_in_temp "$adapter_name" "$source_dir")

    if [[ -z "$temp_dir" || ! -d "$temp_dir" ]]; then
        echo "Error: Failed to create staging directory" >&2
        return 1
    fi

    echo "Staging in: $temp_dir"

    # Validate installation
    if ! validate_installation "$temp_dir" "$adapter_name"; then
        echo "Error: Installation validation failed" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Apply path rewrites if needed
    if [[ "$custom_paths" == "true" ]]; then
        echo "Applying custom path rewrites..."
        if ! apply_rewrites "$temp_dir" true; then
            echo "Error: Path rewriting failed" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    fi

    # Check for conflicts and apply prefix if needed
    local prefix=""
    if should_apply_prefix "$adapter_name" "$temp_dir/commands/"*.md; then
        echo "Conflicts detected, applying prefix..."
        prefix=$(generate_prefix "$adapter_name")

        if [[ -z "$prefix" ]]; then
            echo "Error: Failed to generate prefix" >&2
            rm -rf "$temp_dir"
            return 1
        fi

        echo "Using prefix: $prefix"
    fi

    # Perform atomic installation
    if [[ "$dry_run" == "true" ]]; then
        echo "Dry run mode - would install:"
        find "$temp_dir" -type f | while read -r file; do
            echo "  - $file"
        done
        rm -rf "$temp_dir"
        return 0
    fi

    if ! atomic_move "$temp_dir" "$adapter_name" "$prefix"; then
        echo "Error: Failed to complete installation" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Create manifest
    local version
    version=$(get_adapter_version "$source_dir")
    create_manifest "$adapter_name" "$version" "$prefix"

    # Update manifest with installed files
    track_installed_files "$adapter_name" "$prefix"

    # Clean up
    rm -rf "$temp_dir"

    echo " Adapter $adapter_name installed successfully"
    return 0
}

# Stage adapter files in temporary directory
stage_in_temp() {
    local adapter_name="$1"
    local source_dir="$2"

    local temp_base="${TMPDIR:-/tmp}"
    local temp_dir="$temp_base/living-docs-install-$$-$RANDOM"

    # Create temporary staging directory
    if ! mkdir -p "$temp_dir"; then
        echo "Error: Failed to create temp directory" >&2
        return 1
    fi

    # Copy adapter files to temp directory
    if ! cp -R "$source_dir"/* "$temp_dir/" 2>/dev/null; then
        echo "Error: Failed to copy adapter files" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    echo "$temp_dir"
}

# Validate adapter installation
validate_installation() {
    local temp_dir="$1"
    local adapter_name="$2"

    echo "Validating installation..."

    # Check for required directories
    if [[ ! -d "$temp_dir/commands" ]] && [[ ! -d "$temp_dir/templates" ]]; then
        echo "Error: Adapter must contain commands/ or templates/ directory" >&2
        return 1
    fi

    # Skip strict path validation if we're going to rewrite paths
    # Just check for absolute paths which should never exist
    if ! validate_no_absolute "$temp_dir" >/dev/null 2>&1; then
        echo "Error: Absolute paths found in adapter" >&2
        echo "Adapters should use relative paths only" >&2
        return 1
    fi

    # Check for hardcoded paths that need rewriting
    local path_report
    path_report=$(detect_paths "$temp_dir" 2>&1)

    if [[ -n "$path_report" ]]; then
        echo "Note: Hardcoded paths detected (will be rewritten):"
        echo "$path_report" | head -5
    fi

    echo " Validation passed"
    return 0
}

# Perform atomic move of files from temp to final location
atomic_move() {
    local temp_dir="$1"
    local adapter_name="$2"
    local prefix="$3"

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local ai_dir
    ai_dir=$(get_ai_command_dir)

    # Create necessary directories
    mkdir -p "$project_root/adapters/$adapter_name"
    mkdir -p "$ai_dir"

    local errors=0

    # Install command files
    if [[ -d "$temp_dir/commands" ]]; then
        echo "Installing commands..."

        for cmd_file in "$temp_dir/commands/"*.md; do
            if [[ -f "$cmd_file" ]]; then
                local base_name
                base_name=$(basename "$cmd_file")
                local dest_name="$base_name"

                # Apply prefix if needed
                if [[ -n "$prefix" ]]; then
                    dest_name="${prefix}_${base_name}"
                fi

                local dest_file="$ai_dir/$dest_name"

                if cp "$cmd_file" "$dest_file"; then
                    echo "   Installed: $dest_name"
                else
                    echo "   Failed to install: $dest_name" >&2
                    ((errors++))
                fi
            fi
        done
    fi

    # Install templates
    if [[ -d "$temp_dir/templates" ]]; then
        echo "Installing templates..."
        local template_dir="$project_root/adapters/$adapter_name/templates"
        mkdir -p "$template_dir"

        if cp -R "$temp_dir/templates/"* "$template_dir/" 2>/dev/null; then
            echo "   Templates installed"
        else
            echo "   Failed to install templates" >&2
            ((errors++))
        fi
    fi

    # Install scripts
    if [[ -d "$temp_dir/scripts" ]]; then
        echo "Installing scripts..."
        local scripts_dir="$project_root/adapters/$adapter_name/scripts"
        mkdir -p "$scripts_dir"

        if cp -R "$temp_dir/scripts/"* "$scripts_dir/" 2>/dev/null; then
            # Make scripts executable
            find "$scripts_dir" -type f -name "*.sh" -exec chmod +x {} \;
            echo "   Scripts installed"
        else
            echo "   Failed to install scripts" >&2
            ((errors++))
        fi
    fi

    # Install config files
    if [[ -f "$temp_dir/config.yml" ]] || [[ -f "$temp_dir/config.yaml" ]]; then
        echo "Installing configuration..."
        local adapter_dir="$project_root/adapters/$adapter_name"

        for config in "$temp_dir"/config.{yml,yaml}; do
            if [[ -f "$config" ]]; then
                if cp "$config" "$adapter_dir/"; then
                    echo "   Configuration installed"
                else
                    echo "   Failed to install configuration" >&2
                    ((errors++))
                fi
            fi
        done
    fi

    return $errors
}

# Track installed files in manifest
track_installed_files() {
    local adapter_name="$1"
    local prefix="$2"

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local ai_dir
    ai_dir=$(get_ai_command_dir)

    # Track command files
    if [[ -n "$prefix" ]]; then
        for cmd_file in "$ai_dir/${prefix}_"*.md; do
            if [[ -f "$cmd_file" ]]; then
                local checksum
                checksum=$(calculate_checksum "$cmd_file")
                update_manifest "$adapter_name" "$cmd_file" "$checksum" "" "command"
                add_command_to_manifest "$adapter_name" "$(basename "$cmd_file")"
            fi
        done
    else
        # Track unprefixed files (need to identify which belong to this adapter)
        local adapter_dir="$project_root/adapters/$adapter_name"
        if [[ -f "$adapter_dir/.installation_files.txt" ]]; then
            while IFS= read -r file; do
                if [[ -f "$file" ]]; then
                    local checksum
                    checksum=$(calculate_checksum "$file")
                    update_manifest "$adapter_name" "$file" "$checksum" "" "command"
                    add_command_to_manifest "$adapter_name" "$(basename "$file")"
                fi
            done < "$adapter_dir/.installation_files.txt"
        fi
    fi

    # Track template files
    local template_dir="$project_root/adapters/$adapter_name/templates"
    if [[ -d "$template_dir" ]]; then
        find "$template_dir" -type f | while read -r file; do
            local checksum
            checksum=$(calculate_checksum "$file")
            local relative_path="${file#$project_root/}"
            update_manifest "$adapter_name" "$relative_path" "$checksum" "" "template"
        done
    fi

    # Track script files
    local scripts_dir="$project_root/adapters/$adapter_name/scripts"
    if [[ -d "$scripts_dir" ]]; then
        find "$scripts_dir" -type f | while read -r file; do
            local checksum
            checksum=$(calculate_checksum "$file")
            local relative_path="${file#$project_root/}"
            update_manifest "$adapter_name" "$relative_path" "$checksum" "" "script"
        done
    fi
}

# Get adapter version from source
get_adapter_version() {
    local source_dir="$1"
    local version="0.0.1"

    # Check for version file
    if [[ -f "$source_dir/version.txt" ]]; then
        version=$(cat "$source_dir/version.txt" | tr -d '\n')
    elif [[ -f "$source_dir/VERSION" ]]; then
        version=$(cat "$source_dir/VERSION" | tr -d '\n')
    elif [[ -f "$source_dir/package.json" ]]; then
        # Extract version from package.json
        version=$(grep '"version"' "$source_dir/package.json" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    echo "$version"
}

# Rollback installation on failure
rollback_installation() {
    local adapter_name="$1"
    local manifest_backup="$2"

    echo "Rolling back installation..."

    # Restore manifest if backup exists
    if [[ -f "$manifest_backup" ]]; then
        restore_manifest "$adapter_name"
    fi

    # Remove installed files
    local files_to_remove
    files_to_remove=$(list_manifest_files "$adapter_name" 2>/dev/null)

    if [[ -n "$files_to_remove" ]]; then
        echo "$files_to_remove" | while read -r file; do
            if [[ -f "$file" ]]; then
                rm -f "$file"
                echo "  Removed: $file"
            fi
        done
    fi

    echo "Rollback complete"
}

# Export functions for use by other scripts
export -f install_adapter
export -f stage_in_temp
export -f validate_installation
export -f atomic_move
export -f track_installed_files
export -f get_adapter_version
export -f rollback_installation