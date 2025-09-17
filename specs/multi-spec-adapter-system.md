# Multi-Spec Adapter System Specification

**Status**: 🟡 In Development
**Version**: 0.1.0
**Created**: 2025-09-16

## Problem Statement
Current system only supports one spec framework at a time. Companies experimenting with AI-driven development need to:
- Test multiple frameworks simultaneously
- Mix and match features from different specs
- Avoid file conflicts between frameworks
- Maintain clean project structure

## Solution: Directory-Based Multi-Spec Support

### Core Architecture

```
adapters/
├── spec-kit/           # GitHub's spec-driven toolkit
│   ├── install.sh
│   ├── config.yml
│   ├── templates/
│   │   ├── memory/
│   │   ├── specs/
│   │   └── scripts/
│   └── README.md
│
├── bmad-method/        # BMAD multi-agent system
│   ├── install.sh
│   ├── config.yml
│   ├── templates/
│   │   ├── bmad-core/
│   │   └── expansion-packs/
│   └── README.md
│
├── agent-os/           # Agent OS dated specs
│   ├── install.sh
│   ├── config.yml
│   ├── templates/
│   │   └── .agent-os/
│   └── README.md
│
├── aider/              # Aider conventions
│   ├── install.sh
│   ├── config.yml
│   ├── templates/
│   │   └── CONVENTIONS.md
│   └── README.md
│
├── cursor/             # Cursor rules
│   ├── install.sh
│   ├── config.yml
│   ├── templates/
│   │   └── .cursorrules
│   └── README.md
│
└── continue/           # Continue.dev rules
    ├── install.sh
    ├── config.yml
    ├── templates/
    │   └── .continuerules
    └── README.md
```

### Configuration Tracking

`.living-docs.config` additions:
```bash
# Multiple specs can be active
INSTALLED_SPECS="spec-kit bmad-method aider"

# Track versions for updates
SPEC_VERSIONS="spec-kit:1.0.0 bmad-method:2.1.0 aider:1.0.0"

# Custom installation paths (if needed)
SPEC_KIT_PATH=".github"
BMAD_PATH="."
AGENT_OS_PATH=".agent-os"
```

### Installation Flow

1. **Discovery Phase**
   ```bash
   # Wizard detects available adapters
   ls adapters/*/config.yml
   ```

2. **Selection Interface**
   ```
   Select spec frameworks to install:
   [x] spec-kit    - GitHub's specification toolkit
   [ ] bmad-method - Multi-agent development system
   [x] agent-os    - Dated specs methodology
   [ ] aider       - AI coding conventions
   [x] cursor      - Cursor IDE rules
   [ ] continue    - Continue.dev rules
   ```

3. **Conflict Detection**
   ```bash
   # Check for file conflicts before installation
   for spec in $SELECTED_SPECS; do
     check_conflicts "adapters/$spec/templates/"
   done
   ```

4. **Parallel Installation**
   ```bash
   # Install each selected spec
   for spec in $SELECTED_SPECS; do
     bash "adapters/$spec/install.sh" &
   done
   wait
   ```

### Adapter Structure

Each adapter must provide:

#### config.yml
```yaml
name: spec-kit
version: 1.0.0
description: GitHub's specification-driven development toolkit
author: GitHub
license: MIT

files:
  - source: templates/memory/
    dest: memory/
  - source: templates/specs/
    dest: specs/
  - source: templates/scripts/
    dest: scripts/

dependencies: []

conflicts:
  - bmad-method  # If they share similar files

ai_assistants:
  - claude
  - copilot
  - cursor
```

#### install.sh
```bash
#!/bin/bash
# Adapter-specific installation logic
# Called by wizard.sh with project root as argument

PROJECT_ROOT="$1"
ADAPTER_DIR="$(dirname "$0")"

# Copy templates
cp -r "$ADAPTER_DIR/templates/"* "$PROJECT_ROOT/"

# Run any setup
if [ -f "$ADAPTER_DIR/setup.sh" ]; then
  bash "$ADAPTER_DIR/setup.sh" "$PROJECT_ROOT"
fi
```

### Documentation Impact

Current.md changes from:
```markdown
- [specs/github-spec-kit/install.sh](../specs/github-spec-kit/install.sh)
- [specs/github-spec-kit/template1.md](../specs/github-spec-kit/template1.md)
- [specs/github-spec-kit/template2.md](../specs/github-spec-kit/template2.md)
```

To:
```markdown
- [adapters/spec-kit/](../adapters/spec-kit/) - GitHub spec toolkit
- [adapters/bmad-method/](../adapters/bmad-method/) - BMAD multi-agent
```

### Benefits

1. **Clean Separation** - Each spec in its own directory
2. **No Conflicts** - Different frameworks use different files
3. **Easy Updates** - Pull updates per adapter
4. **Mix & Match** - Use spec-kit's memory/ with agent-os specs/
5. **Version Control** - Track versions independently
6. **Simple Removal** - Just delete the adapter directory

### Implementation Tasks

1. ✅ Research existing spec frameworks
2. ✅ Design directory structure
3. 🟡 Create this specification
4. ⬜ Refactor existing spec-kit adapter
5. ⬜ Create BMAD adapter
6. ⬜ Create Agent OS adapter
7. ⬜ Create lightweight adapters (aider, cursor, continue)
8. ⬜ Update wizard.sh for multi-select
9. ⬜ Add conflict detection
10. ⬜ Test parallel installation

### Compatibility Matrix

| Framework | File Location | AI Tools | Conflicts |
|-----------|--------------|----------|-----------|
| spec-kit | memory/, specs/ | All | None |
| bmad-method | bmad-core/ | All | None |
| agent-os | .agent-os/specs/ | All | None |
| aider | CONVENTIONS.md | Aider | None |
| cursor | .cursorrules | Cursor | None |
| continue | .continuerules | Continue | None |

### Migration Path

For existing installations:
1. Detect current spec (if any)
2. Move to new adapter structure
3. Update .living-docs.config
4. Preserve customizations

### Testing Requirements

- [ ] Install single spec
- [ ] Install multiple specs
- [ ] Update individual spec
- [ ] Remove spec
- [ ] Detect conflicts
- [ ] Preserve customizations during update

## Open Questions

1. Should we support spec dependencies? (e.g., bmad requires Node.js)
2. How to handle spec-specific commands? (e.g., `npx bmad-method`)
3. Should adapters auto-update or manual only?
4. Maximum number of simultaneous specs?

## Decision

**Proceed with directory-based multi-spec system.** Start by refactoring spec-kit into new structure as proof of concept.