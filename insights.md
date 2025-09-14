# Critical Insights & Architecture Decisions

## 🧠 Core Philosophy
**"Documentation that stays alive by being part of the workflow, not separate from it"**

## 🎯 Key Innovations

### 1. Universal Adapter Pattern
- living-docs doesn't compete with methodologies (BMAD, Agent OS, Spec-Kit)
- It's the documentation layer that works with ANY methodology
- Like a universal power adapter for documentation

### 2. Behavior vs Reference Separation
- **Behavior** (CLAUDE.md/AI.md): HOW agents should act - stays small and accessible
- **Reference** (docs/): WHAT to know - detailed procedures, can grow large
- This prevents documentation bloat in critical files

### 3. Temporal Organization
- Dated completions create accountability trail
- `2025-09-14-feature-complete.md` tells a story
- Historical record of what happened when

### 4. Progressive Disclosure
- Dashboard (current.md) → Active work → Detailed procedures
- Users only see what they need at each level
- Prevents information overload

### 5. Documentation Repair for Brownfield
- Most tools assume greenfield projects
- We handle existing chaos with grace
- Bootstrap mode adds without breaking

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

### Why Not Just GitHub Issues?
- `bugs.md` = quick capture, low friction
- GitHub = external community interaction
- Internal vs external separation
- Different tools for different purposes

## 🚀 Growth Strategy

### Phase 1: Foundation (COMPLETE)
- ✅ Core framework
- ✅ Universal adapters
- ✅ Documentation repair
- ✅ Unified wizard

### Phase 2: Adoption
- Examples from real projects
- Video tutorials
- Community templates
- Integration guides

### Phase 3: Ecosystem
- VSCode extension
- GitHub Actions
- Web dashboard
- Enterprise features

## 💡 Competitive Advantages

1. **Only solution for brownfield projects**
2. **Works with ANY methodology**
3. **AI-agnostic design**
4. **Zero lock-in**
5. **Progressive adoption**

## 🔑 Success Metrics
- Time to find documentation
- Documentation staleness
- Contributor onboarding time
- Bug resolution speed
- Documentation update frequency

## 🎨 Design Principles
1. **Simplicity** - If it's complex, it won't be maintained
2. **Flexibility** - Work with what exists, don't force change
3. **Intelligence** - Auto-detect and adapt
4. **Beauty** - Good UX encourages usage
5. **Universality** - Work for everyone, everywhere

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

## 🌟 The Vision
**"Make documentation so easy that it happens automatically"**

Every project in the world could benefit from living documentation. We're building the universal solution that works with any team, any methodology, any AI, anywhere.

---
*This file captures the essential insights that must not be lost*