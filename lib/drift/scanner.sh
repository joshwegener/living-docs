#!/usr/bin/env bash
# Drift scanner module - file system scanning and checksum generation
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/paths.sh" 2>/dev/null || true

# Calculate checksum for a file
calculate_file_checksum() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Use sha256sum or shasum depending on platform
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        die "No checksum utility found" "$E_DEPENDENCY_MISSING"
    fi
}

# Scan directory for files and generate checksums
scan_directory() {
    local dir="${1:-.}"
    local ignore_patterns=("${@:2}")
    local checksums=()

    # Find all files (excluding ignored patterns)
    while IFS= read -r file; do
        local skip=false

        # Check ignore patterns
        for pattern in "${ignore_patterns[@]}"; do
            if [[ "$file" == $pattern ]]; then
                skip=true
                break
            fi
        done

        if [[ "$skip" == false ]]; then
            local checksum
            checksum=$(calculate_file_checksum "$file")
            if [[ -n "$checksum" ]]; then
                checksums+=("$checksum  $file")
            fi
        fi
    done < <(find "$dir" -type f 2>/dev/null | sort)

    # Output checksums
    printf '%s\n' "${checksums[@]}"
}

# Compare two checksum lists
compare_checksums() {
    local baseline_file="$1"
    local current_file="$2"
    local drifts=()

    # Read baseline into associative array
    declare -A baseline_checksums
    while IFS='  ' read -r checksum file; do
        baseline_checksums["$file"]="$checksum"
    done < "$baseline_file"

    # Compare current against baseline
    while IFS='  ' read -r checksum file; do
        if [[ -n "${baseline_checksums[$file]:-}" ]]; then
            if [[ "${baseline_checksums[$file]}" != "$checksum" ]]; then
                drifts+=("MODIFIED:$file")
            fi
            unset baseline_checksums["$file"]
        else
            drifts+=("ADDED:$file")
        fi
    done < "$current_file"

    # Check for deleted files
    for file in "${!baseline_checksums[@]}"; do
        drifts+=("DELETED:$file")
    done

    # Output drifts
    printf '%s\n' "${drifts[@]}"
}

# Generate baseline checksums
generate_baseline() {
    local dir="${1:-.}"
    local baseline_file="$2"
    local ignore_patterns=("${@:3}")

    log_info "Generating baseline checksums..."

    # Create directory if needed
    local baseline_dir
    baseline_dir=$(dirname "$baseline_file")
    ensure_dir "$baseline_dir"

    # Scan and save checksums
    scan_directory "$dir" "${ignore_patterns[@]}" > "$baseline_file"

    local file_count
    file_count=$(wc -l < "$baseline_file" | tr -d ' ')
    log_success "Baseline generated with $file_count files"

    return 0
}

# Check for drift against baseline
check_drift() {
    local dir="${1:-.}"
    local baseline_file="$2"
    local ignore_patterns=("${@:3}")

    if [[ ! -f "$baseline_file" ]]; then
        log_error "Baseline file not found: $baseline_file"
        return 1
    fi

    # Generate current checksums
    local temp_file
    temp_file=$(mktemp)
    scan_directory "$dir" "${ignore_patterns[@]}" > "$temp_file"

    # Compare with baseline
    local drifts
    drifts=$(compare_checksums "$baseline_file" "$temp_file")

    # Clean up
    rm -f "$temp_file"

    if [[ -n "$drifts" ]]; then
        echo "$drifts"
        return 1
    else
        return 0
    fi
}

# Export functions
export -f calculate_file_checksum
export -f scan_directory
export -f compare_checksums
export -f generate_baseline
export -f check_drift