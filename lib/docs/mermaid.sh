#!/usr/bin/env bash
set -euo pipefail
# Mermaid Diagram Validation for living-docs
# Main orchestrator using modular components
# Part of living-docs documentation quality assurance system

# Version and metadata
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="mermaid.sh"

# Configuration
readonly MERMAID_CLI_MIN_VERSION="9.0.0"
readonly MAX_DIAGRAM_COMPLEXITY=50
readonly TEMP_DIR="${TMPDIR:-/tmp}/mermaid-validation-$$"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_VALIDATION_ERROR=1
readonly EXIT_DEPENDENCY_ERROR=2
readonly EXIT_PARSE_ERROR=3
readonly EXIT_ACCESSIBILITY_ERROR=4

# Global variables
VERBOSE=false
QUIET=false
DRY_RUN=false
CHECK_ACCESSIBILITY=true
CHECK_COMPLEXITY=true
OUTPUT_FORMAT="text"
VALIDATION_RESULTS=()

# Source modular components
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/mermaid-parser.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/mermaid-validator.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/mermaid-reporter.sh" 2>/dev/null || true

# Cleanup on exit
cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Create temp directory
create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

# Version comparison
version_compare() {
    local version1="$1"
    local version2="$2"

    # Split versions into arrays
    IFS='.' read -ra v1_parts <<< "$version1"
    IFS='.' read -ra v2_parts <<< "$version2"

    # Compare each part
    for i in "${!v1_parts[@]}"; do
        # If version2 has fewer parts, version1 is greater
        if [[ $i -ge ${#v2_parts[@]} ]]; then
            return 1
        fi

        if [[ ${v1_parts[$i]} -gt ${v2_parts[$i]} ]]; then
            return 1
        elif [[ ${v1_parts[$i]} -lt ${v2_parts[$i]} ]]; then
            return 0
        fi
    done

    # If we get here, versions are equal or version1 has fewer parts
    return 0
}

# Check dependencies
check_dependencies() {
    local deps_ok=true

    # Check for mermaid CLI (optional but recommended)
    if command -v mmdc &>/dev/null; then
        local mmdc_version
        mmdc_version=$(mmdc --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

        if [[ -n "$mmdc_version" ]]; then
            if ! version_compare "$MERMAID_CLI_MIN_VERSION" "$mmdc_version"; then
                log_warning "Mermaid CLI version $mmdc_version is older than recommended $MERMAID_CLI_MIN_VERSION"
            else
                log_verbose "Mermaid CLI version $mmdc_version detected"
            fi
        fi
    else
        log_verbose "Mermaid CLI not found - using fallback validation"
    fi

    # Check for optional tools
    if ! command -v jq &>/dev/null && [[ "$OUTPUT_FORMAT" == "json" ]]; then
        log_verbose "jq not found - will use plain JSON output"
    fi

    return 0
}

# Add validation result
add_validation_result() {
    local file="$1"
    local line="${2:-0}"
    local type="$3"
    local message="$4"

    local result="$file:$line:$type:$message"
    VALIDATION_RESULTS+=("$result")

    # Output immediately if not quiet
    if [[ "$QUIET" != true ]]; then
        case "$type" in
            ERROR)
                log_error "[$file:$line] $message"
                ;;
            WARNING)
                log_warning "[$file:$line] $message"
                ;;
            INFO)
                log_verbose "[$file:$line] $message"
                ;;
        esac
    fi
}

# Validate single file
validate_file() {
    local file="$1"
    local file_valid=true

    if [[ ! -f "$file" ]]; then
        add_validation_result "$file" 0 "ERROR" "File not found"
        return $EXIT_VALIDATION_ERROR
    fi

    log_info "Validating: $file"

    # Extract diagrams
    local diagrams=()
    while IFS= read -r diagram_info; do
        [[ -n "$diagram_info" ]] && diagrams+=("$diagram_info")
    done < <(extract_mermaid_diagrams "$file")

    if [[ ${#diagrams[@]} -eq 0 ]]; then
        add_validation_result "$file" 0 "INFO" "No Mermaid diagrams found"
        return $EXIT_SUCCESS
    fi

    # Validate each diagram
    for diagram_info in "${diagrams[@]}"; do
        local line_num="${diagram_info%%|*}"
        line_num="${line_num#LINE:}"
        local content="${diagram_info#*CONTENT:}"

        # Validate diagram type
        if ! diagram_type=$(validate_diagram_type "$content"); then
            add_validation_result "$file" "$line_num" "ERROR" "Invalid or missing diagram type"
            file_valid=false
            continue
        fi

        # Validate syntax
        if ! validate_diagram_syntax "$content"; then
            add_validation_result "$file" "$line_num" "ERROR" "Syntax validation failed"
            file_valid=false
        fi

        # Check complexity
        if [[ "$CHECK_COMPLEXITY" == true ]]; then
            if ! validate_diagram_complexity "$content" "$MAX_DIAGRAM_COMPLEXITY"; then
                add_validation_result "$file" "$line_num" "WARNING" "Diagram exceeds complexity threshold"
            fi
        fi

        # Check accessibility
        if [[ "$CHECK_ACCESSIBILITY" == true ]]; then
            local accessibility_warnings
            if ! accessibility_warnings=$(validate_accessibility "$content" 2>&1); then
                while IFS= read -r warning; do
                    [[ -n "$warning" ]] && add_validation_result "$file" "$line_num" "WARNING" "$warning"
                done <<< "$accessibility_warnings"
            fi
        fi

        # Check common errors
        local common_errors
        if ! common_errors=$(check_common_errors "$content" 2>&1); then
            while IFS= read -r error; do
                [[ -n "$error" ]] && add_validation_result "$file" "$line_num" "WARNING" "$error"
            done <<< "$common_errors"
        fi
    done

    if [[ "$file_valid" == false ]]; then
        return $EXIT_VALIDATION_ERROR
    fi

    return $EXIT_SUCCESS
}

# Show usage
show_help() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] FILE...

Validate Mermaid diagrams in markdown files

Options:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress output except errors
    -f, --format FORMAT     Output format: text, json, junit, csv, markdown
                           (default: text)
    -o, --output FILE       Write results to file (default: stdout)
    --no-accessibility      Skip accessibility checks
    --no-complexity         Skip complexity checks
    --max-complexity NUM    Set maximum complexity threshold (default: 50)
    --version              Show version information

Examples:
    $SCRIPT_NAME README.md
    $SCRIPT_NAME --format json docs/*.md
    $SCRIPT_NAME -v --output report.xml --format junit docs/

Exit codes:
    0 - All validations passed
    1 - Validation errors found
    2 - Dependency error
    3 - Parse error
    4 - Accessibility error

EOF
}

# Parse arguments
parse_args() {
    local files=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit $EXIT_SUCCESS
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --no-accessibility)
                CHECK_ACCESSIBILITY=false
                shift
                ;;
            --no-complexity)
                CHECK_COMPLEXITY=false
                shift
                ;;
            --max-complexity)
                MAX_DIAGRAM_COMPLEXITY="$2"
                shift 2
                ;;
            --version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit $EXIT_SUCCESS
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit $EXIT_PARSE_ERROR
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    printf '%s\n' "${files[@]}"
}

# Main function
main() {
    local files=()

    # Parse arguments
    while IFS= read -r file; do
        [[ -n "$file" ]] && files+=("$file")
    done < <(parse_args "$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        log_error "No files specified"
        show_help
        exit $EXIT_PARSE_ERROR
    fi

    # Check dependencies
    check_dependencies

    # Create temp directory
    create_temp_dir

    # Validate each file
    local exit_code=$EXIT_SUCCESS
    for file in "${files[@]}"; do
        if ! validate_file "$file"; then
            exit_code=$EXIT_VALIDATION_ERROR
        fi
    done

    # Output results
    if [[ ${#VALIDATION_RESULTS[@]} -gt 0 ]] || [[ "$QUIET" != true ]]; then
        local output
        output=$(output_results "$OUTPUT_FORMAT" "${VALIDATION_RESULTS[@]}")

        if [[ -n "${OUTPUT_FILE:-}" ]]; then
            echo "$output" > "$OUTPUT_FILE"
            log_success "Results written to: $OUTPUT_FILE"
        else
            echo "$output"
        fi
    fi

    exit $exit_code
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi