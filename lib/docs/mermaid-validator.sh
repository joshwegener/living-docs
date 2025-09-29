#!/usr/bin/env bash
# Mermaid diagram validation module
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Supported diagram types
readonly -a SUPPORTED_DIAGRAM_TYPES=(
    "flowchart" "graph" "sequenceDiagram" "classDiagram"
    "stateDiagram" "erDiagram" "journey" "gantt"
    "pie" "gitgraph" "requirement" "mindmap"
    "timeline" "sankey" "block" "architecture"
)

# Validate diagram syntax using fallback method
validate_diagram_syntax_fallback() {
    local diagram_content="$1"
    local errors=()

    # Basic syntax checks
    local diagram_type=""
    if [[ "$diagram_content" =~ ^(flowchart|graph|sequenceDiagram|classDiagram|stateDiagram|erDiagram|journey|gantt|pie|gitgraph|requirement|mindmap|timeline|sankey|block|architecture) ]]; then
        diagram_type="${BASH_REMATCH[1]}"
    else
        errors+=("Unknown diagram type or missing declaration")
    fi

    # Check for balanced brackets
    local open_count
    open_count=$(echo "$diagram_content" | tr -cd '[{(' | wc -c)
    local close_count
    close_count=$(echo "$diagram_content" | tr -cd ']})' | wc -c)

    if [[ $open_count -ne $close_count ]]; then
        errors+=("Unbalanced brackets: $open_count opening, $close_count closing")
    fi

    # Check for unclosed strings
    local quote_count
    quote_count=$(echo "$diagram_content" | tr -cd '"' | wc -c)
    if [[ $((quote_count % 2)) -ne 0 ]]; then
        errors+=("Unclosed string literal")
    fi

    # Type-specific validation
    case "$diagram_type" in
        flowchart|graph)
            # Check for arrow syntax
            if ! [[ "$diagram_content" =~ (-->|---|==>|-.->|--o|--x) ]]; then
                errors+=("No valid arrow syntax found in flowchart")
            fi
            ;;
        sequenceDiagram)
            # Check for participant declaration
            if ! [[ "$diagram_content" =~ participant ]]; then
                errors+=("No participant declaration in sequence diagram")
            fi
            ;;
        classDiagram)
            # Check for class declaration
            if ! [[ "$diagram_content" =~ class[[:space:]] ]]; then
                errors+=("No class declaration in class diagram")
            fi
            ;;
        *)
            # Generic validation for other types
            ;;
    esac

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Validate diagram syntax with mermaid CLI
validate_diagram_syntax() {
    local diagram_content="$1"
    local temp_file="${2:-}"

    # If mermaid CLI is not available, use fallback
    if ! command -v mmdc &>/dev/null; then
        validate_diagram_syntax_fallback "$diagram_content"
        return $?
    fi

    # Create temp file if not provided
    if [[ -z "$temp_file" ]]; then
        temp_file=$(mktemp)
        echo "$diagram_content" > "$temp_file"
    fi

    # Validate with mermaid CLI
    local output
    if output=$(mmdc -i "$temp_file" -o /dev/null -t dark 2>&1); then
        [[ -z "${2:-}" ]] && rm -f "$temp_file"
        return 0
    else
        # Parse error message
        local error_msg="${output##*Error: }"
        echo "Syntax error: $error_msg"
        [[ -z "${2:-}" ]] && rm -f "$temp_file"
        return 1
    fi
}

# Validate diagram type
validate_diagram_type() {
    local diagram_content="$1"
    local detected_type=""

    # Extract diagram type
    for type in "${SUPPORTED_DIAGRAM_TYPES[@]}"; do
        if [[ "$diagram_content" =~ ^[[:space:]]*$type ]]; then
            detected_type="$type"
            break
        fi
    done

    if [[ -z "$detected_type" ]]; then
        echo "Unknown or missing diagram type"
        return 1
    fi

    echo "$detected_type"
    return 0
}

# Validate diagram complexity
validate_diagram_complexity() {
    local diagram_content="$1"
    local max_complexity="${2:-50}"

    # Count nodes (simplified)
    local node_count=0

    # Count different node indicators
    node_count=$((node_count + $(echo "$diagram_content" | grep -c '\[.*\]')))
    node_count=$((node_count + $(echo "$diagram_content" | grep -c '(.*)')))
    node_count=$((node_count + $(echo "$diagram_content" | grep -c '{.*}')))
    node_count=$((node_count + $(echo "$diagram_content" | grep -c '|.*|')))

    # Count connections
    local connection_count=0
    connection_count=$((connection_count + $(echo "$diagram_content" | grep -c -- '-->')))
    connection_count=$((connection_count + $(echo "$diagram_content" | grep -c -- '---')))
    connection_count=$((connection_count + $(echo "$diagram_content" | grep -c -- '==>')))
    connection_count=$((connection_count + $(echo "$diagram_content" | grep -c -- '-.->')))

    local total_complexity=$((node_count + connection_count))

    if [[ $total_complexity -gt $max_complexity ]]; then
        echo "Diagram too complex: $total_complexity elements (max: $max_complexity)"
        return 1
    fi

    echo "Complexity: $total_complexity elements"
    return 0
}

# Validate accessibility attributes
validate_accessibility() {
    local diagram_content="$1"
    local warnings=()

    # Check for title
    if ! [[ "$diagram_content" =~ title[[:space:]]*: ]] && \
       ! [[ "$diagram_content" =~ accTitle[[:space:]]*: ]]; then
        warnings+=("Missing title attribute for screen readers")
    fi

    # Check for description
    if ! [[ "$diagram_content" =~ accDescr[[:space:]]*: ]] && \
       ! [[ "$diagram_content" =~ description[[:space:]]*: ]]; then
        warnings+=("Missing description attribute for accessibility")
    fi

    # Check for meaningful node labels
    if [[ "$diagram_content" =~ \[\ *\] ]] || \
       [[ "$diagram_content" =~ \(\ *\) ]]; then
        warnings+=("Empty node labels detected")
    fi

    # Check for color-only information
    if [[ "$diagram_content" =~ style.*fill:#[0-9a-fA-F]+ ]] || \
       [[ "$diagram_content" =~ style.*stroke:#[0-9a-fA-F]+ ]]; then
        warnings+=("Using color styling - ensure information is not conveyed by color alone")
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        printf '%s\n' "${warnings[@]}"
        return 1
    fi

    return 0
}

# Check for common Mermaid errors
check_common_errors() {
    local diagram_content="$1"
    local errors=()

    # Check for tab characters (can cause parsing issues)
    if [[ "$diagram_content" =~ $'\t' ]]; then
        errors+=("Contains tab characters - use spaces instead")
    fi

    # Check for smart quotes
    if [[ "$diagram_content" =~ [""''] ]]; then
        errors+=("Contains smart quotes - use straight quotes")
    fi

    # Check for missing semicolons in certain contexts
    if [[ "$diagram_content" =~ classDiagram ]]; then
        # Check for class declarations without proper termination
        if echo "$diagram_content" | grep -qE 'class [^;]+$'; then
            errors+=("Missing semicolon in class diagram")
        fi
    fi

    # Check for invalid characters in IDs
    if [[ "$diagram_content" =~ [[:space:]][0-9]+[[:space:]]--  ]]; then
        errors+=("Node ID starts with number - use letters first")
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    return 0
}

# Export functions
export -f validate_diagram_syntax_fallback
export -f validate_diagram_syntax
export -f validate_diagram_type
export -f validate_diagram_complexity
export -f validate_accessibility
export -f check_common_errors