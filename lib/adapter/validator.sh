#!/bin/bash
# adapter/validator.sh - Adapter validation module
# Extracted from update.sh as part of DEBT-001 refactoring

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/validation.sh" 2>/dev/null || true

# Validate manifest structure
validate_manifest_structure() {
    local manifest_json="${1:-}"

    if [[ -z "$manifest_json" ]]; then
        log_error "Empty manifest provided"
        return 1
    fi

    # Check for required fields
    if ! echo "$manifest_json" | jq -e '.adapters' >/dev/null 2>&1; then
        log_error "Invalid manifest: missing 'adapters' field"
        return 1
    fi

    # Validate each adapter entry
    local adapters
    adapters=$(echo "$manifest_json" | jq -r '.adapters | keys[]' 2>/dev/null)

    if [[ -z "$adapters" ]]; then
        log_warning "No adapters defined in manifest"
        return 0
    fi

    while IFS= read -r adapter; do
        # Check required adapter fields
        if ! echo "$manifest_json" | jq -e ".adapters[\"$adapter\"].version" >/dev/null 2>&1; then
            log_error "Adapter $adapter missing version field"
            return 1
        fi
    done <<< "$adapters"

    return 0
}

# Validate adapter compatibility
validate_adapter_compatibility() {
    local adapter_name="${1:-}"
    local target_version="${2:-}"

    if [[ -z "$adapter_name" ]]; then
        log_error "Adapter name required"
        return 1
    fi

    # Remove v prefix if present
    target_version="${target_version#v}"

    # Check major version compatibility
    local major_version="${target_version%%.*}"

    case "$major_version" in
        5|6)
            log_info "Adapter $adapter_name compatible with v$target_version"
            return 0
            ;;
        *)
            log_warning "Adapter $adapter_name may not be compatible with v$target_version"
            return 1
            ;;
    esac
}

# Check adapter dependencies
check_adapter_dependencies() {
    local adapter_name="${1:-}"

    if [[ -z "$adapter_name" ]]; then
        log_error "Adapter name required"
        return 1
    fi

    local missing_deps=()

    # Check common dependencies based on adapter
    case "$adapter_name" in
        spec-kit)
            command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
            ;;
        aider)
            command -v python3 >/dev/null 2>&1 || missing_deps+=("python3")
            ;;
        cursor)
            command -v node >/dev/null 2>&1 || missing_deps+=("node")
            ;;
    esac

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies for $adapter_name: ${missing_deps[*]}"
        return 1
    fi

    log_info "All dependencies satisfied for $adapter_name"
    return 0
}

# Validate file permissions
validate_file_permissions() {
    local file="${1:-}"

    if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
        log_error "Invalid file: $file"
        return 1
    fi

    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        log_error "File not readable: $file"
        return 1
    fi

    # Check if script files are executable
    if [[ "$file" == *.sh ]]; then
        if [[ ! -x "$file" ]]; then
            log_warning "Script not executable: $file"
            chmod +x "$file" || return 1
        fi
    fi

    return 0
}

# Validate adapter files
validate_adapter_files() {
    local adapter_name="${1:-}"
    local manifest_file="${2:-${PROJECT_ROOT:-$(pwd)}/.living-docs-manifest.json}"

    if [[ ! -f "$manifest_file" ]]; then
        log_error "Manifest not found"
        return 1
    fi

    # Get file list from manifest
    local files
    files=$(jq -r ".adapters[\"$adapter_name\"].files[]? // empty" "$manifest_file" 2>/dev/null)

    if [[ -z "$files" ]]; then
        log_warning "No files listed for $adapter_name"
        return 0
    fi

    local validation_failed=false

    while IFS= read -r file; do
        if [[ ! -f "$file" ]]; then
            log_error "Missing file: $file"
            validation_failed=true
        elif ! validate_file_permissions "$file"; then
            validation_failed=true
        fi
    done <<< "$files"

    if [[ "$validation_failed" == "true" ]]; then
        return 1
    fi

    log_success "All files valid for $adapter_name"
    return 0
}

# Export functions
export -f validate_manifest_structure
export -f validate_adapter_compatibility
export -f check_adapter_dependencies
export -f validate_file_permissions
export -f validate_adapter_files