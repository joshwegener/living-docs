# Quickstart: Robust Adapter Installation

## Overview
This guide demonstrates the new robust adapter installation system that prevents conflicts, tracks installations, and safely handles updates.

## Prerequisites
- living-docs installed (`wizard.sh` available)
- Git installed
- Bash 3.2+ (macOS or Linux)

## Quick Test Scenarios

### 1. Safe Installation with Conflict Detection
```bash
# Install adapter with automatic conflict resolution
./wizard.sh

# Select option 2 (Install framework adapter)
# Choose spec-kit
# System will:
# - Detect existing commands
# - Automatically prefix conflicts
# - Create tracking manifest

# Verify installation
ls .claude/commands/speckit_*.md
cat adapters/spec-kit/.living-docs-manifest.json
```

### 2. Custom Path Installation
```bash
# Set custom paths
export SCRIPTS_PATH="./my-scripts"
export SPECS_PATH="./my-specs"

# Install adapter
./wizard.sh

# Verify path rewriting
grep "my-scripts" .claude/commands/speckit_*.md
```

### 3. Complete Adapter Removal
```bash
# Remove an adapter completely
./wizard.sh

# Select option 3 (Remove adapter)
# Choose spec-kit
# System will:
# - Read manifest
# - Remove all tracked files
# - Clean up empty directories

# Verify removal
ls .claude/commands/speckit_*.md 2>/dev/null || echo "Commands removed ✓"
ls adapters/spec-kit/.living-docs-manifest.json 2>/dev/null || echo "Manifest removed ✓"
```

### 4. Update with Customization Preservation
```bash
# Install and customize
./wizard.sh  # Install spec-kit
echo "# My custom notes" >> .claude/commands/speckit_plan.md

# Update adapter
./wizard.sh

# Select option 4 (Check for updates)
# System will:
# - Detect customized files
# - Show diff for review
# - Preserve your changes
# - Update other files

# Verify customization preserved
grep "My custom notes" .claude/commands/speckit_plan.md
```

### 5. Multi-Adapter Installation
```bash
# Install multiple adapters without conflicts
./wizard.sh  # Install spec-kit
./wizard.sh  # Install aider
./wizard.sh  # Install bmad

# Verify no conflicts
ls .claude/commands/ | sort | uniq -d  # Should be empty
```

## Validation Commands

### Check Installation Health
```bash
# Verify manifest exists and is valid
for adapter in adapters/*/; do
    if [[ -f "$adapter/.living-docs-manifest.json" ]]; then
        echo "✓ $(basename $adapter) has manifest"
        jq -r '.version' "$adapter/.living-docs-manifest.json"
    fi
done
```

### Verify Path Rewriting
```bash
# Check for hardcoded paths (should find none)
grep -r "scripts/bash/" .claude/commands/ 2>/dev/null || echo "✓ No hardcoded paths"
```

### List Installed Adapters
```bash
# Show all installed adapters with versions
for manifest in adapters/*/.living-docs-manifest.json; do
    adapter=$(jq -r '.adapter' "$manifest")
    version=$(jq -r '.version' "$manifest")
    files=$(jq -r '.files | length' "$manifest")
    echo "$adapter v$version ($files files)"
done
```

## Common Operations

### Force Reinstall
```bash
# Remove and reinstall fresh
./wizard.sh  # Remove adapter
./wizard.sh  # Install adapter
```

### Check for Conflicts Before Installation
```bash
# Dry run to see what would conflict
LIVING_DOCS_DRY_RUN=1 ./wizard.sh
```

### Install Without Prefixing
```bash
# For single-adapter users who want clean names
LIVING_DOCS_NO_PREFIX=1 ./wizard.sh
```

## Troubleshooting

### Issue: Installation Failed
```bash
# Check temp directory for partial installation
ls -la ./tmp/
# Clean up and retry
rm -rf ./tmp/*
./wizard.sh
```

### Issue: Customizations Lost
```bash
# Restore from manifest backup
cp adapters/spec-kit/.living-docs-manifest.json.backup \
   adapters/spec-kit/.living-docs-manifest.json
```

### Issue: Conflicting Commands
```bash
# List all command files by adapter
for cmd in .claude/commands/*.md; do
    echo "$(basename $cmd): $(head -1 "$cmd" | grep -o 'adapter: [^ ]*' || echo 'unknown')"
done | sort
```

## Success Criteria
- ✓ Adapters install without conflicts
- ✓ Custom paths are properly rewritten
- ✓ Removal is complete (no orphan files)
- ✓ Updates preserve customizations
- ✓ Multiple adapters coexist peacefully

## Next Steps
After validation:
1. Install your preferred adapters
2. Customize as needed (changes are tracked)
3. Run updates periodically for bug fixes
4. Remove unused adapters to keep project clean

---
*This quickstart validates all acceptance scenarios from the specification*