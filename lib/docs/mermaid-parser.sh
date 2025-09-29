#!/usr/bin/env bash
# Mermaid diagram parser module
set -euo pipefail

# Source common libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/errors.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../common/logging.sh" 2>/dev/null || true

# Extract Mermaid diagrams from markdown files
extract_mermaid_diagrams() {
    local file="$1"
    local diagrams=()
    local in_mermaid=false
    local current_diagram=""
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for mermaid code block start
        if [[ "$line" =~ ^\`\`\`mermaid ]]; then
            in_mermaid=true
            current_diagram=""
            continue
        fi

        # Check for code block end
        if [[ "$in_mermaid" == true ]] && [[ "$line" =~ ^\`\`\` ]]; then
            in_mermaid=false
            if [[ -n "$current_diagram" ]]; then
                diagrams+=("LINE:$line_num|CONTENT:$current_diagram")
            fi
            continue
        fi

        # Accumulate diagram content
        if [[ "$in_mermaid" == true ]]; then
            if [[ -n "$current_diagram" ]]; then
                current_diagram+=$'\n'
            fi
            current_diagram+="$line"
        fi
    done < "$file"

    # Output diagrams
    printf '%s\n' "${diagrams[@]}"
}

# Parse diagram metadata
parse_diagram_metadata() {
    local diagram_content="$1"
    local metadata=()

    # Extract title
    if [[ "$diagram_content" =~ title[[:space:]]*:[[:space:]]*([^$'\n']+) ]]; then
        metadata+=("title:${BASH_REMATCH[1]}")
    elif [[ "$diagram_content" =~ accTitle[[:space:]]*:[[:space:]]*([^$'\n']+) ]]; then
        metadata+=("title:${BASH_REMATCH[1]}")
    fi

    # Extract description
    if [[ "$diagram_content" =~ accDescr[[:space:]]*:[[:space:]]*([^$'\n']+) ]]; then
        metadata+=("description:${BASH_REMATCH[1]}")
    elif [[ "$diagram_content" =~ description[[:space:]]*:[[:space:]]*([^$'\n']+) ]]; then
        metadata+=("description:${BASH_REMATCH[1]}")
    fi

    # Extract diagram type
    local diagram_type=""
    if [[ "$diagram_content" =~ ^[[:space:]]*(flowchart|graph|sequenceDiagram|classDiagram|stateDiagram|erDiagram|journey|gantt|pie|gitgraph|requirement|mindmap|timeline|sankey|block|architecture) ]]; then
        diagram_type="${BASH_REMATCH[1]}"
        metadata+=("type:$diagram_type")
    fi

    printf '%s\n' "${metadata[@]}"
}

# Extract nodes from diagram
extract_nodes() {
    local diagram_content="$1"
    local nodes=()

    # Extract different node formats
    # Format: [text]
    while read -r node; do
        [[ -n "$node" ]] && nodes+=("square:$node")
    done < <(echo "$diagram_content" | grep -o '\[[^]]*\]' | sed 's/\[\(.*\)\]/\1/')

    # Format: (text)
    while read -r node; do
        [[ -n "$node" ]] && nodes+=("round:$node")
    done < <(echo "$diagram_content" | grep -o '([^)]*)'  | sed 's/(\(.*\))/\1/')

    # Format: {text}
    while read -r node; do
        [[ -n "$node" ]] && nodes+=("diamond:$node")
    done < <(echo "$diagram_content" | grep -o '{[^}]*}'  | sed 's/{\(.*\)}/\1/')

    # Format: |text|
    while read -r node; do
        [[ -n "$node" ]] && nodes+=("cylinder:$node")
    done < <(echo "$diagram_content" | grep -o '|[^|]*|'  | sed 's/|\(.*\)|/\1/')

    printf '%s\n' "${nodes[@]}"
}

# Extract connections from diagram
extract_connections() {
    local diagram_content="$1"
    local connections=()

    # Arrow types
    local -a arrow_patterns=(
        "--->"
        "---"
        "==>"
        "-.->"
        "-->"
        "-..-"
        "=="
        "--o"
        "--x"
        "o--o"
        "x--x"
    )

    for pattern in "${arrow_patterns[@]}"; do
        while read -r line; do
            if [[ -n "$line" ]]; then
                connections+=("$pattern:$line")
            fi
        done < <(echo "$diagram_content" | grep -F "$pattern")
    done

    printf '%s\n' "${connections[@]}"
}

# Parse subgraphs
parse_subgraphs() {
    local diagram_content="$1"
    local subgraphs=()
    local in_subgraph=false
    local subgraph_name=""
    local subgraph_content=""

    while IFS= read -r line; do
        # Check for subgraph start
        if [[ "$line" =~ subgraph[[:space:]]+([^[:space:]]+) ]]; then
            in_subgraph=true
            subgraph_name="${BASH_REMATCH[1]}"
            subgraph_content=""
            continue
        fi

        # Check for subgraph end
        if [[ "$in_subgraph" == true ]] && [[ "$line" =~ ^[[:space:]]*end ]]; then
            in_subgraph=false
            if [[ -n "$subgraph_content" ]]; then
                subgraphs+=("NAME:$subgraph_name|CONTENT:$subgraph_content")
            fi
            continue
        fi

        # Accumulate subgraph content
        if [[ "$in_subgraph" == true ]]; then
            if [[ -n "$subgraph_content" ]]; then
                subgraph_content+=$'\n'
            fi
            subgraph_content+="$line"
        fi
    done <<< "$diagram_content"

    printf '%s\n' "${subgraphs[@]}"
}

# Parse styles and classes
parse_styles() {
    local diagram_content="$1"
    local styles=()

    # Extract class definitions
    while read -r class_def; do
        [[ -n "$class_def" ]] && styles+=("class:$class_def")
    done < <(echo "$diagram_content" | grep -o 'class [^;]*')

    # Extract style definitions
    while read -r style_def; do
        [[ -n "$style_def" ]] && styles+=("style:$style_def")
    done < <(echo "$diagram_content" | grep -o 'style [^;]*')

    # Extract classDef definitions
    while read -r classdef; do
        [[ -n "$classdef" ]] && styles+=("classDef:$classdef")
    done < <(echo "$diagram_content" | grep -o 'classDef [^;]*')

    printf '%s\n' "${styles[@]}"
}

# Parse sequence diagram specifics
parse_sequence_elements() {
    local diagram_content="$1"
    local elements=()

    # Extract participants
    while read -r participant; do
        [[ -n "$participant" ]] && elements+=("participant:$participant")
    done < <(echo "$diagram_content" | grep -o 'participant [^$'\n']*')

    # Extract actors
    while read -r actor; do
        [[ -n "$actor" ]] && elements+=("actor:$actor")
    done < <(echo "$diagram_content" | grep -o 'actor [^$'\n']*')

    # Extract notes
    while read -r note; do
        [[ -n "$note" ]] && elements+=("note:$note")
    done < <(echo "$diagram_content" | grep -o 'Note [^:]*:[^$'\n']*')

    # Extract loops
    while read -r loop; do
        [[ -n "$loop" ]] && elements+=("loop:$loop")
    done < <(echo "$diagram_content" | grep -o 'loop [^$'\n']*')

    printf '%s\n' "${elements[@]}"
}

# Count diagram elements
count_diagram_elements() {
    local diagram_content="$1"
    local counts=()

    # Count nodes
    local node_count
    node_count=$(extract_nodes "$diagram_content" | wc -l)
    counts+=("nodes:$node_count")

    # Count connections
    local connection_count
    connection_count=$(extract_connections "$diagram_content" | wc -l)
    counts+=("connections:$connection_count")

    # Count subgraphs
    local subgraph_count
    subgraph_count=$(parse_subgraphs "$diagram_content" | wc -l)
    counts+=("subgraphs:$subgraph_count")

    # Count styles
    local style_count
    style_count=$(parse_styles "$diagram_content" | wc -l)
    counts+=("styles:$style_count")

    printf '%s\n' "${counts[@]}"
}

# Export functions
export -f extract_mermaid_diagrams
export -f parse_diagram_metadata
export -f extract_nodes
export -f extract_connections
export -f parse_subgraphs
export -f parse_styles
export -f parse_sequence_elements
export -f count_diagram_elements