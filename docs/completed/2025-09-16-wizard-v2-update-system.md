# Wizard v2.0 and Update System Implementation

**Date**: 2025-09-16
**Status**: ✅ Complete

## Summary
Major overhaul of wizard.sh to v2.1.0 with intelligent detection, preview mode, and complete update system.

## What Was Completed

### Wizard v2.0 Features
- **Intelligent AI Detection**: Auto-detects Claude, OpenAI, Cursor, Copilot, Windsurf, Continue, Cody, JetBrains, Amazon Q
- **Environment Detection**: Finds existing docs, spec systems, and configurations
- **Preview Mode**: Shows exactly what will be created before doing it
- **Bootstrap Injection**: Automatically adds `@docs/bootstrap.md` reference to AI files
- **Custom Spec Locations**: Spec-kit can install to `.openai/`, `.cursor/`, etc. for non-GitHub projects
- **Fixed ASCII Art**: Proper centering and alignment
- **Update Mode**: Check and restore missing spec-kit files
- **Auto-update Settings**: Daily/weekly/monthly frequency configuration

### Update System (update.sh)
- **Self-Updating**: update.sh updates itself first, then restarts
- **Version Tracking**: Semantic versioning comparison
- **Smart Updates**: Only updates if newer versions available
- **Template Updates**: Downloads latest spec-kit templates
- **Structure Migration**: Handles changes in directory structure
- **Preserves Customizations**: Backs up before updating
- **Helper Script Updates**: Updates check-drift.sh, pre-commit hooks, etc.

### Installation System (install.sh)
- **Always Latest**: Downloads current wizard.sh and update.sh from GitHub
- **Simple Command**: One curl command to get started
- **Works for Both**: New installations and existing projects

## Technical Implementation

### Version Tracking
- wizard.sh has `WIZARD_VERSION="2.1.0"`
- update.sh has `UPDATE_SCRIPT_VERSION="1.0.0"`
- Semantic version comparison for intelligent updates

### Update Flow
1. User runs `./wizard.sh` on existing project
2. Menu offers "Check for all updates"
3. Downloads and runs update.sh
4. update.sh self-updates if needed
5. Updates wizard.sh, templates, scripts
6. Preserves all customizations

### Key Files
- `wizard.sh` - Main wizard with all features
- `update.sh` - Update system with self-update
- `install.sh` - Fresh installation script
- `adapters/spec-kit.sh` - Spec-kit adapter with custom location support

## Testing Completed
- Fresh installations work perfectly
- Update detection finds missing files
- Spec-kit restores to custom locations
- Self-update mechanism tested
- Version comparison works correctly
- GitHub downloads successful

## Lessons Learned
1. Don't create multiple versions of files (wizard-v2.sh) - Git tracks history
2. Self-updating scripts need to download to temp file first
3. curl -s flag can cause silent failures - redirect stderr instead
4. Version tracking essential for proper updates
5. Always test end-to-end from GitHub, not just locally

## Impact
Users can now easily keep living-docs current as the project rapidly evolves. The update system ensures they get new features, bug fixes, and template updates without losing their customizations.