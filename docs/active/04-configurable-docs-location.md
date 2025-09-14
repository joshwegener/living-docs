# Configurable Documentation Location

**Status**: ACTIVE
**Started**: Sept 14, 2025
**Owner**: Core Team

## Objective
Allow users to choose where their documentation lives (e.g., `docs/`, `.claude/docs/`, `.github/docs/`, etc.)

## Why This Matters
- Some projects already have a `docs/` directory
- AI projects might prefer `.claude/docs/`
- Enterprise might want `.documentation/`
- Flexibility increases adoption

## Design

### Configuration File
Create `.living-docs.config` in project root:
```yaml
# .living-docs.config
version: 1.0
paths:
  docs: ".claude/docs"      # or "docs" or ".github/docs" etc.
  bugs: "bugs.md"           # or ".claude/bugs.md"
  project: "PROJECT.md"     # or "CLAUDE.md" for AI projects
spec_system: "github-spec-kit"  # or "bmad-method" etc.
auto_update: true
update_frequency: "weekly"
```

### Setup Flow
```bash
./setup.sh my-project

> Where should documentation live?
  1) docs/ (standard)
  2) .claude/docs/ (AI projects)
  3) .github/docs/ (GitHub-centric)
  4) .documentation/ (enterprise)
  5) Custom path...

> Choice: 2
✓ Documentation will be created at: .claude/docs/
```

### Template Updates
All templates need to use path variables:
- `{{DOCS_PATH}}` instead of hardcoded `docs/`
- `{{PROJECT_FILE}}` instead of `PROJECT.md`
- `{{BUGS_FILE}}` instead of `bugs.md`

### Agent Guidance Updates
CLAUDE.md and PROJECT.md templates must reference configured paths:
```markdown
Check `{{DOCS_PATH}}/current.md` for status
Report bugs in `{{BUGS_FILE}}`
```

## Implementation Steps
1. Update setup.sh to ask for path preference
2. Create config file generator
3. Update all templates with variables
4. Create path resolver utility
5. Test with different configurations

## Benefits
- Works with existing project structures
- No conflicts with existing docs
- Supports team preferences
- Enterprise-friendly customization