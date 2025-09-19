# living-docs

> Documentation that evolves with your code - automatically

🎉 **v5.0.0**: 82% token reduction! Dynamic context loading, modular rules, KV-cache optimization.

[![GitHub](https://img.shields.io/github/license/joshwegener/living-docs)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-living-brightgreen)](docs/current.md)
[![Status](https://img.shields.io/badge/status-beta-yellow)](docs/current.md)
[![Version](https://img.shields.io/badge/version-5.0.0-blue)](docs/current.md)

## 📑 Quick Navigation

- [**The Problem**](#-the-problem-we-solve) - Why documentation dies
- [**Features**](#-key-features) - What makes living-docs different
- [**Quick Start**](#-quick-start) - One command setup
- [**Supported Frameworks**](#-supported-frameworks) - 6 AI development methodologies
- [**How It Works**](#-how-it-works) - The living-docs philosophy
- [**Roadmap**](#-roadmap) - What's coming next
- [**Contributing**](#-contributing) - Join the mission

---

## 🎯 The Problem We Solve

**Documentation dies because it's separate from work.**

We've all been there:
- Starting a new job, staring at README.md last updated 2 years ago
- "Check the wiki" → Wiki is empty or wrong
- "Ask in Slack" → 47 conflicting answers
- "Read the code" → 500,000 lines, where do I start?

Documentation becomes that thing you'll "update later" - except later never comes. Knowledge scatters across closed PRs, Slack threads, and that one developer who just quit.

## ✨ Key Features

### ⚡ 82% Token Reduction (NEW in v5.0)
- **Dynamic Context Loading**: Only loads relevant docs for current task
- **KV-Cache Optimization**: 10x cost reduction on cached tokens
- **Smart Router**: Bootstrap.md now routes to needed docs vs loading everything
- **Immutable Gates**: Compliance checks in GATES.xml for perfect caching

### 🚀 One-Command Setup
```bash
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```
That's it. No npm install, no dependencies, just works.

### 🧠 Self-Updating & Smart
- **Auto-updates**: `wizard.sh --update` or add to cron
- **Detects everything**: Your AI assistant, existing docs, project type
- **Brownfield ready**: Works with 5-year-old legacy codebases
- **Zero config**: But fully configurable when needed

### 📚 Six AI Frameworks (Use Any Combination!)
- **spec-kit**: GitHub's specification-driven development
- **bmad-method**: Multi-agent orchestration (auto-installs Node.js)
- **agent-os**: Dated specification folders
- **aider**: AI coding conventions
- **cursor**: Cursor IDE rules
- **continue**: Continue.dev rules

### 🏗️ Documentation That Lives
- **Single dashboard** (`current.md`): Everything at a glance
- **Temporal organization**: `2025-09-16-feature.md` tells a story
- **Quick capture**: One-liner bugs and ideas
- **Progressive disclosure**: Only see what you need
- **Drift detection**: Auto-fixes broken links and orphaned docs

### 🎨 Works Your Way
- **Any directory**: `.claude/`, `.github/`, `docs/`, wherever you want
- **Any methodology**: Agile, waterfall, "whatever works"
- **Any AI**: Claude, GPT-4, Copilot, Cursor - we support 9+
- **Any project**: JavaScript, Python, Go, Rust - language agnostic

## 🚀 Quick Start

```bash
# Install (from anywhere)
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash

# That's it! The wizard will:
# 1. 🔍 Detect your setup
# 2. 📍 Ask where to put docs
# 3. ✅ Let you select frameworks (arrow keys + space)
# 4. 🚀 Configure everything
# 5. 📝 Show next steps
```

**Already installed?**
```bash
./wizard.sh           # Add frameworks or reconfigure
./wizard.sh --update  # Update to latest version
./wizard.sh --help    # See all options
```

**Automated updates** (for CI/CD or cron):
```bash
# Add to cron for weekly updates
0 0 * * 0 /path/to/project/wizard.sh --update
```

## 🛠 Supported Frameworks

Our adapter system lets you run multiple frameworks simultaneously:

| Framework | What It Does | Creates |
|-----------|--------------|---------|
| **spec-kit** | GitHub's specification toolkit | `.github/` structure, memory system |
| **bmad-method** | Multi-agent AI coordination | Agent configs, task orchestration |
| **agent-os** | Dated specs methodology | `YYYY-MM-DD-feature/` folders |
| **aider** | AI pair programming | `CONVENTIONS.md` |
| **cursor** | Cursor IDE integration | `.cursorrules` |
| **continue** | Continue.dev assistant | `.continuerules` |

Mix and match! Run spec-kit + aider + cursor together. They won't conflict.

## 📂 How It Works

```
your-project/
├── CLAUDE.md          # AI instructions (auto-detected)
└── docs/              # Or .claude/ or .github/ - you choose
    ├── bootstrap.md   # Router - loads only what's needed (v5.0)
    ├── GATES.xml      # Immutable compliance checks (v5.0)
    ├── CONTEXT.md     # Dynamic context based on work (v5.0)
    ├── MINIMAL.md     # Default minimal context (v5.0)
    ├── current.md     # Dashboard - single source of truth
    ├── bugs.md        # One-liner bug tracker
    ├── ideas.md       # Feature backlog
    ├── log.md         # Temporal event log
    ├── active/        # What you're building now
    │   ├── 01-feature.md
    │   └── 02-bugfix.md
    ├── completed/     # What you've shipped
    │   ├── 2025-09-14-auth-system.md
    │   └── 2025-09-16-api-refactor.md
    └── procedures/    # How to do things
        └── deployment.md
```

**The Magic**: Documentation lives where you work. Update it as you code. One-liner captures for bugs. Progressive disclosure that scales.

## 🗺 Roadmap

### ✅ Released
- [x] **v5.0.0** (Sept 2025): 82% token reduction, dynamic context loading, KV-cache optimization
- [x] **v4.0.0** (Sept 2025): Modular spec-specific rules, compliance review system
- [x] **v3.1.0** (Sept 2025): Single-file wizard, self-updating, 6 frameworks
- [x] **v3.0.0** (Sept 2025): Multi-framework support
- [x] **v2.0.0** (Sept 2025): Intelligent auto-detection
- [x] **v1.0.0** (Sept 2025): Core framework

### 🚧 In Development
- [ ] **Testing Suite**: Automated tests for all features
- [ ] **Examples Library**: Real-world templates

### 🔮 Next Up (v6.0)
Based on [community ideas](docs/ideas.md):

**Developer Experience**
- [ ] VSCode extension for navigation
- [ ] CLI tool (`ld add-bug`, `ld complete`)
- [ ] `living-docs doctor` health checks
- [ ] Monorepo support
- [ ] Template marketplace

**AI Integration**
- [ ] Chat interface for querying docs
- [ ] Auto-generate PR descriptions
- [ ] Documentation coverage analysis
- [ ] Smart documentation suggestions

**Automation**
- [ ] GitHub Actions for daily updates
- [ ] Changelog from completed tasks
- [ ] Documentation versioning with git tags
- [ ] JIRA/Linear/Asana integration

### 💭 Maybe/Experimental
- Documentation scoring & linting
- Web dashboard visualization
- Notion/Obsidian sync
- Multi-language support
- Enterprise features
- Certification program

See [bugs.md](docs/bugs.md) for known issues and [ideas.md](docs/ideas.md) for full backlog.

## 🤝 Contributing

We eat our own dog food! Check [docs/current.md](docs/current.md) to see what we're working on.

### Quick Setup for Contributors
```bash
# One-liner to start contributing
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash -s -- --dev

# This clones the repo and sets up living-docs on itself
```

### How to Help
1. Check [active work](docs/active/) to avoid duplicates
2. Browse [bugs](docs/bugs.md) for issues to fix
3. Pick from [ideas](docs/ideas.md) for features to add
4. Run `./scripts/check-drift.sh` before submitting
5. Follow our [procedures](docs/procedures/)

### Development Commands
```bash
./wizard.sh --update     # Update to latest
./wizard.sh --version    # Check version
./test-adapters.sh       # Run test suite
./scripts/check-drift.sh # Fix documentation drift
```

## 🏢 Who's Using This

- **living-docs** - This project (we dogfood!)
- **[Add your project with a PR!]**

## 📖 Philosophy

### Why Not Just Use GitHub Issues?
- `bugs.md` = Quick capture while coding
- GitHub Issues = External collaboration
- Different tools for different moments

### Why Not Force a Methodology?
You already have one. Maybe it's Agile, maybe it's "whatever works." We adapt to YOU, not the other way around.

### Why So Simple?
Complexity kills documentation. If it's not easy, it won't happen. One file, one command, one source of truth.

## 📜 License

MIT - Use it anywhere, for anything.

---

<p align="center">
<b>Make documentation so easy it happens automatically.</b><br>
<a href="https://github.com/joshwegener/living-docs">Star us on GitHub</a> if this helps your team!
</p>