# SPEC-001: GitHub Spec-Kit Adapter Implementation

## Status: Ready for Implementation
**Assigned**: Dev Agent
**Priority**: CRITICAL - Blocks alpha release

## Objective
Create the first working adapter for living-docs that integrates GitHub's Spec-Kit community standards with auto-update capability.

## Success Criteria
- [ ] Adapter creates complete GitHub community structure
- [ ] Auto-update mechanism checks for latest templates
- [ ] Preserves user customizations during updates
- [ ] Works independently and via wizard.sh
- [ ] Fully documented with examples

## Implementation Requirements

### 1. Directory Structure
```
adapters/
├── spec-kit.sh              # Main adapter executable
├── spec-kit/
│   ├── templates/           # Template cache
│   │   ├── ISSUE_TEMPLATE/
│   │   │   ├── bug_report.md
│   │   │   ├── feature_request.md
│   │   │   └── config.yml
│   │   ├── pull_request_template.md
│   │   ├── CONTRIBUTING.md
│   │   ├── CODE_OF_CONDUCT.md
│   │   ├── SECURITY.md
│   │   └── FUNDING.yml
│   ├── version.json         # Version tracking
│   └── update.sh           # Update mechanism
```

### 2. Core Functions (spec-kit.sh)

```bash
#!/bin/bash

# Function: Install spec-kit structure
install_spec_kit() {
    # Create .github/ directory
    # Copy templates from cache
    # Apply project-specific substitutions
    # Update .living-docs.config
}

# Function: Check for updates
check_updates() {
    # Check GitHub API for latest community standards
    # Compare with local version.json
    # Return update availability
}

# Function: Apply updates
apply_updates() {
    # Download latest templates
    # Preserve user customizations (git diff)
    # Merge updates intelligently
    # Update version.json
}

# Function: Validate installation
validate_spec_kit() {
    # Check all required files exist
    # Verify structure integrity
    # Return validation status
}

# CLI interface
case "$1" in
    install) install_spec_kit ;;
    update) check_updates && apply_updates ;;
    validate) validate_spec_kit ;;
    --test) run_tests ;;
    *) show_usage ;;
esac
```

### 3. Template Content

Create sensible defaults for each template:

**bug_report.md**:
```markdown
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Run '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- OS: [e.g. macOS, Linux]
- Version: [e.g. 0.2.0]
```

**feature_request.md**:
```markdown
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution**
What you want to happen.

**Alternatives considered**
Other solutions you've considered.
```

### 4. Auto-Update Mechanism

**update.sh**:
```bash
#!/bin/bash

# Configuration
GITHUB_API="https://api.github.com"
SPEC_KIT_REPO="github/gitignore"  # Example repo with templates
UPDATE_FREQUENCY="${UPDATE_FREQUENCY:-weekly}"

# Check if update needed
check_update_needed() {
    # Check last update timestamp
    # Compare with frequency setting
    # Return true/false
}

# Fetch latest templates
fetch_latest() {
    # Use GitHub API or direct download
    # Cache in templates/
    # Update version.json
}

# Preserve customizations
preserve_custom() {
    # Git diff current vs template
    # Store customizations
    # Apply after update
}
```

### 5. Integration with wizard.sh

Modify wizard.sh to call the adapter:

```bash
# In wizard.sh, when user selects GitHub Spec-Kit:
if [[ "$SPEC_SYSTEM" == "github-spec-kit" ]]; then
    echo "📦 Installing GitHub Spec-Kit..."
    bash adapters/spec-kit.sh install

    # Add to .living-docs.config
    echo "spec_system: github-spec-kit" >> .living-docs.config
    echo "auto_update: true" >> .living-docs.config
fi
```

### 6. Version Tracking

**version.json**:
```json
{
  "version": "1.0.0",
  "last_updated": "2025-09-14T10:00:00Z",
  "source": "github/community",
  "templates": {
    "bug_report": "1.0.0",
    "feature_request": "1.0.0",
    "pull_request": "1.0.0"
  }
}
```

### 7. Documentation

Create `docs/adapters/spec-kit.md`:

```markdown
# GitHub Spec-Kit Adapter

## Overview
Integrates GitHub's community standards into your project.

## Installation
```bash
./adapters/spec-kit.sh install
```

## Auto-Updates
Updates check weekly by default:
```bash
./adapters/spec-kit.sh update
```

## Customization
Edit templates in `.github/` - your changes are preserved during updates.

## Configuration
Set in `.living-docs.config`:
- `auto_update`: true/false
- `update_frequency`: daily/weekly/monthly
```

## Testing Requirements

1. **Installation Test**: Verify all files created correctly
2. **Update Test**: Ensure updates preserve customizations
3. **Validation Test**: Check structure integrity
4. **Integration Test**: Works via wizard.sh
5. **Edge Cases**: Handles existing .github/, spaces in paths

## Definition of Done

- [ ] All template files created and populated
- [ ] Adapter script fully functional
- [ ] Auto-update mechanism works
- [ ] Integration with wizard.sh complete
- [ ] Documentation written
- [ ] Tests pass
- [ ] Can be called independently: `./adapters/spec-kit.sh install`

## Notes for Dev Agent

1. Start with basic functionality - get install working first
2. Use simple bash, no external dependencies
3. Make it idempotent - running twice shouldn't break
4. Focus on GitHub's core 6 community files first
5. Auto-update can be phase 2 if needed

---
**This spec is complete. Implement exactly as specified. Ask if anything unclear.**