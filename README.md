# living-docs

> Documentation that evolves with your project

⚠️ **ALPHA STATUS**: This project is in early development. Core functionality works but expect breaking changes. We're using it to document itself - eating our own dog food! 🐕

[![GitHub](https://img.shields.io/github/license/joshwegener/living-docs)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-living-brightgreen)](docs/current.md)
[![Status](https://img.shields.io/badge/status-alpha-orange)](docs/current.md)

## 🎯 The Problem

Every project starts with good documentation intentions. Then reality hits:
- Documentation drifts from reality
- Team members can't find what they need
- Updates happen in code but not in docs
- Knowledge gets lost in Slack threads and closed PRs
- Different methodologies fight for control

**Result**: Dead documentation that nobody trusts or maintains.

## 💡 The Solution

**living-docs** is a universal documentation framework that stays alive by integrating with your actual workflow AND your preferred development methodology:

- **Documentation Repair**: Add to ANY existing project with minimal friction
- **Universal Spec Adapter**: Works with GitHub Spec-Kit, BMAD Method, Agent OS, or your custom approach
- **AI Agnostic**: Supports Claude, ChatGPT, Copilot, Cursor, JetBrains AI, or any assistant
- **Configurable Paths**: Put docs anywhere (.docs/, .claude/docs/, .github/docs/, etc.)
- **Auto-Discovery**: Detects existing methodologies and suggests organization
- **Behavior vs Reference Separation**: Core rules stay accessible, detailed procedures stay organized
- **Temporal Organization**: Track what was done when with dated completions
- **Progressive Disclosure**: Dashboard → Active work → Detailed procedures
- **Living System**: Documentation updates are part of the workflow, not an afterthought
- **Auto-Updates**: Stay current with your chosen methodology

## 🚀 Quick Start

### One-Line Install (Recommended)

Open your project directory and run:

```bash
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```

That's it! The wizard will guide you through everything.

### Alternative: Clone and Run

```bash
git clone https://github.com/joshwegener/living-docs.git
./living-docs/wizard.sh
```

The wizard automatically:
- ✓ Detects if you're in a new or existing project
- ✓ Guides you through all configuration options
- ✓ Sets up everything based on your choices
- ✓ Works with your existing methodology

### 🔮 The Wizard Experience

The intelligent wizard will:
1. **Detect** - New project? Existing project? Already configured?
2. **Guide** - Interactive prompts for every choice
3. **Configure** - Documentation location, AI assistant, methodology
4. **Setup** - Creates the right structure for your needs
5. **Succeed** - You're ready to document!

## 📂 Structure

```
your-project/
├── PROJECT.md          # Core behavior guidance (or CLAUDE.md for AI projects)
├── bugs.md            # Lightweight bug tracking
└── docs/
    ├── current.md     # Status dashboard
    ├── log.md         # One-liner history
    ├── active/        # Current priorities
    ├── completed/     # Dated completions
    ├── issues/        # Detailed bug specs
    ├── procedures/    # Step-by-step guides
    └── templates/     # Reusable formats
```

## 🎯 Real-World Battle Testing

This framework powers:
- **[Tmux-Orchestrator](examples/tmux-orchestrator/)**: AI agent orchestration across tmux sessions
- **[OTR Dad](examples/web-application/)**: 90,000 episode streaming platform
- Multiple enterprise AI projects (case studies coming)

## 🔗 Integrations

### GitHub Spec-Kit
Seamlessly integrates with GitHub's issue templates, PR workflows, and community health files.

### AI Agent Systems
- Optimized for multi-agent coordination
- Clear behavior guidance with CLAUDE.md
- Tested with Claude, GPT-4, and open-source models

## 📚 Documentation

- [Quick Start Guide](docs/procedures/quick-start.md)
- [Migration Guide](docs/procedures/migration-guide.md)
- [Architecture Principles](docs/procedures/architecture-principles.md)
- [Current Project Status](docs/current.md) - See how we use our own system

## 🤝 Contributing

We use our own system for development. Check our [current work](docs/current.md) and [contribution guide](docs/contributing/CONTRIBUTING.md).

**Note**: We use GitHub Spec-Kit for living-docs development (see `.github/`). This is OUR choice - you can use ANY methodology with living-docs!

## 📄 License

MIT - Use it anywhere, for any project.

---

**The insight**: Most documentation dies because it's separate from work. living-docs makes documentation part of the workflow, not an afterthought.