# living-docs - Project Dashboard (Single Source of Truth)

**Status**: ALPHA | **Version**: 0.2.0 | **Updated**: Sept 14, 2025

## 🎯 Project Mission
Create a documentation framework that actually stays alive throughout a project's lifecycle.

## 📊 Current Status
- **Unified Wizard**: ✅ Complete
- **Documentation Repair**: ✅ Complete
- **Universal Adapters**: ✅ Complete
- **AI-Agnostic**: ✅ Complete
- **Examples**: 🟡 In Progress
- **Community**: 🔴 Not Started

## 🔥 Active Development
1. [Initial Repository Setup](./active/01-initial-setup.md) - Core structure
2. [Spec-Kit Integration](./active/02-spec-kit-integration.md) - GitHub integration
3. [Universal Spec Adapter](./active/03-universal-spec-adapter.md) - Any methodology
4. [Configurable Paths](./active/04-configurable-docs-location.md) - Flexible locations
5. [Documentation Repair](./active/05-documentation-repair-system.md) - Brownfield projects

## 📂 Complete Documentation Map

### Core Files
- [README.md](../README.md) - Public introduction
- [PROJECT.md](../PROJECT.md) - Internal guidelines
- [CRITICAL_INSIGHTS.md](../CRITICAL_INSIGHTS.md) - Essential architecture decisions
- [MIGRATION.md](../MIGRATION.md) - Version migration guide

### Quick Capture
- [bugs.md](../bugs.md) - Lightweight bug tracking (one-liners)
- [IDEAS.md](../IDEAS.md) - Feature ideas backlog (one-liners)

### Configuration
- [.living-docs.config](../.living-docs.config) - Our configuration
- [.living-docs.config.example](../.living-docs.config.example) - Template

### Scripts
- [wizard.sh](../wizard.sh) - Universal setup wizard (NEW!)
- [setup.sh](../setup.sh) - Legacy setup (deprecated)
- [repair.sh](../repair.sh) - Legacy repair (deprecated)

### Templates
- [templates/PROJECT.md.template](../templates/PROJECT.md.template) - Standard projects
- [templates/ai-projects/CLAUDE.md.template](../templates/ai-projects/CLAUDE.md.template) - Claude AI
- [templates/ai-projects/AI.md.template](../templates/ai-projects/AI.md.template) - Universal AI
- [templates/bugs.md.template](../templates/bugs.md.template) - Bug tracker
- [templates/docs/current.md.template](../templates/docs/current.md.template) - Dashboard

### Spec Adapters
- [specs/README.md](../specs/README.md) - Adapter system docs
- [specs/github-spec-kit/](../specs/github-spec-kit/) - GitHub integration
- [specs/bmad-method/](../specs/bmad-method/) - BMAD integration
- [specs/agent-os/](../specs/agent-os/) - Agent OS integration

### GitHub Integration
- [.github/README.md](../.github/README.md) - Our spec-kit usage
- [.github/ISSUE_TEMPLATE/](../.github/ISSUE_TEMPLATE/) - Issue templates

### Development Logs
- [docs/log.md](./log.md) - One-liner history
- [docs/completed/](./completed/) - Finished tasks (dated)
- [docs/issues/](./issues/) - Detailed bug investigations

## 🐛 Quick Issues
See [bugs.md](../bugs.md) - Current count: 7 open, 2 closed

## 💡 Ideas Backlog
See [IDEAS.md](../IDEAS.md) - Current count: 25 ideas

## 🔮 Roadmap
- [x] **v0.1**: Core framework
- [x] **v0.2**: Unified wizard
- [ ] **v0.3**: Real-world examples
- [ ] **v0.4**: Community features
- [ ] **v1.0**: Production ready

## 📖 External Resources
- [GitHub Repository](https://github.com/joshwegener/living-docs)
- [One-Liner Install](https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh)

---

**This dashboard is the single source of truth for ALL documentation in living-docs**

---

**Quick Commands:**
```bash
# Check current work
ls docs/active/

# Add new issue
echo "- [ ] Issue description" >> ../bugs.md

# Complete a task
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md
```