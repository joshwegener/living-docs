# Living-Docs Multi-Spec Adapter System

## Overview

The adapter system allows you to install and use multiple specification frameworks simultaneously in your project. Each framework brings its own methodology while respecting your chosen directory structure.

## Supported Frameworks

### 1. 📝 Aider (`aider`)
- **File**: `CONVENTIONS.md`
- **Purpose**: AI coding conventions for Aider
- **Location**: Project root (always)
- **Complexity**: Simple

### 2. 🎯 Cursor (`cursor`)
- **File**: `.cursorrules`
- **Purpose**: Rules for Cursor IDE AI assistance
- **Location**: Project root (always)
- **Complexity**: Simple

### 3. 🚀 Continue (`continue`)
- **File**: `.continuerules`
- **Purpose**: Rules for Continue.dev AI
- **Location**: Project root (always)
- **Complexity**: Simple

### 4. 📋 Spec-Kit (`spec-kit`)
- **Files**: Multiple directories
- **Purpose**: GitHub's specification-driven development
- **Location**: Customizable (memory/, specs/, scripts/)
- **Complexity**: Medium
- **Features**: Constitution, spec templates, scripts

### 5. 🤖 Agent OS (`agent-os`)
- **Files**: Dated specification folders
- **Purpose**: Standards/Product/Specs methodology
- **Location**: Customizable (.agent-os/ or custom)
- **Complexity**: Medium
- **Features**: Dated folders (2025-09-16-feature/)

### 6. 🚀 BMAD-Method (`bmad-method`)
- **Files**: Multi-agent templates
- **Purpose**: Multi-agent development system
- **Location**: Customizable
- **Complexity**: High
- **Requirements**: Node.js 20+ (optional but recommended)
- **Features**: 5 specialized agents (Analyst, PM, Architect, Developer, QA)

## Installation

### Individual Adapter
```bash
cd adapters/[adapter-name]
./install.sh /path/to/project
```

### Multiple Adapters (via wizard - coming soon)
```bash
./wizard.sh
# Select multiple frameworks with checkboxes
```

## Path Customization

The system supports custom installation paths:

```bash
# During wizard installation, choose:
1) .claude/      # Recommended for Claude
2) .github/      # GitHub-friendly
3) docs/         # Traditional
4) .docs/        # Hidden
5) Custom path   # Your choice
```

### Path Variables
- `{{LIVING_DOCS_PATH}}` - Base documentation path
- `{{AI_PATH}}` - AI assistant files location
- `{{SPECS_PATH}}` - Specifications directory
- `{{MEMORY_PATH}}` - Memory/constitution files
- `{{SCRIPTS_PATH}}` - Script files location

## Updates

### Check for Updates
```bash
./adapters/update-all.sh
```

### Update Single Adapter
```bash
./adapters/[adapter-name]/update.sh
```

### Update All Adapters
```bash
./adapters/update-all.sh
# Choose 'y' when prompted
```

Updates will:
- Back up current installation
- Preserve customizations where possible
- Update to latest adapter version
- Track versions in `.living-docs.config`

## Configuration

The system tracks installed adapters in `.living-docs.config`:

```bash
INSTALLED_SPECS="spec-kit agent-os aider cursor"
SPEC_KIT_VERSION="2.0.0"
AGENT_OS_VERSION="1.0.0"
AIDER_VERSION="1.0.0"
CURSOR_VERSION="1.0.0"
LIVING_DOCS_PATH=".claude"
AI_PATH=".claude"
SPECS_PATH=".claude/specs"
MEMORY_PATH=".claude/memory"
```

## Combining Frameworks

You can use multiple frameworks together:

### Example 1: Spec-Kit + Aider + Cursor
- Use Spec-Kit's specification structure
- Apply Aider's conventions for AI coding
- Add Cursor rules for IDE assistance

### Example 2: Agent-OS + BMAD
- Use Agent-OS dated folders for specs
- Apply BMAD's multi-agent approach
- Combine methodologies for complex projects

### Example 3: Lightweight Stack
- Just Aider + Cursor + Continue
- Minimal setup, maximum AI assistance
- No complex directory structures

## Node.js Requirement (BMAD only)

BMAD-Method requires Node.js 20+ for multi-agent functionality:

### Automatic Detection
The installer will:
1. Check for Node.js
2. Offer installation options if missing:
   - Install via nvm (recommended)
   - Install via Homebrew (macOS)
   - Skip (limited functionality)

### Manual Installation
```bash
# Via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20

# Via Homebrew (macOS)
brew install node@20
```

## Conflict Resolution

The system prevents conflicts by:
- Each adapter claiming specific directories
- Checking for conflicts before installation
- Using unique file names/paths
- Supporting parallel installations

## Development

### Adding a New Adapter

1. Create directory: `adapters/new-adapter/`
2. Add required files:
   - `config.yml` - Adapter metadata
   - `install.sh` - Installation script
   - `update.sh` - Update script
   - `templates/` - Files to install

3. Configure in `config.yml`:
```yaml
name: new-adapter
version: 1.0.0
description: Your adapter description
requires_path_rewrite: true/false
files:
  - source: templates/file.md
    dest: "{{AI_PATH}}/file.md"
```

### Path Rewriting

For adapters needing custom paths:
```bash
source adapters/common/path-rewrite.sh
rewrite_directory "$TEMP_DIR" "$LIVING_DOCS_PATH" ...
```

## Troubleshooting

### Adapter Not Installing
- Check file permissions: `chmod +x install.sh`
- Verify config.yml exists
- Check for path conflicts

### Path Issues
- Ensure .living-docs.config has correct paths
- Check sed compatibility (macOS vs Linux)
- Verify template placeholders

### Update Failures
- Check backup directory permissions
- Verify adapter version in config.yml
- Review .living-docs.config for corruption

## Best Practices

1. **Start Simple**: Begin with lightweight adapters (aider, cursor)
2. **Test Individually**: Install and test each adapter separately
3. **Document Choices**: Record why you chose specific frameworks
4. **Regular Updates**: Check for updates monthly
5. **Backup Before Major Changes**: Manual backup before experiments

## Support

For issues or questions:
1. Check adapter's README
2. Review installation logs
3. Verify requirements (Node.js for BMAD)
4. Check .living-docs.config for issues

---

*The adapter system is designed to be flexible and extensible. Each adapter is self-contained and can be developed independently.*