# Spec System Adapters

This directory contains adapters for various development methodologies and spec systems.

## Available Spec Systems

### GitHub Spec-Kit
- **Purpose**: Community-driven development with GitHub integration
- **Features**: Issue templates, PR workflows, community health files
- **Best For**: Open source projects, community collaboration

### BMAD Method
- **Purpose**: AI-driven development with two-phase approach
- **Features**: Planning agents, execution agents, workflow orchestration
- **Best For**: AI-assisted development, complex projects

### Agent OS
- **Purpose**: AI agent coordination and runtime management
- **Features**: Agent standards, coordination protocols, quality gates
- **Best For**: Multi-agent systems, AI orchestration

### Custom
- **Purpose**: Bring your own methodology
- **Features**: Template for creating custom spec adapters
- **Best For**: Proprietary methodologies, unique workflows

## How Spec Adapters Work

Each spec system provides:
1. **Templates**: Methodology-specific file templates
2. **Config**: Integration configuration
3. **Sync**: Update mechanism to stay current
4. **Docs**: How to use with living-docs

## Adding a New Spec System

1. Create directory in `specs/your-methodology/`
2. Add `config.yaml` with metadata
3. Add `sync.sh` for updates
4. Add templates and documentation
5. Submit PR with example usage

## Choosing a Spec System

Run `./setup.sh` and select from the interactive menu. You can:
- Use one spec system exclusively
- Combine multiple methodologies
- Switch between them as needed
- Create your own hybrid approach

The living-docs framework provides the documentation layer that works with any methodology!