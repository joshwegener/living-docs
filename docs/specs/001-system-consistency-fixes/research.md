# Research: System Consistency Fixes

**Date**: 2025-09-16
**Feature**: 001-system-consistency-fixes

## Configuration File Standards

### Decision: Use simple key=value bash format
**Rationale**:
- Consistent with existing tools (update.sh, wizard.sh)
- Easy to source in bash scripts
- Human readable and editable
- No external dependencies

**Alternatives considered**:
- YAML: Too complex, requires parser
- JSON: Not bash-friendly
- TOML: Good but adds complexity

**Required fields**:
```bash
docs_path="docs"
version="3.1.0"
created="2025-09-16"
INSTALLED_SPECS="spec-kit"
SPEC_KIT_VERSION="1.0.0"
```

## Documentation Structure Organization

### Decision: Move specs/ to docs/specs/
**Rationale**:
- Follows our own convention of configurable docs path
- Users expect all docs in one place
- Eliminates root directory clutter
- Consistent with our messaging

**Migration approach**:
- Check if specs/ exists and docs/ exists
- Move specs/* to docs/specs/*
- Update any hardcoded references
- Preserve git history where possible

## Archive Strategy

### Decision: 30-day rolling archive
**Rationale**:
- Reduces agent context from 12+ files to ~3-5 recent files
- 30 days covers typical sprint/iteration cycles
- Preserves history without cognitive overload
- Allows easy restoration if needed

**Implementation**:
- Create docs/archived/ directory
- Move completed work older than 30 days
- Update current.md references
- Maintain chronological organization

## Spec-Kit Integration

### Decision: Update bootstrap.md with spec-kit commands
**Rationale**:
- Makes spec-kit discoverable to AI agents
- Enforces dogfooding our own system
- Provides clear workflow guidance
- Validates our adapter system works

**Required changes**:
- Add spec-kit command references to bootstrap
- Document workflow: specify → plan → tasks
- Update critical checklist with spec-kit steps
- Test the full workflow ourselves

## Bootstrap Enhancement

### Decision: Dynamic bootstrap based on installed specs
**Rationale**:
- Bootstrap should know what tools are available
- Different workflows for different methodologies
- Reduces confusion about available commands
- Scales to multiple installed frameworks

**Implementation approach**:
- Read .living-docs.config to detect installed specs
- Conditionally show relevant commands
- Maintain backwards compatibility
- Clear fallback if no specs installed