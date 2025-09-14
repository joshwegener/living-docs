# living-docs - Project Dashboard (Single Source of Truth)

**Status**: ALPHA | **Version**: 0.2.0 | **Updated**: Sept 14, 2025

## 📋 Status Reporting Instructions
When asked for project status, provide:
1. **Active Tasks**: Count items in `active/` directory (currently 8 specs)
2. **Open Bugs**: Check [bugs.md](../bugs.md) (7 open, 2 closed)
3. **Ideas Backlog**: Check [ideas.md](../ideas.md) (25+ ideas)
4. **Recent Completions**: Spec-kit integration, bootstrap templates
5. **Current Focus**: Testing framework and examples library

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
6. [Testing Framework](./active/06-testing-framework.md) - Comprehensive testing
7. [Examples Library](./active/07-examples-library.md) - Real-world examples
8. [VSCode Extension](./active/08-vscode-extension.md) - IDE integration

## 📂 Complete Documentation Map

### Core Files
- [README.md](../README.md) - Public introduction (GitHub standard)
- [project.md](../project.md) - Internal development guidelines
- [insights.md](../insights.md) - Architecture decisions & key insights
- [migration.md](../migration.md) - Version migration guide

### Quick Capture
- [bugs.md](../bugs.md) - Lightweight bug tracking (one-liners)
- [ideas.md](../ideas.md) - Feature ideas backlog (one-liners)

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

### Development History
- [docs/log.md](./log.md) - Agent coordination log (one-liners for multi-agent awareness)
- [docs/completed/](./completed/) - Finished tasks with full details (dated)
- [docs/issues/](./issues/) - Detailed bug investigations when needed

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

## 📚 GitHub Integration (Spec-Kit)
- [Pull Request Template](../.github/pull_request_template.md) - PR standards
- [Contributing Guide](../.github/CONTRIBUTING.md) - How to contribute
- [Code of Conduct](../.github/CODE_OF_CONDUCT.md) - Community standards
- [Bug Report Template](../.github/ISSUE_TEMPLATE/bug_report.md) - Issue reporting
- [Feature Request Template](../.github/ISSUE_TEMPLATE/feature_request.md) - New ideas

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

# Run tests (coming soon)
./test.sh

# Install in new project
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```