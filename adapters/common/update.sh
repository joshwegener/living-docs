#!/bin/bash

# Common Update Script for Adapters
# Handles backing up and updating adapter installations

set -e

update_adapter() {
    local adapter_name="$1"
    local project_root="${2:-.}"
    local adapter_dir="$(dirname "$0")/../$adapter_name"

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
            # Backup spec-kit directories
            source "$project_root/.living-docs.config"
            [ -d "$project_root/$MEMORY_PATH" ] && cp -r "$project_root/$MEMORY_PATH" "$BACKUP_DIR/"
            [ -d "$project_root/$SCRIPTS_PATH" ] && cp -r "$project_root/$SCRIPTS_PATH" "$BACKUP_DIR/"
            ;;
        agent-os)
            # Backup agent-os structure
            source "$project_root/.living-docs.config"
            [ -d "$project_root/$AGENT_OS_PATH" ] && cp -r "$project_root/$AGENT_OS_PATH" "$BACKUP_DIR/"
            ;;
        bmad-method)
            # Backup BMAD configuration
            source "$project_root/.living-docs.config"
            [ -d "$project_root/$BMAD_PATH" ] && cp -r "$project_root/$BMAD_PATH" "$BACKUP_DIR/"
            ;;
    esac

    # Run adapter's install script (it will handle updates)
    echo "  Running update..."
    bash "$adapter_dir/install.sh" "$project_root"

    # Update version in config
    VERSION=$(grep "version:" "$adapter_dir/config.yml" | cut -d: -f2 | tr -d ' ')
    sed -i.bak "s/${adapter_name^^}_VERSION=.*/${adapter_name^^}_VERSION=\"$VERSION\"/" "$project_root/.living-docs.config"
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
        ADAPTER_DIR="$(dirname "$0")/../$adapter"
        if [ -f "$ADAPTER_DIR/config.yml" ]; then
            LATEST_VERSION=$(grep "version:" "$ADAPTER_DIR/config.yml" | cut -d: -f2 | tr -d ' ')
            CURRENT_VERSION_VAR="${adapter^^}_VERSION"
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