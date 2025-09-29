#!/bin/bash
set -euo pipefail
# Agent Template Installation Functions for Adapter Installation System
# Handles installation of AI agents to various agent directories

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source required adapter libraries with safety checks
if [[ -f "$SCRIPT_DIR/../adapter/manifest.sh" ]]; then
    source "$SCRIPT_DIR/../adapter/manifest.sh"
fi
if [[ -f "$SCRIPT_DIR/../adapter/prefix.sh" ]]; then
    source "$SCRIPT_DIR/../adapter/prefix.sh"
fi

# AI tool detection mappings (bash 3.2 compatible)
# Get agents directory for a tool
get_tool_agents_dir() {
    local tool="$1"
    case "$tool" in
        claude) echo ".claude/agents" ;;
        cursor) echo ".cursor/agents" ;;
        copilot) echo ".github/copilot-agents" ;;
        continue) echo ".continue/agents" ;;
        aider) echo ".aider/agents" ;;
        agent-os|open-interpreter) echo "agents" ;;
        *) return 1 ;;
    esac
}

# Get detection pattern for a tool
get_tool_pattern() {
    local tool="$1"
    case "$tool" in
        claude) echo ".claude" ;;
        cursor) echo ".cursor" ;;
        copilot) echo ".github/copilot" ;;
        continue) echo ".continue" ;;
        aider) echo ".aider" ;;
        agent-os) echo "agent-os.yml" ;;
        open-interpreter) echo "interpreter" ;;
        *) return 1 ;;
    esac
}

# Main agent installation function
install_agents() {
    local adapter_name="$1"
    local source_dir="$2"
    local options="${3:-}"

    if [[ -z "$adapter_name" || -z "$source_dir" ]]; then
        echo "Error: adapter_name and source_dir required" >&2
        return 1
    fi

    # Parse options
    local dry_run=false
    local ai_tool=""
    local agents_dir=""
    local force=false

    for opt in $options; do
        case $opt in
            --dry-run) dry_run=true ;;
            --ai-tool=*) ai_tool="${opt#*=}" ;;
            --agents-dir=*) agents_dir="${opt#*=}" ;;
            --force) force=true ;;
        esac
    done

    echo "Installing agents for adapter: $adapter_name"

    # Check if source has agents
    local agents_source_dir="$source_dir/agents"
    if [[ ! -d "$agents_source_dir" ]]; then
        echo "No agents directory found in source"
        return 0
    fi

    # Detect AI tool if not specified
    if [[ -z "$ai_tool" ]]; then
        ai_tool=$(detect_ai_tool)
        if [[ -z "$ai_tool" ]]; then
            echo "Warning: Could not detect AI tool, using default (claude)"
            ai_tool="claude"
        fi
    fi

    echo "Detected AI tool: $ai_tool"

    # Determine agents directory
    local target_agents_dir
    if [[ -n "$agents_dir" ]]; then
        target_agents_dir="$agents_dir"
    else
        target_agents_dir=$(get_agents_dir "$ai_tool")
        if [[ -z "$target_agents_dir" ]]; then
            echo "Error: Could not determine agents directory for $ai_tool" >&2
            return 1
        fi
    fi

    echo "Target agents directory: $target_agents_dir"

    # Install agents
    if ! install_to_agents_dir "$adapter_name" "$agents_source_dir" "$target_agents_dir" "$dry_run" "$force"; then
        echo "Error: Failed to install agents" >&2
        return 1
    fi

    # Track in manifest if not dry run
    if [[ "$dry_run" != "true" ]]; then
        if ! track_in_manifest "$adapter_name" "$target_agents_dir"; then
            echo "Warning: Failed to track agents in manifest" >&2
        fi
    fi

    echo " Agents installed successfully"
    return 0
}

# Detect AI tool from environment and directory structure
detect_ai_tool() {
    local project_root="${PROJECT_ROOT:-$(pwd)}"

    # Check environment variables first
    if [[ -n "$CLAUDE_API_KEY" || -n "$ANTHROPIC_API_KEY" ]]; then
        if [[ -d "$project_root/.claude" ]]; then
            echo "claude"
            return 0
        fi
    fi

    if [[ -n "$OPENAI_API_KEY" ]]; then
        if [[ -d "$project_root/.github/copilot" ]]; then
            echo "copilot"
            return 0
        fi
    fi

    # Check for directory patterns
    for tool in claude cursor copilot continue aider agent-os open-interpreter; do
        local pattern
        pattern=$(get_tool_pattern "$tool")
        if [[ -n "$pattern" && -e "$project_root/$pattern" ]]; then
            echo "$tool"
            return 0
        fi
    done

    # Check for config files
    if [[ -f "$project_root/.cursor-tutor" ]]; then
        echo "cursor"
        return 0
    fi

    if [[ -f "$project_root/.aiderignore" ]]; then
        echo "aider"
        return 0
    fi

    if [[ -f "$project_root/.continue/config.json" ]]; then
        echo "continue"
        return 0
    fi

    # Default fallback
    return 1
}

# Get agents directory for specific AI tool
get_agents_dir() {
    local ai_tool="$1"

    if [[ -z "$ai_tool" ]]; then
        echo "Error: AI tool required" >&2
        return 1
    fi

    local agents_dir
    agents_dir=$(get_tool_agents_dir "$ai_tool")
    if [[ -z "$agents_dir" ]]; then
        echo "Error: Unknown AI tool: $ai_tool" >&2
        return 1
    fi

    echo "$agents_dir"
}

# Install agents to specific directory
install_to_agents_dir() {
    local adapter_name="$1"
    local source_dir="$2"
    local target_dir="$3"
    local dry_run="${4:-false}"
    local force="${5:-false}"

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local full_target_dir="$project_root/$target_dir"

    # Create target directory if needed
    if [[ "$dry_run" != "true" ]]; then
        mkdir -p "$full_target_dir"
    fi

    local agents_installed=0
    local errors=0

    # Process all agent files
    while IFS= read -r agent_file; do
        if [[ -f "$agent_file" ]]; then
            local agent_name
            agent_name=$(basename "$agent_file")
            local target_file="$full_target_dir/$agent_name"

            # Check for conflicts
            if [[ -f "$target_file" && "$force" != "true" ]]; then
                echo "  Conflict: $agent_name already exists (use --force to overwrite)"
                ((errors++))
                continue
            fi

            if [[ "$dry_run" == "true" ]]; then
                echo "  Would install: $agent_name"
            else
                # Copy agent file
                if cp "$agent_file" "$target_file"; then
                    echo "   Installed agent: $agent_name"
                    ((agents_installed++))

                    # Make executable if it's a script
                    if [[ "$agent_name" =~ \.(sh|py|js)$ ]]; then
                        chmod +x "$target_file"
                    fi
                else
                    echo "   Failed to install: $agent_name" >&2
                    ((errors++))
                fi
            fi
        fi
    done < <(find "$source_dir" -type f)

    if [[ "$dry_run" != "true" ]]; then
        echo "Installed $agents_installed agents with $errors errors"
    fi

    return $errors
}

# Track agents in manifest
track_in_manifest() {
    local adapter_name="$1"
    local agents_dir="$2"

    local project_root="${PROJECT_ROOT:-$(pwd)}"
    local full_agents_dir="$project_root/$agents_dir"

    if [[ ! -d "$full_agents_dir" ]]; then
        echo "Error: Agents directory not found: $full_agents_dir" >&2
        return 1
    fi

    # Add each agent to manifest
    while IFS= read -r agent_file; do
        if [[ -f "$agent_file" ]]; then
            local agent_name
            agent_name=$(basename "$agent_file")

            # Calculate checksum
            local checksum
            checksum=$(calculate_checksum "$agent_file")

            # Update manifest
            local relative_path="${agent_file#$project_root/}"
            update_manifest "$adapter_name" "$relative_path" "$checksum" "" "agent"

            # Add to agents array in manifest
            add_agent_to_manifest "$adapter_name" "$agent_name"

            echo "  Tracked agent: $agent_name"
        fi
    done < <(find "$full_agents_dir" -type f -name "*" 2>/dev/null)

    return 0
}

# Remove agents for adapter
remove_agents() {
    local adapter_name="$1"
    local dry_run="${2:-false}"

    echo "Removing agents for adapter: $adapter_name"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    # Get list of agent files from manifest
    local agent_files
    agent_files=$(awk '
    /"file_type"[[:space:]]*:[[:space:]]*"agent"/ {
        # Look backward for the file path
        for (i = NR-10; i < NR; i++) {
            if (line[i] ~ /"[^"]*"[[:space:]]*:[[:space:]]*{/) {
                gsub(/^[[:space:]]*"/, "", line[i])
                gsub(/"[[:space:]]*:[[:space:]]*{.*/, "", line[i])
                print line[i]
                break
            }
        }
    }
    { line[NR] = $0 }
    ' "$manifest_path")

    if [[ -z "$agent_files" ]]; then
        echo "No agents found for adapter $adapter_name"
        return 0
    fi

    local agents_removed=0
    local errors=0
    local project_root="${PROJECT_ROOT:-$(pwd)}"

    while IFS= read -r agent_path; do
        [[ -z "$agent_path" ]] && continue

        # Convert relative path to absolute
        if [[ ! "$agent_path" =~ ^/ ]]; then
            agent_path="$project_root/$agent_path"
        fi

        if [[ "$dry_run" == "true" ]]; then
            echo "  Would remove: $(basename "$agent_path")"
        else
            if [[ -f "$agent_path" ]]; then
                if rm "$agent_path"; then
                    echo "   Removed agent: $(basename "$agent_path")"
                    ((agents_removed++))
                else
                    echo "   Failed to remove: $(basename "$agent_path")" >&2
                    ((errors++))
                fi
            else
                echo "  - Agent not found: $(basename "$agent_path")"
            fi
        fi
    done <<< "$agent_files"

    if [[ "$dry_run" != "true" ]]; then
        echo "Removed $agents_removed agents with $errors errors"
    fi

    return $errors
}

# List agents for adapter
list_agents() {
    local adapter_name="$1"

    local manifest_path
    manifest_path=$(get_manifest_path "$adapter_name")

    if [[ ! -f "$manifest_path" ]]; then
        echo "Error: Manifest not found for adapter $adapter_name" >&2
        return 1
    fi

    echo "Agents for adapter: $adapter_name"

    # Get agents array from manifest
    local agents
    agents=$(awk '
    /"agents"[[:space:]]*:[[:space:]]*\[/ {
        getline
        while ($0 !~ /\]/ && getline) {
            gsub(/^[[:space:]]*"/, "")
            gsub(/".*/, "")
            if ($0 != "") print $0
        }
    }
    ' "$manifest_path")

    if [[ -z "$agents" ]]; then
        echo "  No agents installed"
        return 0
    fi

    while IFS= read -r agent_name; do
        [[ -z "$agent_name" ]] && continue
        echo "  - $agent_name"
    done <<< "$agents"
}

# Validate agent file
validate_agent() {
    local agent_file="$1"

    if [[ ! -f "$agent_file" ]]; then
        echo "Error: Agent file not found: $agent_file" >&2
        return 1
    fi

    local agent_name
    agent_name=$(basename "$agent_file")

    # Basic validation
    local errors=0

    # Check file extension
    case "$agent_name" in
        *.md|*.txt|*.sh|*.py|*.js|*.json|*.yml|*.yaml)
            # Valid extensions
            ;;
        *)
            echo "Warning: Unknown agent file type: $agent_name" >&2
            ;;
    esac

    # Check for minimum content
    if [[ ! -s "$agent_file" ]]; then
        echo "Error: Agent file is empty: $agent_name" >&2
        ((errors++))
    fi

    # Check for reasonable size (not too large)
    local file_size
    file_size=$(wc -c < "$agent_file" 2>/dev/null || echo 0)
    if [[ $file_size -gt 1048576 ]]; then  # 1MB
        echo "Warning: Agent file is very large: $agent_name (${file_size} bytes)" >&2
    fi

    return $errors
}

# Generate agent installation report
generate_agent_report() {
    local adapter_name="$1"
    local report_file="${2:-/dev/stdout}"

    {
        echo "Agent Installation Report"
        echo "========================"
        echo "Adapter: $adapter_name"
        echo "Date: $(date)"
        echo ""

        # Detected AI tools
        echo "Detected AI Tools:"
        for tool in claude cursor copilot continue aider agent-os open-interpreter; do
            local pattern
            pattern=$(get_tool_pattern "$tool")
            local project_root="${PROJECT_ROOT:-$(pwd)}"
            if [[ -n "$pattern" && -e "$project_root/$pattern" ]]; then
                local agents_dir
                agents_dir=$(get_tool_agents_dir "$tool")
                echo "  - $tool (agents: $agents_dir)"
                if [[ -n "$agents_dir" && -d "$project_root/$agents_dir" ]]; then
                    local agent_count
                    agent_count=$(find "$project_root/$agents_dir" -type f 2>/dev/null | wc -l)
                    echo "    Existing agents: $agent_count"
                fi
            fi
        done

        echo ""

        # Current agents for adapter
        echo "Current Agents:"
        list_agents "$adapter_name" | tail -n +2

    } > "$report_file"

    echo "$report_file"
}

# Export functions for use by other scripts
export -f install_agents
export -f detect_ai_tool
export -f get_agents_dir
export -f install_to_agents_dir
export -f track_in_manifest
export -f remove_agents
export -f list_agents
export -f validate_agent
export -f generate_agent_report