# Documentation Repair System for Brownfield Projects

**Status**: ACTIVE
**Started**: Sept 14, 2025
**Owner**: Core Team

## 🎯 Vision
Add living-docs to ANY existing project with minimal friction, automatically discovering and organizing their existing documentation.

## Core Features

### 1. Auto-Discovery System
Detect what methodology/structure they're currently using:
- **BMAD Method**: Look for PRD files, architecture docs, agent configs
- **Agent OS**: Check for agent definitions, standards files
- **GitHub Spec-Kit**: .github/ templates and workflows
- **Custom/Unknown**: Analyze patterns and infer structure

### 2. Documentation Repair Modes

#### Quick Bootstrap (Minimal Touch)
```bash
./repair.sh --bootstrap

# Just adds:
# - AI.md (or CLAUDE.md, OPENAI.md, etc.)
# - @living-docs-guide.md reference
# - .living-docs.config
```

#### Full Migration (Complete Reorganization)
```bash
./repair.sh --full

# Analyzes and reorganizes:
# - Discovers existing docs
# - Suggests new structure
# - Migrates with user approval
# - Updates all references
```

### 3. AI-Agnostic Design

Instead of just CLAUDE.md, support:
- `AI.md` - Universal AI instructions
- `CLAUDE.md` - Claude-specific
- `OPENAI.md` - ChatGPT/GPT-4
- `JETBRAINS.md` - JetBrains AI
- `CURSOR.md` - Cursor AI
- `COPILOT.md` - GitHub Copilot

### 4. Bootstrap Approach

For minimal friction, we can just add:
```markdown
# AI.md (or CLAUDE.md)

@living-docs-guide.md  <!-- Imports our methodology -->

## Project-Specific Instructions
[Existing content preserved here]
```

## Implementation Design

### repair.sh Script Flow
```bash
./repair.sh [project-path]

> Analyzing existing documentation...
✓ Found README.md
✓ Found docs/ directory
✓ Found CONTRIBUTING.md
✓ Detected: Partial GitHub structure

> Suggested organization:
  docs/ → docs/procedures/
  README.md → Keep as is
  CONTRIBUTING.md → docs/contributing/

> Choose repair mode:
  1) Quick Bootstrap (add living-docs on top)
  2) Full Migration (reorganize everything)
  3) Custom (interactive choices)

> Which AI assistant do you use?
  1) Claude (Anthropic)
  2) ChatGPT (OpenAI)
  3) GitHub Copilot
  4) Cursor AI
  5) JetBrains AI
  6) Multiple/All
```

### Auto-Discovery Patterns

```python
# Methodology detection patterns
patterns = {
    'bmad': ['PRD.md', 'architecture.md', 'agents/', 'workflows/'],
    'agent-os': ['agents/', 'standards/', 'agent-config.yaml'],
    'spec-kit': ['.github/ISSUE_TEMPLATE/', '.github/workflows/'],
    'living-docs': ['.living-docs.config', 'docs/current.md'],
    'custom': []  # Fallback
}
```

### Minimal Friction Bootstrap

For existing projects that just want to add AI guidance:

```bash
# One-liner to add living-docs
curl -sSL https://living-docs.dev/bootstrap | bash

# Creates:
# - AI.md with @living-docs-guide.md
# - .living-docs.config (minimal)
# - bugs.md (if doesn't exist)
```

## Benefits

1. **Zero Breaking Changes** - Works on top of existing structure
2. **Progressive Enhancement** - Start minimal, migrate gradually
3. **AI Agnostic** - Works with any AI assistant
4. **Smart Discovery** - Understands existing patterns
5. **Reversible** - Can undo changes if needed

## File Structure After Repair

### Bootstrap Mode (Minimal)
```
existing-project/
├── [existing files unchanged]
├── AI.md (new, with @living-docs-guide.md)
├── bugs.md (new)
└── .living-docs.config (new)
```

### Full Migration Mode
```
existing-project/
├── [existing files preserved]
├── AI.md (or CLAUDE.md, etc.)
├── bugs.md
├── docs/ (reorganized)
│   ├── current.md (new dashboard)
│   ├── active/ (extracted from TODOs)
│   ├── procedures/ (migrated docs)
│   └── archive/ (old structure backup)
└── .living-docs.config
```

## Next Steps
1. Create repair.sh script
2. Build pattern detection system
3. Create AI-agnostic templates
4. Test on real brownfield projects
5. Create one-liner bootstrap installer