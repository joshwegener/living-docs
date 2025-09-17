# living-docs - Project Dashboard (Single Source of Truth)

**Status**: BETA | **Version**: 0.3.0 | **Updated**: Sept 16, 2025

## 🎯 Project Mission
Create a documentation framework that actually stays alive throughout a project's lifecycle.

## 📊 Current Status
- **Unified Wizard**: ✅ Complete v3.0.0 (multi-adapter support, interactive selection)
- **Multi-Spec Adapters**: ✅ Complete (6 frameworks: spec-kit, bmad, agent-os, aider, cursor, continue)
- **Update System**: ✅ Complete (checks core + all adapters, version tracking)
- **Path Rewriting**: ✅ Complete (dynamic path customization for all adapters)
- **Documentation Repair**: ✅ Complete with drift detection
- **AI-Agnostic**: ✅ Complete (auto-detects 9+ AI assistants)
- **Bootstrap System**: ✅ Complete with auto-injection and modular rules
- **Minimal Impact**: ✅ Complete
- **GitHub Standards**: ✅ Complete with custom locations
- **Auto-updates**: ✅ Complete (manual trigger, preserves customizations)
- **Examples**: 🔴 Not Started
- **Testing**: 🔴 Not Started
- **Community**: 🔴 Not Started

## 🔥 Active Development
1. [Testing Framework](./active/06-testing-framework.md) - 🔴 Not Started (HIGH)
2. [Examples Library](./active/07-examples-library.md) - 🔴 Not Started (HIGH)
3. [VSCode Extension](./active/08-vscode-extension.md) - ⚪ Future

## ✅ Recently Completed
- [Modular Spec Rules System](./specs/002-modular-spec-rules/) - Dynamic framework rule inclusion with compliance review ✅
- [Multi-Spec Adapter System](./completed/2025-09-16-multi-spec-adapter.md) - Support for 6 frameworks ✅
- [System Consistency Fixes](completed/2025-09-16-system-consistency-fixes.md) - Fixed drift detection and path issues ✅
- [Wizard v3.0.0](./completed/2025-09-16-wizard-v3.md) - Multi-select framework installation ✅
- [Update System Enhancement](./completed/2025-09-16-update-system.md) - Adapter version tracking ✅
- [Spec-Kit Adapter](./completed/2025-09-15-spec-kit-adapter.md) - GitHub spec-kit integration ✅
- [Drift Detection System](./completed/2025-09-15-drift-detection.md) - Auto-fix documentation drift ✅
<!-- BROKEN: - [Bootstrap Implementation](./completed/2025-09-14-bootstrap-implementation.md) - Clean separation ✅ -->
<!-- BROKEN: - [GitHub Standards](./completed/2025-09-14-github-standards.md) - PR template, CONTRIBUTING ✅ -->
<!-- BROKEN: - [Minimal Impact Fix](./completed/2025-09-14-minimal-impact-fix.md) - Clean root dirs ✅ -->
<!-- BROKEN: - [Enforcement Rules](./completed/2025-09-14-enforcement-rules.md) - Bootstrap enforcement ✅ -->
<!-- BROKEN: - [Initial Setup](./completed/2025-09-14-initial-setup.md) - Core structure ✅ -->
<!-- BROKEN: - [Configurable Paths](./completed/2025-09-14-configurable-docs-location.md) - Flexible locations ✅ -->
<!-- BROKEN: - [Documentation Repair](./completed/2025-09-14-documentation-repair-system.md) - Brownfield projects ✅ -->

## 📂 Complete Documentation Map

### Core Files
- [README.md](../README.md) - Public introduction (GitHub standard)
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [project.md](../project.md) - Internal development guidelines --> --> --> --> --> -->
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [insights.md](../insights.md) - Architecture decisions & key insights --> --> --> --> --> -->
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [migration.md](../migration.md) - Version migration guide --> --> --> --> --> -->

### Quick Capture
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [bugs.md](../bugs.md) - Lightweight bug tracking (one-liners) --> --> --> --> --> -->
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [ideas.md](../ideas.md) - Feature ideas backlog (one-liners) --> --> --> --> --> -->

### Configuration
- [.living-docs.config](../.living-docs.config) - Our configuration
- [.living-docs.config.example](../.living-docs.config.example) - Template

### Scripts
- [wizard.sh](../wizard.sh) - Universal setup wizard (NEW!)
- [setup.sh](../setup.sh) - Legacy setup (deprecated)
- [repair.sh](../repair.sh) - Legacy repair (deprecated)

### Templates
- [templates/PROJECT.md.template](../templates/PROJECT.md.template) - Standard projects
- [CLAUDE-BOOTSTRAP.md](../templates/ai-projects/CLAUDE-BOOTSTRAP.md) - [Description needed]
- [templates/ai-projects/CLAUDE.md.template](../templates/ai-projects/CLAUDE.md.template) - Claude AI
- [templates/ai-projects/AI.md.template](../templates/ai-projects/AI.md.template) - Universal AI
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: - [templates/bugs.md.template](../templates/bugs.md.template) - Bug tracker --> --> --> --> --> -->
- [templates/docs/current.md.template](../templates/docs/current.md.template) - Dashboard

### Spec Adapters
- [adapters/README.md](../adapters/README.md) - 📚 Complete adapter documentation
- [docs/specs/multi-spec-adapter-system.md](../docs/specs/multi-spec-adapter-system.md) - Multi-spec architecture
- [docs/specs/path-rewriting-system.md](../docs/specs/path-rewriting-system.md) - Path customization system
- [adapters/](../adapters/) - All 6 framework adapters:
  - `spec-kit/` - GitHub specification toolkit ✅
  - `bmad-method/` - Multi-agent system (Node.js) ✅
  - `agent-os/` - Dated specs methodology ✅
  - `aider/` - AI coding conventions ✅
  - `cursor/` - Cursor IDE rules ✅
  - `continue/` - Continue.dev rules ✅
- [docs/specs/wizard-enhancement.md](../docs/specs/wizard-enhancement.md) - Wizard improvement spec
- [docs/specs/auto-update-feature.md](../docs/specs/auto-update-feature.md) - Auto-update specification
- [docs/specs/ai-specific-paths.md](../docs/specs/ai-specific-paths.md) - AI-specific path mapping
- [docs/specs/drift-detection.md](../docs/specs/drift-detection.md) - Drift detection system spec
- [docs/specs/memory-enforcement.md](../docs/specs/memory-enforcement.md) - AI memory enforcement techniques

### GitHub Integration
<!-- BROKEN: - [.github/README.md](../.github/README.md) - Our spec-kit usage -->
- [.github/ISSUE_TEMPLATE/](../.github/ISSUE_TEMPLATE/) - Issue templates

### Development History
- [docs/log.md](./log.md) - Agent coordination log (one-liners for multi-agent awareness)
- [maintenance](procedures/maintenance.md) - [Description needed]
- [docs/completed/](./completed/) - Finished tasks with full details (dated)
- [docs/issues/](./issues/) - Detailed bug investigations when needed
- [docs/procedures/enforcement.md](./procedures/enforcement.md) - Mandatory rules & verification
- [docs/procedures/common-tasks.md](./procedures/common-tasks.md) - Command reference

## 🐛 Quick Issues
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: See [bugs.md](./bugs.md) - Current count: 16 open, 2 closed --> --> --> --> --> -->

## 💡 Ideas Backlog
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: See [ideas.md](./ideas.md) - Current count: 26 ideas --> --> --> --> --> -->

## 🔮 Roadmap
- [x] **v0.1**: Core framework
- [x] **v0.2**: Unified wizard
- [x] **v0.3**: Multi-spec adapter system (6 frameworks)
- [ ] **v0.4**: Real-world examples
- [ ] **v0.5**: Community features
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
<!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: <!-- BROKEN: echo "- [ ] Issue description" >> ../bugs.md --> --> --> --> --> -->

# Complete a task
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md

# Run tests (coming soon)
./test.sh

# Install in new project
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```
