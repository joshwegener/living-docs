#!/bin/bash
# AI Assistant Detection and Command Installation Helper
# Used by adapters to install commands to AI-specific locations

# Detect which AI assistants are in use
detect_ai_assistants() {
    local detected=""

    # Claude detection
    if [ -d ".claude" ] || [ -f "CLAUDE.md" ] || [ -f ".claude/CLAUDE.md" ]; then
        detected="${detected}claude "
    fi

    # Cursor detection
    if [ -f ".cursorrules" ] || [ -d ".cursor" ]; then
        detected="${detected}cursor "
    fi

    # Aider detection
    if [ -f ".aider.conf.yml" ] || [ -d ".aider" ]; then
        detected="${detected}aider "
    fi

    # Continue detection
    if [ -f ".continuerules" ] || [ -d ".continue" ]; then
        detected="${detected}continue "
    fi

    # Agent-OS detection
    if [ -f "CONVENTIONS.md" ] || [ -f ".agent-os/CONVENTIONS.md" ]; then
        detected="${detected}agentos "
    fi

    echo "$detected"
}

# Get the command directory for a specific AI assistant
get_ai_command_dir() {
    local ai_type="$1"

    case "$ai_type" in
        claude)
            echo ".claude/commands"
            ;;
        cursor)
            echo ".cursor/commands"
            ;;
        aider)
            echo ".aider/commands"
            ;;
        continue)
            echo ".continue/commands"
            ;;
        agentos)
            echo ".agent-os/commands"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Install commands to AI-specific locations
install_ai_commands() {
    local source_dir="$1"
    local project_root="$2"

    if [ ! -d "$source_dir" ]; then
        return 1
    fi

    local detected_ais=$(detect_ai_assistants)

    for ai in $detected_ais; do
        local ai_cmd_dir=$(get_ai_command_dir "$ai")
        if [ -n "$ai_cmd_dir" ]; then
            local target_dir="$project_root/$ai_cmd_dir"

            echo "  Installing commands for $ai to $ai_cmd_dir"
            mkdir -p "$target_dir"

            # Copy all .md files from source to target
            if ls "$source_dir"/*.md >/dev/null 2>&1; then
                cp "$source_dir"/*.md "$target_dir/"

                # Track in manifest
                echo "commands:$ai:$target_dir" >> "$project_root/.living-docs.manifest"
            fi
        fi
    done
}

# Remove AI commands (for uninstall)
remove_ai_commands() {
    local project_root="$1"
    local manifest="$project_root/.living-docs.manifest"

    if [ ! -f "$manifest" ]; then
        return 0
    fi

    # Read manifest and remove command directories
    grep "^commands:" "$manifest" 2>/dev/null | while IFS=: read -r _ ai path; do
        if [ -d "$path" ]; then
            echo "  Removing $ai commands from $path"
            rm -rf "$path"
        fi
    done

    # Clean up manifest entries
    if [ -f "$manifest" ]; then
        grep -v "^commands:" "$manifest" > "$manifest.tmp" 2>/dev/null || true
        mv "$manifest.tmp" "$manifest"
    fi
}