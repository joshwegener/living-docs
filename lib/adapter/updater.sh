#!/bin/bash
# adapter/updater.sh - Adapter update checking and application module
# Extracted from update.sh as part of DEBT-001 refactoring

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/paths.sh" 2>/dev/null || true

# Check for adapter updates
check_adapter_updates() {
    local adapter_name="${1:-}"

    if [[ -z "$adapter_name" ]]; then
        log_error "Adapter name required"
        return 1
    fi

    local manifest_file="${PROJECT_ROOT:-$(pwd)}/.living-docs-manifest.json"

    if [[ ! -f "$manifest_file" ]]; then
        log_warning "No manifest found for $adapter_name"
        return 1
    fi

    # Check version in manifest
    local current_version
    current_version=$(jq -r ".adapters[\"$adapter_name\"].version // empty" "$manifest_file" 2>/dev/null)

    if [[ -z "$current_version" ]]; then
        log_info "No version information for $adapter_name"
        return 1
    fi

    log_info "Current version: $current_version"

    # In real implementation, would check remote for latest version
    # For now, just return success
    return 0
}

# Compare two semantic versions
compare_versions() {
    local version1="${1:-0.0.0}"
    local version2="${2:-0.0.0}"

    # Remove 'v' prefix if present
    version1="${version1#v}"
    version2="${version2#v}"

    # Split versions into components
    IFS='.' read -r -a v1_parts <<< "$version1"
    IFS='.' read -r -a v2_parts <<< "$version2"

    # Compare major.minor.patch
    for i in 0 1 2; do
        local v1_part="${v1_parts[i]:-0}"
        local v2_part="${v2_parts[i]:-0}"

        if [[ "$v1_part" -lt "$v2_part" ]]; then
            return 1  # version1 < version2
        elif [[ "$v1_part" -gt "$v2_part" ]]; then
            return 2  # version1 > version2
        fi
    done

    return 0  # versions are equal
}

# Backup current adapter version
backup_adapter_version() {
    local adapter_name="${1:-}"
    local backup_dir="${2:-}"

    if [[ -z "$adapter_name" ]]; then
        log_error "Adapter name required"
        return 1
    fi

    if [[ -z "$backup_dir" ]]; then
        backup_dir="${PROJECT_ROOT:-$(pwd)}/.living-docs-backups/$adapter_name/$(date +%Y%m%d_%H%M%S)"
    fi

    mkdir -p "$backup_dir"

    local manifest_file="${PROJECT_ROOT:-$(pwd)}/.living-docs-manifest.json"

    if [[ -f "$manifest_file" ]]; then
        # Get list of files from manifest
        local files
        files=$(jq -r ".adapters[\"$adapter_name\"].files[]? // empty" "$manifest_file" 2>/dev/null)

        if [[ -n "$files" ]]; then
            while IFS= read -r file; do
                if [[ -f "$file" ]]; then
                    local backup_file="$backup_dir/$(basename "$file")"
                    cp "$file" "$backup_file" || log_warning "Failed to backup $file"
                fi
            done <<< "$files"
        fi
    fi

    log_info "Backup created at: $backup_dir"
    echo "$backup_dir"
    return 0
}

# Apply adapter update
apply_adapter_update() {
    local adapter_name="${1:-}"
    local update_source="${2:-}"

    if [[ -z "$adapter_name" ]]; then
        log_error "Adapter name required"
        return 1
    fi

    if [[ -z "$update_source" ]] || [[ ! -d "$update_source" ]]; then
        log_error "Valid update source directory required"
        return 1
    fi

    # First backup current version
    local backup_dir
    backup_dir=$(backup_adapter_version "$adapter_name")

    if [[ -z "$backup_dir" ]]; then
        log_error "Failed to create backup"
        return 1
    fi

    # Apply update files
    local success=true

    for file in "$update_source"/*; do
        if [[ -f "$file" ]]; then
            local dest="${PROJECT_ROOT:-$(pwd)}/$(basename "$file")"
            if ! cp "$file" "$dest"; then
                log_error "Failed to copy $(basename "$file")"
                success=false
                break
            fi
        fi
    done

    if [[ "$success" != "true" ]]; then
        log_error "Update failed, restoring from backup"
        restore_from_backup "$backup_dir"
        return 1
    fi

    log_success "Update applied successfully"
    return 0
}

# Restore from backup
restore_from_backup() {
    local backup_dir="${1:-}"

    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        log_error "Invalid backup directory"
        return 1
    fi

    for file in "$backup_dir"/*; do
        if [[ -f "$file" ]]; then
            local dest="${PROJECT_ROOT:-$(pwd)}/$(basename "$file")"
            cp "$file" "$dest" || log_warning "Failed to restore $(basename "$file")"
        fi
    done

    log_info "Restored from backup: $backup_dir"
    return 0
}

# Check all adapters for updates
check_all_adapter_updates() {
    local manifest_file="${PROJECT_ROOT:-$(pwd)}/.living-docs-manifest.json"

    if [[ ! -f "$manifest_file" ]]; then
        log_warning "No manifest found"
        return 1
    fi

    local adapters
    adapters=$(jq -r '.adapters | keys[]' "$manifest_file" 2>/dev/null)

    if [[ -z "$adapters" ]]; then
        log_info "No adapters installed"
        return 0
    fi

    local updates_available=false

    while IFS= read -r adapter; do
        log_info "Checking $adapter..."
        if check_adapter_updates "$adapter"; then
            updates_available=true
        fi
    done <<< "$adapters"

    if [[ "$updates_available" == "true" ]]; then
        log_info "Updates available"
        return 0
    else
        log_info "All adapters up to date"
        return 1
    fi
}

# Export functions
export -f check_adapter_updates
export -f compare_versions
export -f backup_adapter_version
export -f apply_adapter_update
export -f restore_from_backup
export -f check_all_adapter_updates