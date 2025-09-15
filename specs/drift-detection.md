# Drift Detection System Specification

## Problem Statement
Documentation drift occurs when files are created but not linked, counts become inaccurate, and documentation doesn't match code reality. Manual enforcement fails because humans forget.

## Solution
Automated drift detection and correction system with pre-commit hooks.

## Implementation

### Core Tool: check-drift.sh
- **Default behavior**: Auto-fix all issues
- **--dry-run**: Preview changes without applying
- **--no-fix**: Detection only mode

### Detection Features
1. **Orphaned Files**: Files not linked in current.md
2. **Broken Links**: Links pointing to non-existent files
3. **Count Mismatches**: Bug/idea counts not matching reality
4. **Categorization**: Smart path-based categorization

### Auto-Fix Capabilities
1. Add orphaned files to appropriate sections
2. Comment out broken links (preserves history)
3. Update counts automatically
4. Flag uncategorized items with warnings

### Categorization Logic
```bash
/active/         → Active Development
/completed/      → Recently Completed
/procedures/     → Development History
/specs/          → Spec Adapters
/templates/      → Templates
/scripts/        → Scripts
/.githooks/      → Git Integration
(other)          → UNCATEGORIZED (with warning)
```

### Pre-Commit Hook
- Runs drift check before every commit
- Auto-adds fixes to current commit
- Warns about undocumented code
- Non-blocking (maintains velocity)

## The "Uncategorized" Section
Special section in current.md that:
- Acts as a catch-all for uncertain items
- Uses warning emojis to grab attention
- Triggers AI's "need to clean" instinct
- Prevents files from being truly orphaned

## Success Metrics
- Zero orphaned files in repository
- All broken links identified immediately
- Counts always accurate
- New files never lost

## Installation
```bash
# Install git hooks
./scripts/install-hooks.sh

# Manual run
./scripts/check-drift.sh
```

## Future Enhancements
- [ ] AI-powered categorization suggestions
- [ ] Automatic description generation
- [ ] Cross-reference validation
- [ ] Code-to-docs mapping