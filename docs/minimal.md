# Minimal Context

## Project: living-docs
Universal documentation framework that keeps docs alive.

## Core Principles
1. **Documentation as Code** - Docs live with code
2. **Zero Drift** - Automated drift detection
3. **Framework Agnostic** - Works with any tools

## Quick Commands
```bash
./scripts/check-drift.sh  # Check for drift
ls docs/active/           # Current work
grep "^- \[ \]" docs/bugs.md  # Open bugs
```

## File Locations
- `docs/` - All documentation
- `specs/` - Feature specifications
- `scripts/` - Automation tools
- `tests/` - Test files

## Need More Context?
If working on:
- Tests → Load @procedures/testing.md
- Git → Load @procedures/git.md
- Bugs → Load @knowledge/gotchas.md
- Specs → Load @rules/[framework].md

---
*This minimal context is loaded by default. Additional docs loaded as needed.*