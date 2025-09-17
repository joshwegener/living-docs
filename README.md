# living-docs

> Make documentation so easy it happens automatically

🎉 **BETA v0.3.0**: Multi-framework support is here! Choose from 6 AI development frameworks in our new wizard. We're using it to document itself - eating our own dog food! 🐕

[![GitHub](https://img.shields.io/github/license/joshwegener/living-docs)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-living-brightgreen)](docs/current.md)
[![Status](https://img.shields.io/badge/status-beta-yellow)](docs/current.md)
[![Version](https://img.shields.io/badge/version-0.3.0-blue)](docs/current.md)

## The Universal Truth

Every project starts with good documentation intentions. Then reality hits.

Documentation dies because **it's separate from work**. It becomes that thing you'll "update later" - except later never comes. Knowledge scatters across Slack threads, closed PRs, and that one developer's brain who just quit.

We've all been there. Starting a new job, staring at outdated docs, wondering if `setup.sh` still works or if you should use `docker-compose` or maybe that new thing mentioned in Slack last Tuesday.

## Why living-docs is Different

### 📍 It Lives Where You Work
Documentation isn't a separate task - it's part of your workflow. Update docs as you code. Track decisions as you make them. One-liner bug capture. Progressive disclosure that shows you what you need when you need it.

**Think of it as a universal adapter for documentation** - like those power adapters that work in any country. We don't compete with GitHub Spec-Kit, BMAD Method, or Agent OS. We're the documentation layer that works with ALL of them.

### 🔧 Built for Brownfield Reality
Most tools assume greenfield projects - clean slate, perfect structure. But that's not reality.

**We handle existing chaos with grace.** Run our wizard in your 5-year-old legacy project. It detects what you have, preserves what works, and adds what's missing. No "rip and replace" - just gentle repair.

### 🧠 Progressive Disclosure That Actually Works
- **Dashboard** (`current.md`): See everything at a glance
- **Active Work** (`docs/active/`): Current priorities
- **Deep Dives** (`docs/procedures/`): Detailed guides when needed

You only see what you need at each level. No information overload.

### ⏰ Temporal Organization
`2025-09-14-feature-complete.md` tells a story. When did we add auth? Check the dated completions. What happened last sprint? It's all there, organized by time.

## ✨ Features

### 🎯 Current Capabilities (v0.3.0)

#### Multi-Framework Support (NEW!)
- **6 Frameworks**: Choose any combination during setup
  - 📚 **spec-kit**: GitHub's specification-driven development toolkit
  - 🚀 **bmad-method**: Multi-agent development system (auto-detects Node.js)
  - 📅 **agent-os**: Dated specification folders methodology
  - 🤖 **aider**: AI coding conventions (CONVENTIONS.md)
  - 💻 **cursor**: Cursor IDE rules (.cursorrules)
  - ⚡ **continue**: Continue.dev rules (.continuerules)
- **Smart Path Rewriting**: Frameworks respect your chosen directory (.claude/, .github/, docs/)
- **Interactive Selection**: Beautiful checkbox interface with arrow key navigation
- **Conflict Detection**: Prevents incompatible frameworks from clashing

#### Intelligent Setup
- **Auto-Detection**: Finds existing docs, AI assistants, and frameworks
- **Brownfield Ready**: Works with messy, existing projects
- **Preview Mode**: See what will be created before committing
- **Version Tracking**: Each adapter tracks its own version
- **Update Checking**: Stay current with upstream framework changes

#### Documentation System
- **Single Dashboard**: `current.md` is your source of truth
- **Active Tracking**: What you're working on right now
- **Temporal History**: Dated completions tell the story
- **Quick Capture**: One-liner bugs and ideas
- **Drift Detection**: Auto-fixes orphaned docs and broken links
- **Progressive Disclosure**: See only what you need

#### Developer Experience
- **One-Command Setup**: Single wizard handles everything
- **AI-Agnostic**: Works with Claude, GPT-4, Cursor, Copilot, etc.
- **Custom Paths**: Put docs anywhere (.claude/, .github/, docs/)
- **Self-Updating**: Wizard and adapters can update themselves
- **Minimal Impact**: Clean root directory, organized structure
- **Git-Friendly**: All text files, perfect for version control

## 🚀 Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```

That's it! The wizard will:
1. 🔍 Detect your existing setup
2. 📍 Ask where to put docs (.claude/, .github/, docs/)
3. ✅ Let you select frameworks (multi-select with Space key)
4. 🚀 Install and configure everything
5. 📝 Show you next steps based on your selections

**Already installed?** Just run `./wizard.sh` to add frameworks or check for updates.

## What Gets Created

```
your-project/
├── CLAUDE.md          # AI assistant instructions (or PROJECT.md for humans)
└── docs/
    ├── current.md     # Dashboard - everything at a glance
    ├── bugs.md        # One-liner bug capture
    ├── ideas.md       # Feature backlog
    ├── active/        # What you're working on now
    ├── completed/     # What's done (dated)
    └── procedures/    # How-to guides
```

Simple. Clear. Maintainable.

## The Philosophy

### Why Not Just Use GitHub Issues?
- `bugs.md` = quick capture during coding
- GitHub Issues = external collaboration
- Different tools for different moments

### Why AI-Agnostic?
Your team uses Claude. Their team uses GPT-4. That contractor uses Cursor. **It doesn't matter.** living-docs works with all of them. One `CLAUDE.md` (or `AI.md`) configures any assistant.

### Why Not Force a Methodology?
Because you already have one. Maybe it's Agile, maybe it's "whatever works." We adapt to YOU, not the other way around.

## 🗺️ Roadmap

### ✅ Completed
- [x] **v0.1.0**: Core documentation framework
- [x] **v0.2.0**: Intelligent wizard with auto-detection
- [x] **v0.3.0**: Multi-framework adapter system (6 frameworks)

### 🚧 In Progress
- [ ] **Testing Framework**: Automated test suite for all features
- [ ] **Examples Library**: Real-world project templates

### 🔮 Future Plans

#### v0.4.0 - Examples & Templates (Q4 2024)
- [ ] Starter templates for common project types
- [ ] Framework-specific examples
- [ ] Migration guides from other doc systems
- [ ] Video tutorials

#### v0.5.0 - Community Features (Q1 2025)
- [ ] Plugin system for custom adapters
- [ ] Shared template repository
- [ ] Community framework contributions
- [ ] Integration with popular tools

#### v1.0.0 - Production Ready (Q2 2025)
- [ ] Enterprise features
- [ ] Team collaboration tools
- [ ] API for programmatic access
- [ ] Documentation analytics
- [ ] VSCode extension

### 💡 Maybe/Experimental
- [ ] **AI Documentation Assistant**: Auto-generate docs from code
- [ ] **Cross-Repository Sync**: Share docs across projects
- [ ] **Documentation Linting**: Enforce documentation standards
- [ ] **Smart Suggestions**: AI-powered documentation improvements
- [ ] **Documentation Graph**: Visualize documentation relationships
- [ ] **Changelog Generation**: Auto-create CHANGELOG from completions
- [ ] **Documentation Coverage**: Show which code lacks docs
- [ ] **Multi-Language Support**: Internationalization

## 🏗️ Architecture

### Adapter System
Our new adapter architecture allows parallel installation of multiple frameworks:

```
adapters/
├── spec-kit/       # GitHub spec-driven development
├── bmad-method/    # Multi-agent systems
├── agent-os/       # Dated specifications
├── aider/          # AI conventions
├── cursor/         # Cursor IDE rules
├── continue/       # Continue.dev rules
└── common/
    └── path-rewrite.sh  # Dynamic path customization
```

### Configuration
Simple `.living-docs.config` tracks everything:
```bash
docs_path: ".claude"
version: "3.0.0"
INSTALLED_SPECS="spec-kit bmad-method aider"
SPEC_KIT_VERSION="1.0.0"
BMAD_VERSION="2.0.0"
AIDER_VERSION="1.0.0"
```

## 🤝 Real Projects Using This

- **[living-docs](https://github.com/joshwegener/living-docs)**: This project (we dogfood ourselves!)
- **[Tmux-Orchestrator](https://github.com/your/tmux-orchestrator)**: Multi-agent AI coordination
- **[OTR Dad](https://github.com/your/otr-dad)**: 90,000 episode streaming platform
- More coming soon!

## 🤝 Contributing

We eat our own dog food. Check [docs/current.md](docs/current.md) to see what we're working on.

### How to Contribute
1. Check our [active work](docs/active/) to avoid duplicates
2. Look at [bugs.md](docs/bugs.md) for known issues
3. Browse [ideas.md](docs/ideas.md) for feature ideas
4. Follow our own documentation patterns
5. Run drift detection before submitting: `./scripts/check-drift.sh`

### Want to Contribute to living-docs itself?
```bash
# One-liner to get started with development
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash -s -- --dev

# This will:
# 1. Clone the living-docs repository
# 2. Run the wizard on itself (we dogfood!)
# 3. Set you up for development
```

For existing contributors:
```bash
# Check documentation drift
./scripts/check-drift.sh

# Test all adapters
./test-adapters.sh
```

## License

MIT - Use it anywhere, for any project.

---

> "Make documentation so easy it happens automatically."

That's the dream. We're building it.