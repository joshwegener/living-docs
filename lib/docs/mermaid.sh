#!/usr/bin/env bash
# Mermaid Diagram Validation for living-docs
# Validates Mermaid syntax, checks for common errors, verifies accessibility
# Part of living-docs documentation quality assurance system

set -uo pipefail

# Version and metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="mermaid.sh"

# Configuration
readonly MERMAID_CLI_MIN_VERSION="9.0.0"
readonly MAX_DIAGRAM_COMPLEXITY=50  # Maximum nodes/connections
readonly TEMP_DIR="${TMPDIR:-/tmp}/mermaid-validation-$$"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_VALIDATION_ERROR=1
readonly EXIT_DEPENDENCY_ERROR=2
readonly EXIT_PARSE_ERROR=3
readonly EXIT_ACCESSIBILITY_ERROR=4

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Supported diagram types
readonly -a SUPPORTED_DIAGRAM_TYPES=(
    "flowchart" "graph" "sequenceDiagram" "classDiagram"
    "stateDiagram" "erDiagram" "journey" "gantt"
    "pie" "gitgraph" "requirement" "mindmap"
    "timeline" "sankey" "block" "architecture"
)

# Accessibility requirements
readonly -a ACCESSIBILITY_REQUIRED_ATTRS=(
    "title" "description" "alt"
)

# Global variables
VERBOSE=false
QUIET=false
DRY_RUN=false
CHECK_ACCESSIBILITY=true
CHECK_COMPLEXITY=true
OUTPUT_FORMAT="text"
VALIDATION_RESULTS=()
ERROR_COUNT=0
WARNING_COUNT=0
USE_FALLBACK_MODE=false

# Logging functions
log_info() {
    [[ "$QUIET" != "true" ]] && echo -e "${BLUE}[INFO]${NC} $*" >&2
}

log_warning() {
    [[ "$QUIET" != "true" ]] && echo -e "${YELLOW}[WARN]${NC} $*" >&2
    ((WARNING_COUNT++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    ((ERROR_COUNT++))
}

log_success() {
    [[ "$QUIET" != "true" ]] && echo -e "${GREEN}[SUCCESS]${NC} $*" >&2
}

log_verbose() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[VERBOSE]${NC} $*" >&2
}

# Utility functions
cleanup() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

create_temp_dir() {
    mkdir -p "$TEMP_DIR"
    log_verbose "Created temporary directory: $TEMP_DIR"
}

# Version comparison function
version_compare() {
    local version1="$1"
    local version2="$2"
    local operator="${3:-ge}"

    printf '%s\n%s\n' "$version1" "$version2" | sort -V | head -n1 | grep -q "^$version2$" || {
        case "$operator" in
            "ge"|">=") return 1 ;;
            "le"|"<=") return 0 ;;
            "eq"|"=") return 1 ;;
            "ne"|"!=") return 0 ;;
        esac
    }

    case "$operator" in
        "ge"|">=") return 0 ;;
        "le"|"<=") return 1 ;;
        "eq"|"=") [[ "$version1" == "$version2" ]] ;;
        "ne"|"!=") [[ "$version1" != "$version2" ]] ;;
    esac
}

# Dependency checking
check_dependencies() {
    log_info "Checking dependencies..."

    # Check for mermaid CLI
    if ! command -v mmdc >/dev/null 2>&1; then
        log_warning "Mermaid CLI (mmdc) not found. Using fallback validation mode."
        log_info "For full syntax validation, install with: npm install -g @mermaid-js/mermaid-cli"
        USE_FALLBACK_MODE=true
        return 0
    fi

    # Check mermaid CLI version
    local mmdc_version
    mmdc_version=$(mmdc --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0.0.0")

    if ! version_compare "$mmdc_version" "$MERMAID_CLI_MIN_VERSION" "ge"; then
        log_warning "Mermaid CLI version $mmdc_version is too old (minimum: $MERMAID_CLI_MIN_VERSION). Using fallback mode."
        USE_FALLBACK_MODE=true
        return 0
    fi

    log_success "All dependencies satisfied (mmdc $mmdc_version)"
    USE_FALLBACK_MODE=false
    return 0
}

# Extract Mermaid diagrams from markdown
extract_mermaid_diagrams() {
    local file="$1"
    local output_dir="$2"
    local diagram_count=0

    log_verbose "Extracting Mermaid diagrams from: $file"

    # Parse markdown file for mermaid code blocks
    awk '
        BEGIN {
            in_mermaid = 0
            diagram_num = 0
            line_num = 0
        }
        {
            line_num++
        }
        /^```mermaid/ {
            in_mermaid = 1
            diagram_num++
            filename = "'$output_dir'/diagram_" diagram_num ".mmd"
            start_line = line_num
            next
        }
        /^```/ && in_mermaid {
            in_mermaid = 0
            close(filename)
            print filename ":" start_line ":" line_num
            next
        }
        in_mermaid {
            print $0 > filename
        }
    ' "$file"
}

# Fallback validation for basic syntax errors
validate_diagram_syntax_fallback() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"

    local content
    content=$(cat "$diagram_file")

    # Basic syntax checks
    local errors_found=false

    # Check for balanced brackets
    local open_brackets
    local close_brackets
    open_brackets=$(echo "$content" | grep -o '\[' | wc -l)
    close_brackets=$(echo "$content" | grep -o '\]' | wc -l)

    if [[ $open_brackets -ne $close_brackets ]]; then
        add_validation_result "$source_file" "$start_line" "error" "Unbalanced brackets: $open_brackets '[' vs $close_brackets ']'"
        errors_found=true
    fi

    # Check for balanced parentheses
    local open_parens
    local close_parens
    open_parens=$(echo "$content" | grep -o '(' | wc -l)
    close_parens=$(echo "$content" | grep -o ')' | wc -l)

    if [[ $open_parens -ne $close_parens ]]; then
        add_validation_result "$source_file" "$start_line" "error" "Unbalanced parentheses: $open_parens '(' vs $close_parens ')'"
        errors_found=true
    fi

    # Check for basic diagram declaration
    local first_line
    first_line=$(head -n1 "$diagram_file" | tr -d '\r\n' | sed 's/^[[:space:]]*//')

    if [[ -z "$first_line" ]]; then
        add_validation_result "$source_file" "$start_line" "error" "Empty diagram - missing diagram type declaration"
        errors_found=true
    fi

    # Check for common syntax patterns
    if echo "$content" | grep -q '\-\->\.*\-\->'; then
        add_validation_result "$source_file" "$start_line" "warning" "Potential chained arrows without intermediate nodes"
    fi

    if [[ "$errors_found" == "true" ]]; then
        return 1
    fi

    log_verbose "Basic syntax validation passed for diagram at line $start_line"
    return 0
}

# Validate diagram syntax
validate_diagram_syntax() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"
    local end_line="$4"

    log_verbose "Validating syntax for: $diagram_file"

    # Check if diagram file is empty
    if [[ ! -s "$diagram_file" ]]; then
        add_validation_result "$source_file" "$start_line" "error" "Empty Mermaid diagram block"
        return 1
    fi

    # Use fallback mode if mermaid CLI not available
    if [[ "$USE_FALLBACK_MODE" == "true" ]]; then
        validate_diagram_syntax_fallback "$diagram_file" "$source_file" "$start_line"
        return $?
    fi

    # Validate with mermaid CLI
    local validation_output
    local exit_code

    validation_output=$(mmdc -i "$diagram_file" -o "$diagram_file.png" --quiet 2>&1) || exit_code=$?

    if [[ ${exit_code:-0} -ne 0 ]]; then
        local error_msg="Syntax error in Mermaid diagram"
        if [[ -n "$validation_output" ]]; then
            error_msg="$error_msg: $validation_output"
        fi
        add_validation_result "$source_file" "$start_line" "error" "$error_msg"
        return 1
    fi

    log_verbose "Syntax validation passed for diagram at line $start_line"
    return 0
}

# Check diagram type
validate_diagram_type() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"

    # Handle empty files
    if [[ ! -s "$diagram_file" ]]; then
        return 1
    fi

    local content
    content=$(cat "$diagram_file")

    # Extract diagram type from any line (not just first, as accessibility attributes might come first)
    local diagram_type=""
    while IFS= read -r line; do
        # Skip comment lines and accessibility attributes
        if [[ "$line" =~ ^[[:space:]]*%% ]] || [[ -z "${line// }" ]]; then
            continue
        fi

        for type in "${SUPPORTED_DIAGRAM_TYPES[@]}"; do
            if [[ "$line" =~ ^[[:space:]]*$type ]]; then
                diagram_type="$type"
                break 2
            fi
        done
    done <<< "$content"

    if [[ -z "$diagram_type" ]]; then
        local first_non_empty_line
        first_non_empty_line=$(echo "$content" | grep -v '^[[:space:]]*$' | grep -v '^[[:space:]]*%%' | head -n1)
        add_validation_result "$source_file" "$start_line" "warning" "Unknown diagram type. First content line: '$first_non_empty_line'"
        return 1
    fi

    log_verbose "Detected diagram type: $diagram_type"
    return 0
}

# Check diagram complexity
validate_diagram_complexity() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"

    [[ "$CHECK_COMPLEXITY" != "true" ]] && return 0

    # Handle empty files
    if [[ ! -s "$diagram_file" ]]; then
        return 0
    fi

    local content
    content=$(cat "$diagram_file")

    # Count nodes and connections (approximate)
    local node_count
    local connection_count

    # Count potential nodes (lines with -->)
    node_count=$(echo "$content" | grep -c '\-\->' 2>/dev/null)
    node_count=${node_count:-0}

    # Count connections
    connection_count=$(echo "$content" | grep -c '\-\-\|==\|~\~\|-\.\-\|::' 2>/dev/null)
    connection_count=${connection_count:-0}

    local total_complexity=$((node_count + connection_count))

    if [[ $total_complexity -gt $MAX_DIAGRAM_COMPLEXITY ]]; then
        add_validation_result "$source_file" "$start_line" "warning" \
            "Diagram complexity ($total_complexity) exceeds recommended maximum ($MAX_DIAGRAM_COMPLEXITY)"
        return 1
    fi

    log_verbose "Diagram complexity: $total_complexity (within limits)"
    return 0
}

# Check accessibility features
validate_accessibility() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"

    [[ "$CHECK_ACCESSIBILITY" != "true" ]] && return 0

    # Handle empty files
    if [[ ! -s "$diagram_file" ]]; then
        return 0
    fi

    local content
    content=$(cat "$diagram_file")

    local has_title=false
    local has_description=false

    # Check for accessibility attributes
    if echo "$content" | grep -q '%%{.*title.*}%%'; then
        has_title=true
    fi

    if echo "$content" | grep -q '%%{.*description.*}%%'; then
        has_description=true
    fi

    # Check for alt text in HTML comments
    if echo "$content" | grep -q '<!--.*alt.*-->'; then
        log_verbose "Found alt text in HTML comment"
    fi

    if [[ "$has_title" != "true" ]]; then
        add_validation_result "$source_file" "$start_line" "warning" \
            "Missing accessibility title. Add: %%{title: 'Your Title'}%%"
    fi

    if [[ "$has_description" != "true" ]]; then
        add_validation_result "$source_file" "$start_line" "info" \
            "Consider adding description for screen readers: %%{description: 'Your Description'}%%"
    fi

    return 0
}

# Check for common diagram errors
validate_common_errors() {
    local diagram_file="$1"
    local source_file="$2"
    local start_line="$3"

    # Handle empty files
    if [[ ! -s "$diagram_file" ]]; then
        return 0
    fi

    local content
    content=$(cat "$diagram_file")

    # Check for unclosed quotes
    if echo "$content" | grep -q '"[^"]*$\|'\''[^'\'']*$'; then
        add_validation_result "$source_file" "$start_line" "error" \
            "Potentially unclosed quotes detected"
    fi

    # Check for invalid characters in node IDs
    if echo "$content" | grep -qE '[^a-zA-Z0-9_-]+\['; then
        add_validation_result "$source_file" "$start_line" "warning" \
            "Node IDs should only contain alphanumeric characters, underscores, and hyphens"
    fi

    # Check for extremely long labels
    local long_labels
    long_labels=$(echo "$content" | grep -oE '\[[^]]{100,}\]' | wc -l)
    if [[ $long_labels -gt 0 ]]; then
        add_validation_result "$source_file" "$start_line" "warning" \
            "Found $long_labels labels longer than 100 characters (consider breaking into multiple lines)"
    fi

    return 0
}

# Add validation result
add_validation_result() {
    local file="$1"
    local line="$2"
    local severity="$3"
    local message="$4"

    local result="$file:$line:$severity:$message"
    VALIDATION_RESULTS+=("$result")

    case "$severity" in
        "error") log_error "$file:$line - $message" ;;
        "warning") log_warning "$file:$line - $message" ;;
        "info") log_info "$file:$line - $message" ;;
    esac
}

# Validate single file
validate_file() {
    local file="$1"

    log_info "Validating: $file"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return $EXIT_PARSE_ERROR
    fi

    if [[ ! -r "$file" ]]; then
        log_error "File not readable: $file"
        return $EXIT_PARSE_ERROR
    fi

    # Create temporary directory for this file
    local file_temp_dir="$TEMP_DIR/$(basename "$file" .md)"
    mkdir -p "$file_temp_dir"

    # Extract diagrams
    local diagrams_info
    diagrams_info=$(extract_mermaid_diagrams "$file" "$file_temp_dir")

    if [[ -z "$diagrams_info" ]]; then
        log_info "No Mermaid diagrams found in $file"
        return 0
    fi

    local diagram_count=0
    local validation_passed=true

    # Process each diagram
    while IFS=: read -r diagram_file start_line end_line; do
        [[ -z "$diagram_file" ]] && continue

        ((diagram_count++))
        log_verbose "Processing diagram $diagram_count at line $start_line"

        # Run all validations
        validate_diagram_syntax "$diagram_file" "$file" "$start_line" "$end_line" || validation_passed=false
        validate_diagram_type "$diagram_file" "$file" "$start_line" || true  # Non-critical
        validate_diagram_complexity "$diagram_file" "$file" "$start_line" || true  # Non-critical
        validate_accessibility "$diagram_file" "$file" "$start_line" || true  # Non-critical
        validate_common_errors "$diagram_file" "$file" "$start_line" || true  # Non-critical

    done <<< "$diagrams_info"

    log_info "Processed $diagram_count Mermaid diagrams in $file"

    if [[ "$validation_passed" == "true" ]]; then
        return 0
    else
        return $EXIT_VALIDATION_ERROR
    fi
}

# Output results
output_results() {
    case "$OUTPUT_FORMAT" in
        "json")
            output_json_results
            ;;
        "junit")
            output_junit_results
            ;;
        *)
            output_text_results
            ;;
    esac
}

output_text_results() {
    echo
    echo "=== Mermaid Validation Results ==="
    echo "Total files processed: ${#VALIDATION_RESULTS[@]}"
    echo "Errors: $ERROR_COUNT"
    echo "Warnings: $WARNING_COUNT"
    echo

    if [[ ${#VALIDATION_RESULTS[@]} -gt 0 ]]; then
        echo "Issues found:"
        for result in "${VALIDATION_RESULTS[@]}"; do
            echo "  $result"
        done
    else
        echo "No issues found!"
    fi
}

output_json_results() {
    if command -v jq >/dev/null 2>&1; then
        output_json_results_with_jq
    else
        output_json_results_plain
    fi
}

output_json_results_with_jq() {
    local json_output='{"validation_results":[],"summary":{}}'

    # Add results
    for result in "${VALIDATION_RESULTS[@]}"; do
        local file line severity message
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)
        severity=$(echo "$result" | cut -d: -f3)
        message=$(echo "$result" | cut -d: -f4-)
        json_output=$(echo "$json_output" | jq --arg file "$file" --arg line "$line" --arg severity "$severity" --arg message "$message" \
            '.validation_results += [{"file": $file, "line": ($line | tonumber), "severity": $severity, "message": $message}]')
    done

    # Add summary
    json_output=$(echo "$json_output" | jq --arg errors "$ERROR_COUNT" --arg warnings "$WARNING_COUNT" \
        '.summary = {"errors": ($errors | tonumber), "warnings": ($warnings | tonumber)}')

    echo "$json_output"
}

output_json_results_plain() {
    echo "{"
    echo "  \"validation_results\": ["

    local first=true
    for result in "${VALIDATION_RESULTS[@]}"; do
        local file line severity message
        file=$(echo "$result" | cut -d: -f1)
        line=$(echo "$result" | cut -d: -f2)
        severity=$(echo "$result" | cut -d: -f3)
        message=$(echo "$result" | cut -d: -f4-)

        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        # Escape JSON strings
        file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
        message=$(echo "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')

        echo -n "    {\"file\": \"$file\", \"line\": $line, \"severity\": \"$severity\", \"message\": \"$message\"}"
    done

    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"errors\": $ERROR_COUNT,"
    echo "    \"warnings\": $WARNING_COUNT"
    echo "  }"
    echo "}"
}

output_junit_results() {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<testsuite name="MermaidValidation" tests="1" failures="'$ERROR_COUNT'" errors="0" skipped="0">'
    echo '  <testcase classname="MermaidValidation" name="DiagramValidation">'

    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo '    <failure message="Mermaid validation errors found">'
        for result in "${VALIDATION_RESULTS[@]}"; do
            if [[ "$result" =~ :error: ]]; then
                echo "      $result"
            fi
        done
        echo '    </failure>'
    fi

    echo '  </testcase>'
    echo '</testsuite>'
}

# Help function
show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION - Mermaid Diagram Validation

USAGE:
    $SCRIPT_NAME [OPTIONS] <file1.md> [file2.md] ...
    $SCRIPT_NAME [OPTIONS] -d <directory>

OPTIONS:
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress non-error output
    -n, --dry-run           Show what would be done without executing
    -f, --format FORMAT     Output format (text|json|junit) [default: text]
    -d, --directory DIR     Validate all markdown files in directory
    -r, --recursive         Recurse into subdirectories (with -d)
    --no-accessibility      Skip accessibility checks
    --no-complexity         Skip complexity checks
    --max-complexity N      Set maximum diagram complexity [default: $MAX_DIAGRAM_COMPLEXITY]
    -h, --help              Show this help message
    --version               Show version information

EXAMPLES:
    # Validate single file
    $SCRIPT_NAME README.md

    # Validate multiple files
    $SCRIPT_NAME docs/*.md

    # Validate directory recursively with JSON output
    $SCRIPT_NAME -d docs -r -f json

    # Validate with custom complexity limit
    $SCRIPT_NAME --max-complexity 100 architecture.md

DIAGRAM TYPES SUPPORTED:
    flowchart, graph, sequenceDiagram, classDiagram, stateDiagram,
    erDiagram, journey, gantt, pie, gitgraph, requirement, mindmap,
    timeline, sankey, block, architecture

ACCESSIBILITY FEATURES:
    - Checks for title attributes: %%{title: 'Diagram Title'}%%
    - Checks for descriptions: %%{description: 'Detailed description'}%%
    - Validates alt text in HTML comments

EXIT CODES:
    0 - Success (no errors)
    1 - Validation errors found
    2 - Missing dependencies
    3 - Parse/file errors
    4 - Accessibility errors

For more information, visit: https://github.com/living-docs/mermaid-validation
EOF
}

# Main validation function
main() {
    local files=()
    local directory=""
    local recursive=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                VERBOSE=false
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            -d|--directory)
                directory="$2"
                shift 2
                ;;
            -r|--recursive)
                recursive=true
                shift
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
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use -h or --help for usage information."
                exit 1
                ;;
            *)
                files+=("$1")
                shift
                ;;
        esac
    done

    # Validate output format
    case "$OUTPUT_FORMAT" in
        "text"|"json"|"junit") ;;
        *)
            log_error "Invalid output format: $OUTPUT_FORMAT"
            exit 1
            ;;
    esac

    # Check dependencies
    check_dependencies || exit $?

    # Create temporary directory
    create_temp_dir

    # Collect files to validate
    if [[ -n "$directory" ]]; then
        if [[ ! -d "$directory" ]]; then
            log_error "Directory not found: $directory"
            exit $EXIT_PARSE_ERROR
        fi

        local find_args=("$directory" -name "*.md" -type f)
        [[ "$recursive" != "true" ]] && find_args+=(-maxdepth 1)

        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "${find_args[@]}" -print0)

        if [[ ${#files[@]} -eq 0 ]]; then
            log_warning "No markdown files found in: $directory"
            exit 0
        fi
    fi

    if [[ ${#files[@]} -eq 0 ]]; then
        log_error "No files specified for validation"
        echo "Use -h or --help for usage information."
        exit 1
    fi

    # Validate files
    local overall_exit_code=0
    for file in "${files[@]}"; do
        if ! validate_file "$file"; then
            overall_exit_code=$EXIT_VALIDATION_ERROR
        fi
    done

    # Output results
    output_results

    exit $overall_exit_code
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi