#!/usr/bin/env bash
# Drift analyzer module - analyzes and categorizes drift types
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Analyze drift patterns
analyze_drift() {
    local drift_list=("$@")
    local analysis=()

    # Counters for different drift types
    local modified=0
    local added=0
    local deleted=0

    for drift in "${drift_list[@]}"; do
        case "$drift" in
            MODIFIED:*)
                ((modified++))
                ;;
            ADDED:*)
                ((added++))
                ;;
            DELETED:*)
                ((deleted++))
                ;;
        esac
    done

    # Generate analysis
    analysis+=("Total drifts: ${#drift_list[@]}")
    analysis+=("Modified files: $modified")
    analysis+=("Added files: $added")
    analysis+=("Deleted files: $deleted")

    printf '%s\n' "${analysis[@]}"
}

# Categorize drift by severity
categorize_drift_severity() {
    local file="$1"
    local drift_type="$2"

    # Critical files
    if [[ "$file" == *".living-docs-manifest.json" ]] ||
       [[ "$file" == *"wizard.sh" ]] ||
       [[ "$file" == *"security/"* ]]; then
        echo "CRITICAL"
        return
    fi

    # High priority files
    if [[ "$file" == *"lib/"* ]] ||
       [[ "$file" == *"scripts/"* ]] ||
       [[ "$drift_type" == "DELETED" ]]; then
        echo "HIGH"
        return
    fi

    # Medium priority
    if [[ "$file" == *"docs/"* ]] ||
       [[ "$file" == *"templates/"* ]]; then
        echo "MEDIUM"
        return
    fi

    # Low priority
    echo "LOW"
}

# Group drifts by directory
group_drifts_by_directory() {
    local drift_list=("$@")
    declare -A dir_counts

    for drift in "${drift_list[@]}"; do
        local file="${drift#*:}"
        local dir
        dir=$(dirname "$file")

        if [[ -z "${dir_counts[$dir]:-}" ]]; then
            dir_counts["$dir"]=1
        else
            ((dir_counts["$dir"]++))
        fi
    done

    # Output grouped results
    for dir in "${!dir_counts[@]}"; do
        echo "$dir: ${dir_counts[$dir]} drifts"
    done | sort
}

# Suggest fixes for drifts
suggest_drift_fixes() {
    local drift="$1"
    local suggestions=()

    case "$drift" in
        MODIFIED:*)
            local file="${drift#MODIFIED:}"
            suggestions+=("Review changes to $file")
            suggestions+=("Option 1: Accept changes and update baseline")
            suggestions+=("Option 2: Revert to baseline version")
            suggestions+=("Option 3: Manually merge changes")
            ;;
        ADDED:*)
            local file="${drift#ADDED:}"
            suggestions+=("New file detected: $file")
            suggestions+=("Option 1: Add to baseline if intentional")
            suggestions+=("Option 2: Remove if unintended")
            suggestions+=("Option 3: Add to ignore list if temporary")
            ;;
        DELETED:*)
            local file="${drift#DELETED:}"
            suggestions+=("File missing: $file")
            suggestions+=("Option 1: Restore from git/backup")
            suggestions+=("Option 2: Update baseline if deletion intended")
            suggestions+=("Option 3: Recreate if needed")
            ;;
    esac

    printf '%s\n' "${suggestions[@]}"
}

# Analyze drift impact
analyze_drift_impact() {
    local drift_list=("$@")
    local impact_report=()
    local critical_count=0
    local high_count=0

    for drift in "${drift_list[@]}"; do
        local drift_type="${drift%%:*}"
        local file="${drift#*:}"
        local severity
        severity=$(categorize_drift_severity "$file" "$drift_type")

        case "$severity" in
            CRITICAL)
                ((critical_count++))
                impact_report+=("CRITICAL: $drift")
                ;;
            HIGH)
                ((high_count++))
                ;;
        esac
    done

    # Generate impact summary
    if [[ $critical_count -gt 0 ]]; then
        echo "CRITICAL IMPACT: $critical_count critical drifts detected"
    elif [[ $high_count -gt 0 ]]; then
        echo "HIGH IMPACT: $high_count high-priority drifts detected"
    else
        echo "LOW IMPACT: Only low-priority drifts detected"
    fi

    # Output critical drifts
    printf '%s\n' "${impact_report[@]}"
}

# Export functions
export -f analyze_drift
export -f categorize_drift_severity
export -f group_drifts_by_directory
export -f suggest_drift_fixes
export -f analyze_drift_impact