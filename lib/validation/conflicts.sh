#!/bin/bash
# Conflict Detection Functions for Adapter Installation System
# Handles detection and resolution of file conflicts across AI directories

# AI directory mappings (compatible with bash 3.2+)
get_ai_directory() {
    local ai_type="$1"
    case "$ai_type" in
        claude) echo ".claude" ;;
        cursor) echo ".cursor" ;;
        aider) echo ".aider" ;;
        copilot) echo ".github/copilot" ;;
        continue) echo ".continue" ;;
        agent-os) echo ".agent-os" ;;
        *) return 1 ;;
    esac
}

get_ai_command_subdir() {
    local ai_type="$1"
    case "$ai_type" in
        claude|cursor|aider|copilot|continue|agent-os) echo "commands" ;;
        *) return 1 ;;
    esac
}

# Scan existing AI directories for files
scan_existing() {
    local target_dir="${1:-.}"
    local report_file="${2:-/dev/stdout}"
    local found_files=0

    {
        echo "AI Directory Scan Report"
        echo "======================="
        echo "Target Directory: $target_dir"
        echo "Date: $(date)"
        echo ""
        echo "AI Directories Found:"
    } > "$report_file"

    # Check each AI directory type
    for ai_type in claude cursor aider copilot continue agent-os; do
        local ai_dir="$target_dir/$(get_ai_directory "$ai_type")"
        local cmd_subdir="$(get_ai_command_subdir "$ai_type")"
        local cmd_dir="$ai_dir/$cmd_subdir"

        if [[ -d "$ai_dir" ]]; then
            echo "  $ai_type ($ai_dir):" >> "$report_file"

            # Count total files in AI directory
            local total_files
            total_files=$(find "$ai_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "    Total files: $total_files" >> "$report_file"

            # Check command directory specifically
            if [[ -d "$cmd_dir" ]]; then
                local cmd_files
                cmd_files=$(find "$cmd_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
                echo "    Command files (.md): $cmd_files" >> "$report_file"

                if [[ $cmd_files -gt 0 ]]; then
                    echo "    Command file list:" >> "$report_file"
                    find "$cmd_dir" -name "*.md" 2>/dev/null | while read -r file; do
                        echo "      - $(basename "$file")" >> "$report_file"
                    done
                fi
                ((found_files += cmd_files))
            else
                echo "    Commands directory: not found" >> "$report_file"
            fi
            echo "" >> "$report_file"
        fi
    done

    {
        echo "Summary:"
        echo "  Total command files found: $found_files"
    } >> "$report_file"

    return $found_files
}

# Detect conflicts between new files and existing AI directories
detect_conflicts() {
    local new_files=("$@")
    local target_dir="${TARGET_DIR:-.}"
    local conflicts=()
    local conflict_details=()

    if [[ ${#new_files[@]} -eq 0 ]]; then
        return 0
    fi

    # Check each new file against all AI directories
    for new_file in "${new_files[@]}"; do
        local base_name
        base_name=$(basename "$new_file")

        # Check each AI directory type
        for ai_type in claude cursor aider copilot continue agent-os; do
            local ai_dir="$target_dir/$(get_ai_directory "$ai_type")"
            local cmd_subdir="$(get_ai_command_subdir "$ai_type")"
            local cmd_dir="$ai_dir/$cmd_subdir"
            local existing_file="$cmd_dir/$base_name"

            if [[ -f "$existing_file" ]]; then
                conflicts+=("$existing_file")
                conflict_details+=("$base_name:$ai_type:$existing_file")
            fi
        done
    done

    # Output conflicts to stdout for capture
    printf "%s\n" "${conflicts[@]}"

    # Return number of conflicts
    return ${#conflicts[@]}
}

# Suggest resolution strategies for conflicts
suggest_resolution() {
    local conflicts=("$@")
    local report_file="${CONFLICT_REPORT_FILE:-/dev/stdout}"

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        {
            echo "Conflict Resolution Report"
            echo "========================="
            echo "Date: $(date)"
            echo ""
            echo "No conflicts detected."
        } > "$report_file"
        return 0
    fi

    {
        echo "Conflict Resolution Report"
        echo "========================="
        echo "Date: $(date)"
        echo ""
        echo "Conflicts Detected: ${#conflicts[@]}"
        echo ""
        echo "Conflicting Files:"
        printf "  - %s\n" "${conflicts[@]}"
        echo ""
        echo "Resolution Strategies:"
        echo ""
        echo "1. Use Prefixing (Recommended)"
        echo "   - Automatically prefix adapter commands to avoid conflicts"
        echo "   - Example: plan.md becomes adapter_plan.md"
        echo "   - Run: LIVING_DOCS_USE_PREFIX=true ./install-adapter.sh"
        echo ""
        echo "2. Backup and Replace"
        echo "   - Backup existing files before installation"
        echo "   - Original files moved to .backup/ directory"
        echo "   - Risk: May override customizations"
        echo ""
        echo "3. Manual Resolution"
        echo "   - Review each conflict individually"
        echo "   - Merge content manually if needed"
        echo "   - Rename existing files before installation"
        echo ""
        echo "4. Skip Installation"
        echo "   - Abort installation to preserve existing files"
        echo "   - Use: LIVING_DOCS_NO_INSTALL=true"
        echo ""
        echo "Conflict Details:"
    } > "$report_file"

    # Analyze each conflict in detail
    local file_types=()
    local ai_types=()

    for conflict in "${conflicts[@]}"; do
        local base_name
        base_name=$(basename "$conflict")
        local ai_type

        # Determine AI type from path
        if [[ "$conflict" =~ \.claude/ ]]; then
            ai_type="claude"
        elif [[ "$conflict" =~ \.cursor/ ]]; then
            ai_type="cursor"
        elif [[ "$conflict" =~ \.aider/ ]]; then
            ai_type="aider"
        elif [[ "$conflict" =~ \.github/copilot/ ]]; then
            ai_type="copilot"
        elif [[ "$conflict" =~ \.continue/ ]]; then
            ai_type="continue"
        else
            ai_type="unknown"
        fi

        echo "  $base_name (found in $ai_type directory)" >> "$report_file"

        # Check file size and modification date
        if [[ -f "$conflict" ]]; then
            local size
            local mtime
            size=$(stat -f%z "$conflict" 2>/dev/null || stat -c%s "$conflict" 2>/dev/null || echo "unknown")
            mtime=$(stat -f%m "$conflict" 2>/dev/null || stat -c%Y "$conflict" 2>/dev/null || echo "unknown")
            if [[ "$mtime" != "unknown" ]]; then
                mtime=$(date -r "$mtime" 2>/dev/null || echo "unknown")
            fi
            echo "    Size: $size bytes, Modified: $mtime" >> "$report_file"
        fi

        # Track for summary
        if [[ ! " ${file_types[*]} " =~ " ${base_name} " ]]; then
            file_types+=("$base_name")
        fi
        if [[ ! " ${ai_types[*]} " =~ " ${ai_type} " ]]; then
            ai_types+=("$ai_type")
        fi
    done

    {
        echo ""
        echo "Summary:"
        echo "  Unique files in conflict: ${#file_types[@]}"
        echo "  AI directories affected: ${#ai_types[@]} ($(IFS=', '; echo "${ai_types[*]}"))"
        echo ""
        echo "Recommended Action:"
        if [[ ${#conflicts[@]} -le 3 ]]; then
            echo "  Few conflicts detected - consider manual resolution or prefixing"
        elif [[ ${#ai_types[@]} -eq 1 ]]; then
            echo "  Single AI system affected - prefixing recommended"
        else
            echo "  Multiple AI systems affected - prefixing strongly recommended"
        fi
    } >> "$report_file"

    return ${#conflicts[@]}
}

# Check conflicts for a specific adapter installation
check_adapter_conflicts() {
    local adapter_name="$1"
    local adapter_files=("${@:2}")
    local report_file="${2:-/tmp/adapter_conflicts.txt}"

    if [[ -z "$adapter_name" ]]; then
        echo "Error: Adapter name required" >&2
        return 1
    fi

    {
        echo "Adapter Conflict Check: $adapter_name"
        echo "=================================="
        echo "Date: $(date)"
        echo ""
        echo "Files to install: ${#adapter_files[@]}"
        printf "  - %s\n" "${adapter_files[@]}"
        echo ""
    } > "$report_file"

    # Scan existing environment
    echo "Scanning existing AI directories..." >> "$report_file"
    scan_existing "." "/tmp/scan_results.txt"
    cat "/tmp/scan_results.txt" >> "$report_file"
    echo "" >> "$report_file"

    # Detect conflicts
    echo "Checking for conflicts..." >> "$report_file"
    local conflicts
    conflicts=$(detect_conflicts "${adapter_files[@]}")
    local conflict_count=$?

    if [[ $conflict_count -eq 0 ]]; then
        echo "No conflicts detected - installation can proceed safely." >> "$report_file"
    else
        echo "Conflicts detected!" >> "$report_file"
        echo "" >> "$report_file"

        # Generate resolution suggestions
        CONFLICT_REPORT_FILE="/tmp/resolution.txt" suggest_resolution $conflicts
        cat "/tmp/resolution.txt" >> "$report_file"
    fi

    # Clean up temp files
    rm -f "/tmp/scan_results.txt" "/tmp/resolution.txt"

    echo "$report_file"
    return $conflict_count
}

# Generate comprehensive conflict report
generate_conflict_report() {
    local target_dir="${1:-.}"
    local new_files=("${@:2}")
    local report_file="${CONFLICT_REPORT_FILE:-/tmp/comprehensive_conflicts.txt}"

    {
        echo "Comprehensive Conflict Analysis"
        echo "=============================="
        echo "Target Directory: $target_dir"
        echo "Date: $(date)"
        echo ""
    } > "$report_file"

    # First, scan existing environment
    echo "=== EXISTING ENVIRONMENT SCAN ===" >> "$report_file"
    scan_existing "$target_dir" "/tmp/env_scan.txt"
    cat "/tmp/env_scan.txt" >> "$report_file"
    echo "" >> "$report_file"

    # If new files provided, check for conflicts
    if [[ ${#new_files[@]} -gt 0 ]]; then
        echo "=== CONFLICT DETECTION ===" >> "$report_file"
        echo "New files to check: ${#new_files[@]}" >> "$report_file"
        printf "  - %s\n" "${new_files[@]}" >> "$report_file"
        echo "" >> "$report_file"

        TARGET_DIR="$target_dir" conflicts=$(detect_conflicts "${new_files[@]}")
        local conflict_count=$?

        if [[ $conflict_count -gt 0 ]]; then
            echo "Conflicts found: $conflict_count" >> "$report_file"
            echo "" >> "$report_file"

            echo "=== RESOLUTION SUGGESTIONS ===" >> "$report_file"
            CONFLICT_REPORT_FILE="/tmp/resolution_temp.txt" suggest_resolution $conflicts
            cat "/tmp/resolution_temp.txt" >> "$report_file"
            rm -f "/tmp/resolution_temp.txt"
        else
            echo "No conflicts detected." >> "$report_file"
        fi
    fi

    # Clean up
    rm -f "/tmp/env_scan.txt"

    echo "$report_file"
}

# Quick conflict check (returns 0 for no conflicts, 1 for conflicts found)
quick_conflict_check() {
    local new_files=("$@")

    if [[ ${#new_files[@]} -eq 0 ]]; then
        return 0
    fi

    local conflicts
    conflicts=$(detect_conflicts "${new_files[@]}" 2>/dev/null)
    local conflict_count=$?

    return $conflict_count
}

# Backup conflicting files before installation
backup_conflicting_files() {
    local conflicts=("$@")
    local backup_dir="${BACKUP_DIR:-.backup}"
    local backup_timestamp
    backup_timestamp=$(date +"%Y%m%d_%H%M%S")
    local full_backup_dir="$backup_dir/$backup_timestamp"

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        echo "No files to backup."
        return 0
    fi

    echo "Creating backup directory: $full_backup_dir"
    mkdir -p "$full_backup_dir"

    local backed_up=0
    local errors=0

    for conflict in "${conflicts[@]}"; do
        if [[ -f "$conflict" ]]; then
            local relative_path
            relative_path=$(dirname "$conflict")
            local backup_target_dir="$full_backup_dir/$relative_path"

            mkdir -p "$backup_target_dir"

            if cp "$conflict" "$backup_target_dir/"; then
                echo "Backed up: $conflict"
                ((backed_up++))
            else
                echo "Error backing up: $conflict" >&2
                ((errors++))
            fi
        fi
    done

    echo "Backup complete: $backed_up files backed up, $errors errors"
    echo "Backup location: $full_backup_dir"

    return $errors
}

# Restore files from backup
restore_from_backup() {
    local backup_dir="$1"
    local dry_run="${2:-false}"

    if [[ ! -d "$backup_dir" ]]; then
        echo "Error: Backup directory not found: $backup_dir" >&2
        return 1
    fi

    echo "Restoring files from: $backup_dir"

    local restored=0
    local errors=0

    while IFS= read -r backup_file; do
        # Calculate original path (remove backup prefix)
        local original_path
        original_path=$(echo "$backup_file" | sed "s|^$backup_dir/||")

        if [[ "$dry_run" == "true" ]]; then
            echo "Would restore: $backup_file -> $original_path"
        else
            local target_dir
            target_dir=$(dirname "$original_path")
            mkdir -p "$target_dir"

            if cp "$backup_file" "$original_path"; then
                echo "Restored: $original_path"
                ((restored++))
            else
                echo "Error restoring: $backup_file -> $original_path" >&2
                ((errors++))
            fi
        fi
    done < <(find "$backup_dir" -type f)

    if [[ "$dry_run" != "true" ]]; then
        echo "Restore complete: $restored files restored, $errors errors"
    fi

    return $errors
}

# Export functions for use by other scripts
export -f scan_existing
export -f detect_conflicts
export -f suggest_resolution
export -f check_adapter_conflicts
export -f generate_conflict_report
export -f quick_conflict_check
export -f backup_conflicting_files
export -f restore_from_backup