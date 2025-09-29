#!/usr/bin/env bash
# Drift reporter module - generates drift reports in various formats
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Generate human-readable drift report
generate_human_report() {
    local drift_list=("$@")
    local report=()

    if [[ ${#drift_list[@]} -eq 0 ]]; then
        report+=("✅ No drift detected - documentation is in sync")
        printf '%s\n' "${report[@]}"
        return 0
    fi

    # Header
    report+=("🔍 DRIFT DETECTION REPORT")
    report+=("========================")
    report+=("Found ${#drift_list[@]} drifts")
    report+=("")

    # Categorize drifts
    local modified=()
    local added=()
    local deleted=()

    for drift in "${drift_list[@]}"; do
        case "$drift" in
            MODIFIED:*)
                modified+=("${drift#MODIFIED:}")
                ;;
            ADDED:*)
                added+=("${drift#ADDED:}")
                ;;
            DELETED:*)
                deleted+=("${drift#DELETED:}")
                ;;
        esac
    done

    # Modified files section
    if [[ ${#modified[@]} -gt 0 ]]; then
        report+=("📝 MODIFIED FILES (${#modified[@]})")
        report+=("------------------")
        for file in "${modified[@]}"; do
            report+=("  • $file")
        done
        report+=("")
    fi

    # Added files section
    if [[ ${#added[@]} -gt 0 ]]; then
        report+=("➕ ADDED FILES (${#added[@]})")
        report+=("---------------")
        for file in "${added[@]}"; do
            report+=("  • $file")
        done
        report+=("")
    fi

    # Deleted files section
    if [[ ${#deleted[@]} -gt 0 ]]; then
        report+=("➖ DELETED FILES (${#deleted[@]})")
        report+=("-----------------")
        for file in "${deleted[@]}"; do
            report+=("  • $file")
        done
        report+=("")
    fi

    # Summary
    report+=("SUMMARY")
    report+=("-------")
    report+=("Modified: ${#modified[@]}")
    report+=("Added:    ${#added[@]}")
    report+=("Deleted:  ${#deleted[@]}")
    report+=("Total:    ${#drift_list[@]}")

    printf '%s\n' "${report[@]}"
}

# Generate JSON drift report
generate_json_report() {
    local drift_list=("$@")
    local json="{"

    # Add timestamp
    json+="\"timestamp\":\"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\","

    # Add summary
    local modified_count=0
    local added_count=0
    local deleted_count=0

    for drift in "${drift_list[@]}"; do
        case "$drift" in
            MODIFIED:*) ((modified_count++)) ;;
            ADDED:*) ((added_count++)) ;;
            DELETED:*) ((deleted_count++)) ;;
        esac
    done

    json+="\"summary\":{"
    json+="\"total\":${#drift_list[@]},"
    json+="\"modified\":$modified_count,"
    json+="\"added\":$added_count,"
    json+="\"deleted\":$deleted_count"
    json+="},"

    # Add drifts array
    json+="\"drifts\":["

    local first=true
    for drift in "${drift_list[@]}"; do
        if [[ "$first" == false ]]; then
            json+=","
        fi
        first=false

        local type="${drift%%:*}"
        local file="${drift#*:}"

        json+="{\"type\":\"$type\",\"file\":\"$file\""

        # Add severity if available
        if command -v categorize_drift_severity &>/dev/null; then
            local severity
            severity=$(categorize_drift_severity "$file" "$type")
            json+=",\"severity\":\"$severity\""
        fi

        json+="}"
    done

    json+="]}"

    echo "$json"
}

# Generate markdown drift report
generate_markdown_report() {
    local drift_list=("$@")
    local report=()

    report+=("# Drift Detection Report")
    report+=("")
    report+=("Generated: $(date '+%Y-%m-%d %H:%M:%S')")
    report+=("")

    if [[ ${#drift_list[@]} -eq 0 ]]; then
        report+=("✅ **No drift detected** - documentation is in sync")
        printf '%s\n' "${report[@]}"
        return 0
    fi

    report+=("## Summary")
    report+=("")
    report+=("| Metric | Count |")
    report+=("|--------|-------|")

    local modified=0 added=0 deleted=0
    for drift in "${drift_list[@]}"; do
        case "$drift" in
            MODIFIED:*) ((modified++)) ;;
            ADDED:*) ((added++)) ;;
            DELETED:*) ((deleted++)) ;;
        esac
    done

    report+=("| Modified | $modified |")
    report+=("| Added | $added |")
    report+=("| Deleted | $deleted |")
    report+=("| **Total** | **${#drift_list[@]}** |")
    report+=("")

    # Detailed sections
    report+=("## Details")
    report+=("")

    local has_critical=false
    for drift in "${drift_list[@]}"; do
        local type="${drift%%:*}"
        local file="${drift#*:}"

        if command -v categorize_drift_severity &>/dev/null; then
            local severity
            severity=$(categorize_drift_severity "$file" "$type")
            if [[ "$severity" == "CRITICAL" ]]; then
                has_critical=true
            fi
        fi
    done

    if [[ "$has_critical" == true ]]; then
        report+=("### ⚠️ Critical Drifts")
        report+=("")
        for drift in "${drift_list[@]}"; do
            local type="${drift%%:*}"
            local file="${drift#*:}"
            if command -v categorize_drift_severity &>/dev/null; then
                local severity
                severity=$(categorize_drift_severity "$file" "$type")
                if [[ "$severity" == "CRITICAL" ]]; then
                    report+=("- **$type**: \`$file\`")
                fi
            fi
        done
        report+=("")
    fi

    # Modified files
    local modified_files=()
    for drift in "${drift_list[@]}"; do
        if [[ "$drift" == MODIFIED:* ]]; then
            modified_files+=("${drift#MODIFIED:}")
        fi
    done

    if [[ ${#modified_files[@]} -gt 0 ]]; then
        report+=("### Modified Files")
        report+=("")
        for file in "${modified_files[@]}"; do
            report+=("- \`$file\`")
        done
        report+=("")
    fi

    # Added files
    local added_files=()
    for drift in "${drift_list[@]}"; do
        if [[ "$drift" == ADDED:* ]]; then
            added_files+=("${drift#ADDED:}")
        fi
    done

    if [[ ${#added_files[@]} -gt 0 ]]; then
        report+=("### Added Files")
        report+=("")
        for file in "${added_files[@]}"; do
            report+=("- \`$file\`")
        done
        report+=("")
    fi

    # Deleted files
    local deleted_files=()
    for drift in "${drift_list[@]}"; do
        if [[ "$drift" == DELETED:* ]]; then
            deleted_files+=("${drift#DELETED:}")
        fi
    done

    if [[ ${#deleted_files[@]} -gt 0 ]]; then
        report+=("### Deleted Files")
        report+=("")
        for file in "${deleted_files[@]}"; do
            report+=("- \`$file\`")
        done
        report+=("")
    fi

    printf '%s\n' "${report[@]}"
}

# Generate CSV drift report
generate_csv_report() {
    local drift_list=("$@")

    # Header
    echo "Type,File,Severity,Timestamp"

    # Data rows
    for drift in "${drift_list[@]}"; do
        local type="${drift%%:*}"
        local file="${drift#*:}"
        local severity="UNKNOWN"

        if command -v categorize_drift_severity &>/dev/null; then
            severity=$(categorize_drift_severity "$file" "$type")
        fi

        echo "$type,$file,$severity,$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    done
}

# Generate report in specified format
generate_report() {
    local format="${1:-human}"
    shift
    local drift_list=("$@")

    case "$format" in
        human|text)
            generate_human_report "${drift_list[@]}"
            ;;
        json)
            generate_json_report "${drift_list[@]}"
            ;;
        markdown|md)
            generate_markdown_report "${drift_list[@]}"
            ;;
        csv)
            generate_csv_report "${drift_list[@]}"
            ;;
        *)
            log_error "Unknown report format: $format"
            return 1
            ;;
    esac
}

# Export functions
export -f generate_human_report
export -f generate_json_report
export -f generate_markdown_report
export -f generate_csv_report
export -f generate_report