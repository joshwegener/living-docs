# living-docs - Project Dashboard (Single Source of Truth)

**Status**: BETA | **Version**: 5.1.0 | **Updated**: Sept 21, 2025

## 🎯 Project Mission
Create a documentation framework that actually stays alive throughout a project's lifecycle.

## 📊 Current Status
- **Unified Wizard**: ✅ Complete v3.0.0 (multi-adapter support, interactive selection)
- **Multi-Spec Adapters**: ✅ Complete (6 frameworks: spec-kit, bmad, agent-os, aider, cursor, continue)
- **Update System**: ✅ Complete (checks core + all adapters, version tracking)
- **Path Rewriting**: ✅ Complete (dynamic path customization for all adapters)
- **Documentation Repair**: ✅ Complete with drift detection
- **AI-Agnostic**: ✅ Complete (auto-detects 9+ AI assistants)
- **AI Command Support**: ✅ Complete ([auto-installs commands](procedures/ai-commands.md) to AI-specific directories)
- **Bootstrap System**: ✅ Complete with auto-injection and modular rules
- **Minimal Impact**: ✅ Complete
- **Debug System**: ✅ Complete (comprehensive logging with security)
- **Troubleshooting**: ✅ Complete (634-line guide covering all scenarios)
- **GitHub Standards**: ✅ Complete with custom locations
- **Auto-updates**: ✅ Complete (manual trigger, preserves customizations)
- **Examples**: 🔴 Not Started
- **Testing**: 🔴 Not Started
- **Community**: 🔴 Not Started

## 🔥 Active Development

### ⚠️ CRITICAL: TDD Remediation (8-week plan)
**30,000+ lines of code violating TDD_TESTS_FIRST gate**
1. [Week 1: Security Modules](specs/008-tdd-remediation-week1/spec.md) - 🔴 CRITICAL (lib/security/*)
2. [Week 2: Core Adapters](specs/009-tdd-remediation-week2/spec.md) - 🔴 HIGH (lib/adapter/*)
3. [Week 3-4: Validation](specs/010-tdd-remediation-week3/spec.md) - 🟡 MEDIUM (lib/validation/*)
4. [Week 5-6: UI & Integration](specs/011-tdd-remediation-week5/spec.md) - 🟡 MEDIUM (lib/ui/*, lib/docs/*)

### Regular Development
1. [Testing Framework](./active/06-testing-framework.md) - 🟡 In Progress (HIGH)
   - ✅ Created comprehensive input sanitization test suite
   - 🔴 Need to implement lib/security/sanitize.sh module
- [planning-modular-rules](active/002-planning-modular-rules.md) - [Description needed]
2. [Examples Library](./active/07-examples-library.md) - 🔴 Not Started (HIGH)
3. [VSCode Extension](./active/08-vscode-extension.md) - ⚪ Future

## ✅ Recently Completed
- [Documentation Optimization](./specs/003-documentation-optimization/) - 82% token reduction via dynamic loading ✅
- [Modular Spec Rules System](./specs/002-modular-spec-rules/) - Dynamic framework rule inclusion with compliance review ✅
- [Multi-Spec Adapter System](./completed/2025-09-16-multi-spec-adapter.md) - Support for 6 frameworks ✅
- [System Consistency Fixes](completed/2025-09-16-system-consistency-fixes.md) - Fixed drift detection and path issues ✅
- [Wizard v3.0.0](./completed/2025-09-16-wizard-v3.md) - Multi-select framework installation ✅
- [Update System Enhancement](./completed/2025-09-16-update-system.md) - Adapter version tracking ✅
- [Spec-Kit Adapter](./completed/2025-09-15-spec-kit-adapter.md) - GitHub spec-kit integration ✅
- [Drift Detection System](./completed/2025-09-15-drift-detection.md) - Auto-fix documentation drift ✅

## 📐 Project Specifications
- [Spec 001: System Consistency](../specs/001-system-consistency-fixes/spec.md) - Fixes for drift and version issues
- [Spec 002: Modular Rules](../specs/002-modular-spec-rules/spec.md) - Framework-specific rules system
- [Spec 003: Bootstrap System](../specs/003-bootstrap-system/spec.md) - Token-optimized context loading
- [Spec 004: Living Docs Review](../specs/004-living-docs-review/spec.md) - Comprehensive review and fixes
- [Spec 005: Debug Logging](../specs/005-debug-logging/spec.md) - Comprehensive debug logging system (retrospective)
- [Spec 006: Troubleshooting Guide](../specs/006-troubleshooting-guide/spec.md) - User troubleshooting documentation (retrospective)
- [Spec 007: Adapter Installation](../specs/007-adapter-installation/spec.md) - Safe adapter installation with conflict prevention ✅ (Merged Sept 28)
- [Spec 008: TDD Week 1](../specs/008-tdd-remediation-week1/spec.md) - Security module remediation 🔴
- [Spec 009: TDD Week 2](../specs/009-tdd-remediation-week2/spec.md) - Core adapter remediation 🔴
- [Spec 010: TDD Week 3-4](../specs/010-tdd-remediation-week3/spec.md) - Validation remediation 🔴
- [Spec 011: TDD Week 5-6](../specs/011-tdd-remediation-week5/spec.md) - UI & integration remediation 🔴

## 📂 Complete Documentation Map

### Core Files (v5.0 Architecture)
- [README.md](../README.md) - Public introduction (GitHub standard)
- [VERSION](../VERSION) - Current version number
- [docs/versioning.md](./versioning.md) - Versioning strategy and history
- [docs/bootstrap.md](./bootstrap.md) - Router for dynamic documentation loading
- [docs/gates.xml](./gates.xml) - Immutable compliance gates (KV-cache optimized)
- [docs/context.md](./context.md) - Dynamic context (generated by build-context.sh)
- [docs/minimal.md](./minimal.md) - Default minimal context

### Quick Capture
- [docs/bugs.md](./bugs.md) - Lightweight bug tracking (one-liners)
- [docs/ideas.md](./ideas.md) - Feature ideas backlog (one-liners)
- [docs/troubleshooting.md](./troubleshooting.md) - Comprehensive troubleshooting guide

### Configuration
- [.living-docs.config](../.living-docs.config) - Our configuration
- [.living-docs.config.example](../.living-docs.config.example) - Template

### Scripts
- [wizard.sh](../wizard.sh) - Universal setup wizard (NEW!)
- [scripts/build-context.sh](../scripts/build-context.sh) - Dynamic context builder (v5.0)
- [scripts/token-metrics.sh](../scripts/token-metrics.sh) - Token usage analysis (v5.0)
- [scripts/check-drift.sh](../scripts/check-drift.sh) - Documentation drift detection
- [setup.sh](../setup.sh) - Legacy setup (deprecated)
- [repair.sh](../repair.sh) - Legacy repair (deprecated)

### Libraries
- [lib/debug/logger.sh](../lib/debug/logger.sh) - Debug logging with security & cross-platform support
- lib/security/sanitize.sh - Input sanitization (pending implementation)

### Tests (Bats-based TDD tests)
- [tests/bats/](../tests/bats/) - Comprehensive TDD test suite using Bats framework
  - test_adapter_install.bats - Adapter installation tests
  - test_adapter_manifest.bats - Manifest tracking tests
  - test_adapter_prefix.bats - Command prefixing tests
  - test_adapter_remove.bats - Adapter removal tests
  - test_adapter_rewrite.bats - Path rewriting tests
  - test_adapter_update.bats - Update system tests
  - test_agents.bats - Agent installation tests
  - test_a11y.bats - Accessibility library tests
  - test_mermaid.bats - Mermaid diagram tests
  - test_validation.bats - Input validation tests

### Legacy Tests (Shell-based)
- [tests/debug/logger-compliance.test.sh](../tests/debug/logger-compliance.test.sh) - Debug logger compliance tests
- [tests/debug/logger-basic.test.sh](../tests/debug/logger-basic.test.sh) - Debug logger basic tests
- [tests/debug/logger.test.sh](../tests/debug/logger.test.sh) - Debug logger full test suite
- [tests/unit/test_install_adapter_default.sh](../tests/unit/test_install_adapter_default.sh) - Test default adapter installation
- [tests/unit/test_install_adapter_custom_paths.sh](../tests/unit/test_install_adapter_custom_paths.sh) - Test custom path adapter installation
- [tests/unit/test_remove_adapter.sh](../tests/unit/test_remove_adapter.sh) - Test complete adapter removal using manifest (T006)
- [tests/unit/test_update_adapter_customizations.sh](../tests/unit/test_update_adapter_customizations.sh) - Test updating adapter while preserving user customizations (T007)
- [tests/unit/test_validate_paths.sh](../tests/unit/test_validate_paths.sh) - Test detection of hardcoded paths before installation (T008)
- [tests/unit/test_command_prefixing.sh](../tests/unit/test_command_prefixing.sh) - Test automatic command name prefixing (T009)
- [tests/unit/test_handle_conflicts.sh](../tests/unit/test_handle_conflicts.sh) - Test detection and resolution of command conflicts (T010)
- [tests/unit/test_install_agents.sh](../tests/unit/test_install_agents.sh) - Test installation of agent templates (T011)

### Templates
- [templates/PROJECT.md.template](../templates/PROJECT.md.template) - Standard projects
- [CLAUDE-BOOTSTRAP.md](../templates/ai-projects/CLAUDE-BOOTSTRAP.md) - [Description needed]
- [templates/ai-projects/CLAUDE.md.template](../templates/ai-projects/CLAUDE.md.template) - Claude AI
- [templates/ai-projects/AI.md.template](../templates/ai-projects/AI.md.template) - Universal AI
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
- [.github/ISSUE_TEMPLATE/](../.github/ISSUE_TEMPLATE/) - Issue templates
- [.github/workflows/release.yml](../.github/workflows/release.yml) - Automated release pipeline with security validation
- [.github/workflows/tdd-enforcement.yml](../.github/workflows/tdd-enforcement.yml) - TDD compliance checks on all PRs

### Development History
- [docs/log.md](./log.md) - Agent coordination log (one-liners for multi-agent awareness)
- [maintenance](procedures/maintenance.md) - [Description needed]
- [docs/completed/](./completed/) - Finished tasks with full details (dated)
- [docs/issues/](./issues/) - Detailed bug investigations when needed
- [docs/procedures/enforcement.md](./procedures/enforcement.md) - Mandatory rules & verification
- [docs/procedures/common-tasks.md](./procedures/common-tasks.md) - Command reference
- [docs/procedures/adapter-versioning.md](./procedures/adapter-versioning.md) - Dual versioning guide for adapters

## 🐛 Quick Issues
See [bugs.md](./bugs.md) - Current count: 17 open

## 💡 Ideas Backlog
See [ideas.md](./ideas.md) - Feature ideas and improvements

## 🔮 Roadmap
- [x] **v1.0.0**: Core framework (Sept 2025)
- [x] **v2.0.0**: Intelligent auto-detection (Sept 2025)
- [x] **v3.0.0**: Multi-spec adapter system (Sept 2025)
- [x] **v4.0.0**: Modular rules system (Sept 2025)
- [x] **v5.0.0**: Documentation optimization - 82% token reduction (Sept 2025)
- [ ] **v5.1.0**: Testing framework
- [ ] **v5.2.0**: Examples library
- [ ] **v6.0.0**: XML format conversion for all docs
- [ ] **v10.0.0**: Production ready with enterprise features

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
echo "- [ ] Issue description" >> docs/bugs.md

# Complete a task
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md

# Run tests (coming soon)
./test.sh

# Install in new project
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```
