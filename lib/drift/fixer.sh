#!/usr/bin/env bash
# Drift fixer module - auto-fix drift issues
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/paths.sh" 2>/dev/null || true

# Fix single drift item
fix_drift_item() {
    local drift="$1"
    local restore_from_git="${2:-false}"
    local dry_run="${3:-false}"

    local drift_type="${drift%%:*}"
    local file="${drift#*:}"

    case "$drift_type" in
        MODIFIED)
            if [[ "$restore_from_git" == true ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY RUN] Would restore: $file"
                else
                    log_info "Restoring from git: $file"
                    git checkout -- "$file" 2>/dev/null || {
                        log_error "Failed to restore $file from git"
                        return 1
                    }
                fi
            else
                log_warning "Modified file needs manual review: $file"
                return 1
            fi
            ;;
        ADDED)
            if [[ "$dry_run" == true ]]; then
                log_info "[DRY RUN] Would remove: $file"
            else
                log_info "Removing untracked file: $file"
                rm -f "$file"
            fi
            ;;
        DELETED)
            if [[ "$restore_from_git" == true ]]; then
                if [[ "$dry_run" == true ]]; then
                    log_info "[DRY RUN] Would restore deleted: $file"
                else
                    log_info "Restoring deleted file: $file"
                    git checkout -- "$file" 2>/dev/null || {
                        log_error "Failed to restore deleted file $file"
                        return 1
                    }
                fi
            else
                log_warning "Deleted file needs manual restoration: $file"
                return 1
            fi
            ;;
        *)
            log_error "Unknown drift type: $drift_type"
            return 1
            ;;
    esac

    return 0
}

# Fix all drifts
fix_all_drifts() {
    local drift_list=("$@")
    local restore_from_git="${FIX_RESTORE_FROM_GIT:-false}"
    local dry_run="${FIX_DRY_RUN:-false}"
    local fixed_count=0
    local failed_count=0

    log_info "Attempting to fix ${#drift_list[@]} drifts..."

    for drift in "${drift_list[@]}"; do
        if fix_drift_item "$drift" "$restore_from_git" "$dry_run"; then
            ((fixed_count++))
        else
            ((failed_count++))
        fi
    done

    log_success "Fixed $fixed_count drifts"
    if [[ $failed_count -gt 0 ]]; then
        log_warning "Failed to fix $failed_count drifts"
        return 1
    fi

    return 0
}

# Interactive fix mode
interactive_fix() {
    local drift_list=("$@")

    for drift in "${drift_list[@]}"; do
        local drift_type="${drift%%:*}"
        local file="${drift#*:}"

        echo ""
        echo "Drift detected: $drift_type - $file"

        case "$drift_type" in
            MODIFIED)
                echo "Options:"
                echo "  1) View diff"
                echo "  2) Restore from git"
                echo "  3) Keep current version"
                echo "  4) Skip"
                ;;
            ADDED)
                echo "Options:"
                echo "  1) View file"
                echo "  2) Remove file"
                echo "  3) Keep file"
                echo "  4) Skip"
                ;;
            DELETED)
                echo "Options:"
                echo "  1) Restore from git"
                echo "  2) Accept deletion"
                echo "  3) Skip"
                ;;
        esac

        echo -n "Choice: "
        read -r choice

        case "$drift_type" in
            MODIFIED)
                case "$choice" in
                    1) git diff "$file" ;;
                    2) git checkout -- "$file" && echo "Restored from git" ;;
                    3) echo "Keeping current version" ;;
                    4) echo "Skipping..." ;;
                    *) echo "Invalid choice" ;;
                esac
                ;;
            ADDED)
                case "$choice" in
                    1) head -20 "$file" ;;
                    2) rm -f "$file" && echo "File removed" ;;
                    3) echo "Keeping file" ;;
                    4) echo "Skipping..." ;;
                    *) echo "Invalid choice" ;;
                esac
                ;;
            DELETED)
                case "$choice" in
                    1) git checkout -- "$file" && echo "File restored" ;;
                    2) echo "Accepting deletion" ;;
                    3) echo "Skipping..." ;;
                    *) echo "Invalid choice" ;;
                esac
                ;;
        esac
    done
}

# Generate fix script
generate_fix_script() {
    local drift_list=("$@")
    local script_content="#!/bin/bash"

    script_content+=$'\n'"# Auto-generated drift fix script"
    script_content+=$'\n'"# Generated: $(date)"
    script_content+=$'\n'"set -euo pipefail"
    script_content+=$'\n'

    for drift in "${drift_list[@]}"; do
        local drift_type="${drift%%:*}"
        local file="${drift#*:}"

        case "$drift_type" in
            MODIFIED)
                script_content+=$'\n'"# Restore modified file"
                script_content+=$'\n'"git checkout -- '$file'"
                ;;
            ADDED)
                script_content+=$'\n'"# Remove untracked file"
                script_content+=$'\n'"rm -f '$file'"
                ;;
            DELETED)
                script_content+=$'\n'"# Restore deleted file"
                script_content+=$'\n'"git checkout -- '$file'"
                ;;
        esac
    done

    script_content+=$'\n'$'\n'"echo 'Drift fixes applied'"

    echo "$script_content"
}

# Validate fixes before applying
validate_fixes() {
    local drift_list=("$@")
    local errors=()

    for drift in "${drift_list[@]}"; do
        local drift_type="${drift%%:*}"
        local file="${drift#*:}"

        case "$drift_type" in
            MODIFIED|DELETED)
                # Check if file exists in git
                if ! git ls-files --error-unmatch "$file" &>/dev/null; then
                    errors+=("Cannot restore $file - not in git")
                fi
                ;;
            ADDED)
                # Check if file exists
                if [[ ! -f "$file" ]]; then
                    errors+=("Cannot remove $file - file not found")
                fi
                ;;
        esac
    done

    if [[ ${#errors[@]} -gt 0 ]]; then
        for error in "${errors[@]}"; do
            log_error "$error"
        done
        return 1
    fi

    return 0
}

# Export functions
export -f fix_drift_item
export -f fix_all_drifts
export -f interactive_fix
export -f generate_fix_script
export -f validate_fixes