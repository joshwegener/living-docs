# living-docs

> Make documentation so easy it happens automatically

⚠️ **ALPHA STATUS**: Core functionality works. We're using it to document itself - eating our own dog food! 🐕

[![GitHub](https://img.shields.io/github/license/joshwegener/living-docs)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-living-brightgreen)](docs/current.md)
[![Status](https://img.shields.io/badge/status-alpha-orange)](docs/current.md)

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

## 🚀 Quick Start

```bash
curl -sSL https://raw.githubusercontent.com/joshwegener/living-docs/main/wizard.sh | bash
```

That's it. One command. The wizard handles everything:
- Detects new vs existing projects
- Preserves your current structure
- Adds what's missing
- Zero config required (but fully configurable)

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

## Real Projects Using This

- **[Tmux-Orchestrator](https://github.com/your/tmux-orchestrator)**: Multi-agent AI coordination
- **[OTR Dad](https://github.com/your/otr-dad)**: 90,000 episode streaming platform
- **This project** - We use our own system

## Contributing

We eat our own dog food. Check [docs/current.md](docs/current.md) to see what we're working on.

## License

MIT - Use it anywhere, for any project.

---

> "Make documentation so easy it happens automatically."

That's the dream. We're building it.