# Technical Architecture & Implementation Notes

## 🏗️ Core Architecture Patterns

### Behavior vs Reference Separation
- **Behavior** (CLAUDE.md/AI.md): HOW agents should act - stays small and accessible
- **Reference** (docs/): WHAT to know - detailed procedures, can grow large
- This prevents documentation bloat in critical files

### Adapter Pattern Implementation
- Adapters live in `adapters/` directory
- Each adapter is self-contained bash script
- Can be called independently or via wizard
- Version tracking in JSON for updates

## 🏗️ Architecture Decisions

### Why One Wizard?
- Multiple scripts confuse users
- Auto-detection removes decision burden
- Single entry point = better UX

### Why Configurable Paths?
- `.claude/docs/` for AI projects
- `.github/docs/` for GitHub-centric
- Teams have existing conventions
- Flexibility increases adoption

### Why AI-Agnostic?
- Claude today, GPT-5 tomorrow
- Teams use different assistants
- Universal AI.md works for all
- Future-proof design


## 📝 File Naming Conventions

### Use lowercase (except standards)
- ✅ `bugs.md`, `ideas.md`, `log.md`, `project.md`
- ✅ `README.md` (GitHub standard - exception)
- ✅ `LICENSE` (standard - exception)
- ❌ `IDEAS.md`, `PROJECT.md` (avoid unless standard)

### Purpose of Each File Type
- **log.md** - One-liner updates for multi-agent coordination
- **bugs.md** - Quick bug capture (one-liners)
- **ideas.md** - Feature ideas backlog (one-liners)
- **current.md** - Dashboard and single source of truth
- **project.md/claude.md** - Behavior guidance for humans/AI

## 📝 Critical Implementation Notes

### Template Variables
- `{{DOCS_PATH}}` - User's chosen documentation location
- `{{PROJECT_NAME}}` - Extracted or provided name
- `{{SPEC_SYSTEM}}` - Selected methodology

### Script Portability Issues
- `sed -i ''` works on macOS
- `sed -i` works on Linux
- Need to detect OS and adjust

### One-Liner Installation
```bash
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```
This is the magic - one command for everything

---
*This file contains technical implementation details for developers working on living-docs itself*