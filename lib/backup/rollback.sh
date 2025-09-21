#!/usr/bin/env bash
# Rollback mechanism for living-docs
# Provides snapshot creation, listing, and restoration functionality

set -euo pipefail

# Configuration
BACKUP_DIR="${LIVING_DOCS_BACKUP_DIR:-.living-docs.backup}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
BACKUP_MINIMUM_KEEP="${BACKUP_MINIMUM_KEEP:-3}"

# Create a backup snapshot
backup_create_snapshot() {
    local description="${1:-Manual backup}"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local snapshot_id="snapshot_${timestamp}"
    local snapshot_dir="${BACKUP_DIR}/${snapshot_id}"

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Create snapshot directory
    mkdir -p "$snapshot_dir"

    # Save metadata
    cat > "${snapshot_dir}/metadata.json" << EOF
{
    "snapshot_id": "${snapshot_id}",
    "timestamp": "${timestamp}",
    "description": "${description}",
    "created_at": "$(date -Iseconds)",
    "version": "${WIZARD_VERSION:-unknown}",
    "files_count": $(find . -type f ! -path "${BACKUP_DIR}/*" 2>/dev/null | wc -l | tr -d ' ')
}
EOF

    # Backup all files except the backup directory itself
    if [[ -d ".living-docs" ]]; then
        cp -r ".living-docs" "${snapshot_dir}/" 2>/dev/null || true
    fi

    # Backup main files and directories
    for item in wizard.sh docs adapters lib scripts templates specs tests .living-docs.config; do
        if [[ -e "$item" ]]; then
            cp -r "$item" "${snapshot_dir}/" 2>/dev/null || true
        fi
    done

    # Create a manifest of backed up files
    find "${snapshot_dir}" -type f ! -name "metadata.json" -exec basename {} \; | sort > "${snapshot_dir}/manifest.txt"

    echo "Backup created: ${snapshot_id}"
    echo "Description: ${description}"
    echo "Location: ${snapshot_dir}"

    return 0
}

# List available backup snapshots
backup_list_snapshots() {
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        echo "No backup snapshots found"
        return 0
    fi

    echo "Available backup snapshots:"
    echo ""

    # List all snapshots with metadata
    for snapshot_dir in "$BACKUP_DIR"/snapshot_*; do
        if [[ -d "$snapshot_dir" ]]; then
            local snapshot_id
            snapshot_id=$(basename "$snapshot_dir")

            if [[ -f "${snapshot_dir}/metadata.json" ]]; then
                # Parse metadata (basic parsing without jq dependency)
                local description timestamp
                description=$(grep '"description"' "${snapshot_dir}/metadata.json" | cut -d'"' -f4)
                timestamp=$(grep '"created_at"' "${snapshot_dir}/metadata.json" | cut -d'"' -f4)

                echo "  - ${snapshot_id}"
                echo "    Description: ${description}"
                echo "    Created: ${timestamp}"
            else
                echo "  - ${snapshot_id} (no metadata)"
            fi
        fi
    done

    return 0
}

# Rollback to a specific snapshot
backup_rollback_to_snapshot() {
    local snapshot_id="${1:-}"

    if [[ -z "$snapshot_id" ]]; then
        echo "ERROR: No snapshot ID provided" >&2
        return 1
    fi

    local snapshot_dir="${BACKUP_DIR}/${snapshot_id}"

    if [[ ! -d "$snapshot_dir" ]]; then
        echo "ERROR: Snapshot not found: ${snapshot_id}" >&2
        return 1
    fi

    # Create a pre-rollback backup for safety
    echo "Creating pre-rollback backup..."
    backup_create_snapshot "Pre-rollback backup" > /dev/null

    echo "Rolling back to: ${snapshot_id}"

    # Remove current files (except backup directory)
    for item in wizard.sh docs adapters lib scripts templates specs tests .living-docs .living-docs.config; do
        if [[ -e "$item" ]]; then
            rm -rf "$item"
        fi
    done

    # Restore files from snapshot
    for item in "${snapshot_dir}"/*; do
        if [[ -f "$item" ]] || [[ -d "$item" ]]; then
            local basename
            basename=$(basename "$item")

            # Skip metadata files
            if [[ "$basename" == "metadata.json" ]] || [[ "$basename" == "manifest.txt" ]]; then
                continue
            fi

            cp -r "$item" "./${basename}"
        fi
    done

    echo "Rollback complete: restored from ${snapshot_id}"
    return 0
}

# Clean up old backup snapshots
backup_cleanup_old_snapshots() {
    local retention_days="${1:-$BACKUP_RETENTION_DAYS}"
    local keep_minimum="${2:-$BACKUP_MINIMUM_KEEP}"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        return 0
    fi

    # Get list of snapshots sorted by age
    local snapshots=()
    while IFS= read -r snapshot_dir; do
        snapshots+=("$snapshot_dir")
    done < <(find "$BACKUP_DIR" -maxdepth 1 -type d -name "snapshot_*" | sort -r)

    local snapshot_count=${#snapshots[@]}

    # Always keep minimum number of snapshots
    if [[ $snapshot_count -le $keep_minimum ]]; then
        echo "Keeping all ${snapshot_count} snapshots (minimum: ${keep_minimum})"
        return 0
    fi

    # Find cutoff date
    local cutoff_date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        cutoff_date=$(date -v -${retention_days}d +%s)
    else
        # Linux date command
        cutoff_date=$(date -d "${retention_days} days ago" +%s)
    fi

    local removed_count=0
    local kept_count=0

    for ((i=0; i<${#snapshots[@]}; i++)); do
        local snapshot_dir="${snapshots[$i]}"

        # Always keep minimum number of most recent snapshots
        if [[ $i -lt $keep_minimum ]]; then
            ((kept_count++))
            continue
        fi

        # Check age of snapshot
        local snapshot_timestamp
        if [[ "$OSTYPE" == "darwin"* ]]; then
            snapshot_timestamp=$(stat -f %m "$snapshot_dir")
        else
            snapshot_timestamp=$(stat -c %Y "$snapshot_dir")
        fi

        if [[ $snapshot_timestamp -lt $cutoff_date ]]; then
            echo "Removing old snapshot: $(basename "$snapshot_dir")"
            rm -rf "$snapshot_dir"
            ((removed_count++))
        else
            ((kept_count++))
        fi
    done

    echo "Cleanup complete: removed ${removed_count}, kept ${kept_count} snapshots"
    return 0
}

# Restore specific files from a backup
backup_restore_files() {
    local snapshot_id="${1:-}"
    shift
    local files_to_restore=("$@")

    if [[ -z "$snapshot_id" ]]; then
        echo "ERROR: No snapshot ID provided" >&2
        return 1
    fi

    local snapshot_dir="${BACKUP_DIR}/${snapshot_id}"

    if [[ ! -d "$snapshot_dir" ]]; then
        echo "ERROR: Snapshot not found: ${snapshot_id}" >&2
        return 1
    fi

    if [[ ${#files_to_restore[@]} -eq 0 ]]; then
        echo "ERROR: No files specified for restoration" >&2
        return 1
    fi

    echo "Restoring files from: ${snapshot_id}"

    for file in "${files_to_restore[@]}"; do
        local source_file="${snapshot_dir}/${file}"

        if [[ -e "$source_file" ]]; then
            # Create parent directory if needed
            local parent_dir
            parent_dir=$(dirname "$file")
            if [[ "$parent_dir" != "." ]]; then
                mkdir -p "$parent_dir"
            fi

            # Restore the file
            cp -r "$source_file" "$file"
            echo "  Restored: $file"
        else
            echo "  WARNING: File not found in backup: $file" >&2
        fi
    done

    echo "File restoration complete"
    return 0
}

# Export functions for use by other scripts
export -f backup_create_snapshot
export -f backup_list_snapshots
export -f backup_rollback_to_snapshot
export -f backup_cleanup_old_snapshots
export -f backup_restore_files