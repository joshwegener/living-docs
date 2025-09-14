# Universal Spec Adapter Design

**Status**: ACTIVE
**Started**: Sept 14, 2025
**Owner**: Core Team

## 🎯 Revolutionary Insight
living-docs becomes the **universal documentation layer** that works with ANY spec/methodology system!

## Supported Spec Systems
- **GitHub Spec-Kit**: Issue templates, PR workflows, community health
- **BMAD Method**: Two-phase AI development with specialized agents
- **Agent OS**: Runtime coordination and standards
- **Custom**: Bring your own methodology

## Architecture

```
living-docs/
├── specs/                      # Spec system integrations
│   ├── github-spec-kit/
│   │   ├── sync.sh           # Fetch latest from GitHub
│   │   ├── templates/        # Spec-Kit templates
│   │   └── config.yaml       # Integration config
│   ├── bmad-method/
│   │   ├── sync.sh           # Fetch latest BMAD
│   │   ├── templates/        # BMAD workflows
│   │   └── config.yaml       # BMAD settings
│   ├── agent-os/
│   │   ├── sync.sh           # Fetch Agent OS specs
│   │   ├── templates/        # Agent OS structure
│   │   └── config.yaml       # Agent configuration
│   └── custom/
│       └── README.md          # How to add your own
```

## Setup Flow

```bash
./setup.sh my-project

# Interactive prompts:
> Choose your spec system:
  1) GitHub Spec-Kit (Community-driven development)
  2) BMAD Method (AI-driven development)
  3) Agent OS (Agent coordination)
  4) None (Just living-docs)
  5) Custom (Bring your own)

> Enable auto-updates for spec system? (y/n)
> Check for updates: daily/weekly/manual
```

## Implementation Strategy

### Phase 1: Adapter Framework
- Create spec adapter interface
- Define common integration points
- Build sync mechanism

### Phase 2: Initial Integrations
- GitHub Spec-Kit (we control this)
- BMAD Method (fetch from GitHub)
- Agent OS (if open source available)

### Phase 3: Community Specs
- Allow community to add spec systems
- Marketplace for methodologies
- Rating/review system

## Benefits
- **No Lock-in**: Switch methodologies anytime
- **Best of All Worlds**: Combine multiple approaches
- **Stay Current**: Auto-sync with upstream changes
- **Community Driven**: Everyone can contribute specs

## Update Mechanism

```yaml
# specs/github-spec-kit/config.yaml
name: GitHub Spec-Kit
source: https://github.com/joshwegener/spec-kit
version: latest
auto_update: daily
integration_points:
  - issues -> bugs.md
  - pr_template -> docs/contributing/
  - workflows -> .github/workflows/
```

## Daily Update Check
```bash
# Runs via cron or GitHub Actions
./check-spec-updates.sh

# Output:
> Checking for spec updates...
> ✓ GitHub Spec-Kit: Up to date (v1.2.3)
> ⚠ BMAD Method: Update available (v2.0.0 -> v2.1.0)
> ✓ Agent OS: Up to date (v0.9.1)
>
> Run './update-specs.sh bmad' to update BMAD Method
```

## This Changes Everything!
- living-docs becomes the **universal documentation platform**
- Works with ANY development methodology
- Developers choose their preferred spec system
- We provide the living documentation layer on top

## Next Steps
1. Refactor setup.sh to support spec selection
2. Create spec adapter framework
3. Implement GitHub Spec-Kit adapter (our own)
4. Research BMAD and Agent OS structures
5. Create documentation for adding custom specs