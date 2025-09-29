#!/usr/bin/env bash
# living-docs drift detection system
# Main orchestrator using modular components
set -euo pipefail

# === CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
LIVING_DOCS_DIR="$PROJECT_ROOT/.living-docs"
CONFIG_FILE="$LIVING_DOCS_DIR/config.yml"
DEFAULT_BASELINE_FILE="$LIVING_DOCS_DIR/checksums.baseline"
DEFAULT_IGNORE_FILE="$LIVING_DOCS_DIR/drift-ignore"

# Global variables
VERBOSE=false
DRY_RUN=false
OUTPUT_FILE=""
FORMAT="human"
BASELINE_FILE="$DEFAULT_BASELINE_FILE"
IGNORE_PATTERNS=(".git/*" ".git/**/*" "*.tmp" "*.log")
AUTO_FIX=false
RESTORE_FROM_GIT=false
NO_GIT=false

# Exit codes
EXIT_SUCCESS=0
EXIT_DRIFT_DETECTED=1
EXIT_ERROR=2

# Source modular components
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/paths.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/scanner.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/analyzer.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/reporter.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/fixer.sh" 2>/dev/null || true

# Parse YAML config (simple parser for our needs)
parse_config() {
    [[ ! -f "$CONFIG_FILE" ]] && return 0

    verbose "Loading configuration from $CONFIG_FILE"

    # Basic YAML validation
    if grep -qE ":[[:space:]]*[a-zA-Z_-]+:[[:space:]]*[a-zA-Z_-]+:" "$CONFIG_FILE"; then
        echo "Invalid configuration format in $CONFIG_FILE" >&2
        return 1
    fi

    # Parse drift section
    local in_drift_section=false
    local in_ignore_section=false

    while IFS= read -r line_original; do
        case "$line_original" in
            "drift:")
                in_drift_section=true
                in_ignore_section=false
                ;;
            "  ignore:")
                [[ "$in_drift_section" == true ]] && in_ignore_section=true
                ;;
            "  baseline_path:"*)
                if [[ "$in_drift_section" == true ]]; then
                    local baseline_name="${line_original#*: }"
                    baseline_name="${baseline_name//\"}"
                    baseline_name="${baseline_name// }"
                    BASELINE_FILE="$LIVING_DOCS_DIR/$baseline_name"
                fi
                ;;
            "  auto_fix:"*)
                if [[ "$in_drift_section" == true ]]; then
                    [[ "${line_original#*: }" =~ true|True|TRUE ]] && AUTO_FIX=true
                fi
                ;;
            "    - "*)
                if [[ "$in_ignore_section" == true ]]; then
                    local pattern="${line_original#*- }"
                    pattern="${pattern//\"}"
                    IGNORE_PATTERNS+=("$pattern")
                fi
                ;;
            [a-zA-Z_-]*":")
                if [[ "$line_original" != "drift:" ]]; then
                    in_drift_section=false
                    in_ignore_section=false
                fi
                ;;
        esac
    done < "$CONFIG_FILE"

    return 0
}

# Check if path should be ignored
should_ignore() {
    local path="$1"

    for pattern in "${IGNORE_PATTERNS[@]}"; do
        case "$path" in
            $pattern) return 0 ;;
        esac
    done

    # Special handling for .git directory
    if [[ "$path" == .git/* ]] || [[ "$path" == */.git/* ]]; then
        return 0
    fi

    return 1
}

# Check git repository
check_git_repo() {
    if [[ "$NO_GIT" == true ]]; then
        return 1
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        verbose "Not in a git repository"
        return 1
    fi

    return 0
}

# Git integration functions
get_modified_files() {
    check_git_repo && git diff --name-only 2>/dev/null || true
}

get_added_files() {
    check_git_repo && git ls-files --others --exclude-standard 2>/dev/null || true
}

get_removed_files() {
    check_git_repo && git ls-files --deleted 2>/dev/null || true
}

# Check modified files using git
check_modified_files() {
    local modified_files
    modified_files=$(get_modified_files)

    if [[ -n "$modified_files" ]]; then
        echo "$modified_files" | while IFS= read -r file; do
            should_ignore "$file" || echo "MODIFIED:$file"
        done
    fi
}

# Check added files using git
check_added_files() {
    local added_files
    added_files=$(get_added_files)

    if [[ -n "$added_files" ]]; then
        echo "$added_files" | while IFS= read -r file; do
            should_ignore "$file" || echo "ADDED:$file"
        done
    fi
}

# Check removed files using git
check_removed_files() {
    local removed_files
    removed_files=$(get_removed_files)

    if [[ -n "$removed_files" ]]; then
        echo "$removed_files" | while IFS= read -r file; do
            should_ignore "$file" || echo "DELETED:$file"
        done
    fi
}

# Check all changes (git-based)
check_all_changes() {
    local changes=()

    # Modified files
    while IFS= read -r drift; do
        [[ -n "$drift" ]] && changes+=("$drift")
    done < <(check_modified_files)

    # Added files
    while IFS= read -r drift; do
        [[ -n "$drift" ]] && changes+=("$drift")
    done < <(check_added_files)

    # Removed files
    while IFS= read -r drift; do
        [[ -n "$drift" ]] && changes+=("$drift")
    done < <(check_removed_files)

    printf '%s\n' "${changes[@]}"
}

# Main drift detection
detect_drift() {
    local mode="${1:-all}"
    local drift_list=()

    case "$mode" in
        baseline)
            # Use baseline checksums
            if [[ ! -f "$BASELINE_FILE" ]]; then
                die "Baseline file not found: $BASELINE_FILE" "$E_FILE_NOT_FOUND"
            fi

            local drifts
            drifts=$(check_drift "$PROJECT_ROOT" "$BASELINE_FILE" "${IGNORE_PATTERNS[@]}")
            if [[ -n "$drifts" ]]; then
                while IFS= read -r drift; do
                    drift_list+=("$drift")
                done <<< "$drifts"
            fi
            ;;

        git|all)
            # Use git to detect changes
            if ! check_git_repo; then
                log_warning "Not in a git repository, falling back to baseline mode"
                if [[ -f "$BASELINE_FILE" ]]; then
                    detect_drift baseline
                    return $?
                else
                    die "No git repository and no baseline file found"
                fi
            fi

            while IFS= read -r drift; do
                [[ -n "$drift" ]] && drift_list+=("$drift")
            done < <(check_all_changes)
            ;;

        *)
            die "Unknown detection mode: $mode"
            ;;
    esac

    # Process results
    if [[ ${#drift_list[@]} -eq 0 ]]; then
        [[ "$FORMAT" != "json" ]] && log_success "No drift detected"
        return $EXIT_SUCCESS
    fi

    # Analyze drift
    if command -v analyze_drift_impact &>/dev/null; then
        analyze_drift_impact "${drift_list[@]}"
    fi

    # Generate report
    local report
    report=$(generate_report "$FORMAT" "${drift_list[@]}")

    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$report" > "$OUTPUT_FILE"
        log_info "Report saved to: $OUTPUT_FILE"
    else
        echo "$report"
    fi

    # Auto-fix if enabled
    if [[ "$AUTO_FIX" == true ]]; then
        log_info "Attempting auto-fix..."
        export FIX_DRY_RUN="$DRY_RUN"
        export FIX_RESTORE_FROM_GIT="$RESTORE_FROM_GIT"
        fix_all_drifts "${drift_list[@]}"
    fi

    return $EXIT_DRIFT_DETECTED
}

# Show usage
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMMAND]

Commands:
    check       Check for drift (default)
    baseline    Generate or update baseline
    fix         Fix detected drift
    report      Generate drift report

Options:
    -b FILE     Baseline file (default: $DEFAULT_BASELINE_FILE)
    -f FORMAT   Output format: human|json|markdown|csv (default: human)
    -o FILE     Output file (default: stdout)
    -i PATTERN  Add ignore pattern (can be used multiple times)
    -a          Auto-fix drift
    -g          Use git for restore operations
    -n          No git (baseline only)
    -d          Dry run (show what would be done)
    -v          Verbose output
    -h          Show this help

Examples:
    $(basename "$0")                    # Check for drift using git
    $(basename "$0") baseline           # Generate baseline
    $(basename "$0") check -f json      # Check drift, output JSON
    $(basename "$0") fix -g             # Fix drift using git
    $(basename "$0") report -f markdown # Generate markdown report

Exit codes:
    0 - No drift detected
    1 - Drift detected
    2 - Error occurred
EOF
}

# Parse command line arguments
parse_args() {
    local command=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            check|baseline|fix|report)
                command="$1"
                shift
                ;;
            -b|--baseline)
                BASELINE_FILE="${2:-$DEFAULT_BASELINE_FILE}"
                shift 2
                ;;
            -f|--format)
                FORMAT="${2:-human}"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="${2:-}"
                shift 2
                ;;
            -i|--ignore)
                IGNORE_PATTERNS+=("${2:-}")
                shift 2
                ;;
            -a|--auto-fix)
                AUTO_FIX=true
                shift
                ;;
            -g|--git-restore)
                RESTORE_FROM_GIT=true
                shift
                ;;
            -n|--no-git)
                NO_GIT=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit $EXIT_SUCCESS
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                exit $EXIT_ERROR
                ;;
        esac
    done

    echo "${command:-check}"
}

# Main entry point
main() {
    # Parse configuration
    parse_config || true

    # Parse command line (overrides config)
    local command
    command=$(parse_args "$@")

    # Execute command
    case "$command" in
        check)
            detect_drift "all"
            ;;
        baseline)
            log_info "Generating baseline..."
            generate_baseline "$PROJECT_ROOT" "$BASELINE_FILE" "${IGNORE_PATTERNS[@]}"
            ;;
        fix)
            log_info "Checking for drift to fix..."
            local drift_list=()
            while IFS= read -r drift; do
                [[ -n "$drift" ]] && drift_list+=("$drift")
            done < <(check_all_changes)

            if [[ ${#drift_list[@]} -eq 0 ]]; then
                log_success "No drift to fix"
            else
                export FIX_DRY_RUN="$DRY_RUN"
                export FIX_RESTORE_FROM_GIT="$RESTORE_FROM_GIT"

                if [[ "$DRY_RUN" == true ]]; then
                    log_info "DRY RUN - would fix:"
                fi

                fix_all_drifts "${drift_list[@]}"
            fi
            ;;
        report)
            log_info "Generating drift report..."
            local drift_list=()
            while IFS= read -r drift; do
                [[ -n "$drift" ]] && drift_list+=("$drift")
            done < <(check_all_changes)

            local report
            report=$(generate_report "$FORMAT" "${drift_list[@]}")

            if [[ -n "$OUTPUT_FILE" ]]; then
                echo "$report" > "$OUTPUT_FILE"
                log_success "Report saved to: $OUTPUT_FILE"
            else
                echo "$report"
            fi
            ;;
        *)
            die "Unknown command: $command"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi