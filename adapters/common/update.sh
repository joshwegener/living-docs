#!/bin/bash

# Common Update Script for Adapters
# Handles backing up and updating adapter installations

set -e

update_adapter() {
    local adapter_name="$1"
    local project_root="${2:-.}"
    # Get the directory of this script
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # The adapter directory is in the parent of common/
    local adapter_dir="$(dirname "$script_dir")/$adapter_name"

    if [ ! -d "$adapter_dir" ]; then
        echo "❌ Adapter not found: $adapter_name"
        return 1
    fi

    echo "🔄 Updating $adapter_name..."

    # Load adapter config
    if [ ! -f "$adapter_dir/config.yml" ]; then
        echo "❌ No config.yml found for $adapter_name"
        return 1
    fi

    # Check if adapter is installed
    if ! grep -q "$adapter_name" "$project_root/.living-docs.config" 2>/dev/null; then
        echo "❌ $adapter_name is not installed in this project"
        return 1
    fi

    # Create backup directory
    BACKUP_DIR="$project_root/.living-docs-backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    echo "  Creating backup in $BACKUP_DIR"

    # Backup current installation based on adapter type
    case "$adapter_name" in
        aider)
            [ -f "$project_root/CONVENTIONS.md" ] && cp "$project_root/CONVENTIONS.md" "$BACKUP_DIR/"
            ;;
        cursor)
            [ -f "$project_root/.cursorrules" ] && cp "$project_root/.cursorrules" "$BACKUP_DIR/"
            ;;
        continue)
            [ -f "$project_root/.continuerules" ] && cp "$project_root/.continuerules" "$BACKUP_DIR/"
            ;;
        spec-kit)
            # Backup spec-kit directories (using default paths if not configured)
            source "$project_root/.living-docs.config" 2>/dev/null || true
            # Default paths for spec-kit
            MEMORY_PATH="${MEMORY_PATH:-.claude}"
            SCRIPTS_PATH="${SCRIPTS_PATH:-scripts}"
            # Only backup if they exist and exclude backup directory itself
            if [ -d "$project_root/$MEMORY_PATH" ]; then
                rsync -a --exclude=".living-docs-backups" "$project_root/$MEMORY_PATH" "$BACKUP_DIR/" 2>/dev/null || \
                    cp -r "$project_root/$MEMORY_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            fi
            if [ -d "$project_root/$SCRIPTS_PATH" ]; then
                rsync -a --exclude=".living-docs-backups" "$project_root/$SCRIPTS_PATH" "$BACKUP_DIR/" 2>/dev/null || \
                    cp -r "$project_root/$SCRIPTS_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            fi
            ;;
        agent-os)
            # Backup agent-os structure
            source "$project_root/.living-docs.config" 2>/dev/null || true
            AGENT_OS_PATH="${AGENT_OS_PATH:-.agent-os}"
            [ -d "$project_root/$AGENT_OS_PATH" ] && cp -r "$project_root/$AGENT_OS_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            ;;
        bmad-method)
            # Backup BMAD configuration
            source "$project_root/.living-docs.config" 2>/dev/null || true
            BMAD_PATH="${BMAD_PATH:-.bmad}"
            [ -d "$project_root/$BMAD_PATH" ] && cp -r "$project_root/$BMAD_PATH" "$BACKUP_DIR/" 2>/dev/null || true
            ;;
    esac

    # Run adapter's install script (it will handle updates)
    echo "  Running update..."
    bash "$adapter_dir/install.sh" "$project_root"

    # Update version in config
    VERSION=$(grep "version:" "$adapter_dir/config.yml" | cut -d: -f2 | tr -d ' ')
    # Convert adapter name to uppercase for version variable
    VERSION_VAR="$(echo "$adapter_name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_VERSION"
    sed -i.bak "s/${VERSION_VAR}=.*/${VERSION_VAR}=\"$VERSION\"/" "$project_root/.living-docs.config"
    rm -f "$project_root/.living-docs.config.bak"

    echo "✅ $adapter_name updated to version $VERSION"
    echo "  Backup saved in: $BACKUP_DIR"

    return 0
}

# Function to update all installed adapters
update_all_adapters() {
    local project_root="${1:-.}"

    if [ ! -f "$project_root/.living-docs.config" ]; then
        echo "❌ No .living-docs.config found. Is living-docs installed?"
        return 1
    fi

    source "$project_root/.living-docs.config"

    if [ -z "$INSTALLED_SPECS" ]; then
        echo "❌ No adapters installed"
        return 1
    fi

    echo "📦 Updating all installed adapters..."
    echo "  Installed: $INSTALLED_SPECS"
    echo ""

    # Update each installed adapter
    for adapter in $INSTALLED_SPECS; do
        update_adapter "$adapter" "$project_root"
        echo ""
    done

    echo "✅ All adapters updated successfully!"
}

# Function to check for available updates
check_updates() {
    local project_root="${1:-.}"

    if [ ! -f "$project_root/.living-docs.config" ]; then
        echo "❌ No .living-docs.config found"
        return 1
    fi

    source "$project_root/.living-docs.config"

    echo "🔍 Checking for adapter updates..."
    echo ""

    for adapter in $INSTALLED_SPECS; do
        # Get the directory of this script
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # The adapter directory is in the parent of common/
        ADAPTER_DIR="$(dirname "$script_dir")/$adapter"
        if [ -f "$ADAPTER_DIR/config.yml" ]; then
            LATEST_VERSION=$(grep "version:" "$ADAPTER_DIR/config.yml" | cut -d: -f2 | tr -d ' ')
            # Convert adapter name to uppercase for version variable
            CURRENT_VERSION_VAR="$(echo "$adapter" | tr '[:lower:]' '[:upper:]' | tr '-' '_')_VERSION"
            CURRENT_VERSION="${!CURRENT_VERSION_VAR:-unknown}"

            if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
                echo "  📦 $adapter: $CURRENT_VERSION → $LATEST_VERSION (update available)"
            else
                echo "  ✅ $adapter: $CURRENT_VERSION (up to date)"
            fi
        fi
    done
}

# Export functions
export -f update_adapter
export -f update_all_adapters
export -f check_updates