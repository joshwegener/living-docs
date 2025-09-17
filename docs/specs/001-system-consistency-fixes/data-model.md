# Data Model: System Consistency Fixes

**Date**: 2025-09-16
**Feature**: 001-system-consistency-fixes

## Core Entities

### Configuration Entity
**Purpose**: Track installation state and framework versions
**Format**: Bash key=value pairs
**Location**: `.living-docs.config` (project root)

**Fields**:
- `docs_path`: String - Location of documentation (e.g., "docs", ".claude")
- `version`: String - living-docs version (e.g., "3.1.0")
- `created`: String - Installation date (YYYY-MM-DD format)
- `INSTALLED_SPECS`: String - Space-separated list of installed frameworks
- `{FRAMEWORK}_VERSION`: String - Version of each installed framework

**Example**:
```bash
docs_path="docs"
version="3.1.0"
created="2025-09-16"
INSTALLED_SPECS="spec-kit aider"
SPEC_KIT_VERSION="1.0.0"
AIDER_VERSION="1.0.0"
```

### Documentation Structure Entity
**Purpose**: Organized hierarchy of documentation files
**Format**: Directory structure with markdown files
**Location**: Configurable (docs_path value)

**Structure**:
```
{docs_path}/
├── current.md          # Dashboard
├── bugs.md            # Quick issues
├── ideas.md           # Feature backlog
├── log.md             # Event log
├── bootstrap.md       # AI instructions
├── specs/             # All specifications
├── active/            # Current work
├── completed/         # Recent completions (30 days)
├── archived/          # Historical work (>30 days)
└── procedures/        # How-to guides
```

### Archive Entity
**Purpose**: Historical completed work moved from active context
**Format**: Dated markdown files
**Location**: `{docs_path}/archived/`

**Naming**: `YYYY-MM-DD-feature-name.md`
**Criteria**: Completed work older than 30 days
**Content**: Preserved unchanged from completed/

### Spec-Kit Integration Entity
**Purpose**: Connection between installed frameworks and AI instructions
**Format**: Dynamic content in bootstrap.md
**Dependencies**: .living-docs.config INSTALLED_SPECS

**Dynamic Sections**:
- Available commands based on installed frameworks
- Workflow instructions per methodology
- Critical checklist items for each spec type

## Relationships

1. **Configuration → Documentation Structure**: docs_path determines location
2. **Configuration → Spec-Kit Integration**: INSTALLED_SPECS determines available commands
3. **Documentation Structure → Archive**: completed/ files move to archived/ based on age
4. **Spec-Kit Integration → Bootstrap**: bootstrap.md content varies by installed specs

## State Transitions

### Archive Lifecycle
1. **Active** → **Completed**: Task finished, moved to completed/
2. **Completed** → **Archived**: After 30 days, moved to archived/
3. **Archived** → **Completed**: If referenced again (rare)

### Configuration Lifecycle
1. **Missing** → **Created**: First wizard run
2. **Created** → **Updated**: Adding frameworks, version upgrades
3. **Updated** → **Migrated**: Structure changes (e.g., specs/ → docs/specs/)

## Validation Rules

### Configuration File
- `docs_path` must be valid directory name
- `version` must follow semantic versioning
- `created` must be valid YYYY-MM-DD date
- `INSTALLED_SPECS` must contain known framework names
- Version fields must exist for each installed spec

### Archive Rules
- Only move files older than 30 days
- Preserve file naming convention
- Update current.md references when archiving
- Maintain chronological order in archived/