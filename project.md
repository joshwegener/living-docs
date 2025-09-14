# PROJECT.md - living-docs Development Guidelines

This file provides guidance for contributors working on the living-docs framework itself.

## 📚 Documentation System
**@docs/current.md** - Complete project documentation map and status dashboard

## Status Reporting
When asked for status, provide:
1. **Active Tasks**: 8 specs in docs/active/ (3 HIGH, 1 MEDIUM priority)
2. **Open Bugs**: Check bugs.md for count and priorities
3. **Ideas Backlog**: 25+ ideas in ideas.md
4. **Recent Completions**: Spec-kit integration, status reporting templates
5. **Current Focus**: Documentation system bootstrap

## Project Mission

Create a documentation framework that actually stays alive and useful throughout a project's lifecycle.

## Our Development Methodology

**We use GitHub Spec-Kit** for community collaboration on living-docs development. This is visible in our `.github/` directory.

**This is OUR choice** - users of living-docs can choose ANY methodology or none at all. We show our implementation as a real-world example, not a requirement.

## Development Principles

### Core Philosophy
- **Dogfood Everything**: We use our own system to manage this project
- **Simplicity First**: If it's complex, it won't be maintained
- **Universal Application**: Must work for solo projects to enterprise teams
- **Tool Agnostic**: Should work with any development stack

### Quality Standards
- Every feature must have examples
- Templates must be self-documenting
- Migration tools must preserve existing work
- Documentation must be accessible to non-technical users

## Repository Structure

### Our Own Documentation (Dogfooding)
- `docs/` - Our actual project documentation using the system
- `bugs.md` - Our lightweight issue tracking
- `PROJECT.md` - This file, our behavior guidance

### Framework Components
- `templates/` - Templates for other projects
- `examples/` - Real-world usage examples
- `generators/` - Tools for setup and migration
- `integrations/` - Third-party tool integrations

## Contribution Workflow

1. **Check Dashboard**: Review `docs/current.md` for current priorities
2. **Pick Task**: Choose from `docs/active/` or create new in `docs/issues/`
3. **Update Status**: Move task to active, update dashboard
4. **Complete Work**: Implement, test, document
5. **Close Task**: Move to `docs/completed/` with date prefix

## Testing Requirements

Before merging any PR:
- [ ] Examples still work
- [ ] Templates are valid
- [ ] Setup script runs successfully
- [ ] Migration tools handle edge cases
- [ ] Documentation is updated

## Design Decisions

### Why Not Use GitHub Issues?
- GitHub handles external community interaction
- Our system handles internal workflow
- No duplication, each tool for its strength

### Why Separate bugs.md?
- Quick capture without bureaucracy
- Promotes to `docs/issues/` when investigation needed
- Keeps barrier to reporting low

### Why Dated Completions?
- Creates historical record
- Enables "what changed when" analysis
- Provides accountability trail

## Release Process

1. Update `docs/current.md` with release status
2. Tag version in git
3. Update examples to latest version
4. Announce in relevant communities

## Support Channels

- **Issues**: Use `bugs.md` for quick reports
- **Discussions**: GitHub Discussions for community
- **Examples**: See `examples/` for implementation patterns

---

Remember: We're building documentation that developers actually want to maintain.