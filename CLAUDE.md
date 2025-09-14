# CLAUDE.md - living-docs AI Assistant Guidelines

## 📚 Documentation System
**@docs/current.md** - Complete project documentation map and status dashboard

## Status Reporting
When asked for status, provide:
1. **Active Tasks**: List from docs/active/ (currently 8 specs)
2. **Open Bugs**: Count from bugs.md (currently 7 open, 2 closed)
3. **Ideas Backlog**: Count from ideas.md (currently 25+ ideas)
4. **Recent Completions**: Latest from docs/completed/
5. **Current Focus**: What you're working on now

## Project Overview
living-docs is a universal documentation framework that keeps documentation alive by integrating it into the development workflow. We eat our own dog food - this project uses its own system.

## Key Principles
1. **Dogfood Everything**: Use our own system
2. **Simplicity First**: Complex = unmaintained
3. **Universal Application**: Solo to enterprise
4. **Tool Agnostic**: Any stack, any methodology

## Development Workflow
1. Check `docs/current.md` for priorities
2. Pick from `docs/active/` or `bugs.md`
3. Update documentation as you work
4. Move completed work to `docs/completed/`
5. Update `docs/log.md` with one-liner

## Testing Changes
When modifying wizard.sh or templates:
1. Test on macOS (sed -i '')
2. Test on Linux (sed -i)
3. Test all paths through wizard
4. Verify template substitutions

## Critical Files
- `wizard.sh` - The one script that does everything
- `docs/current.md` - Single source of truth
- `templates/` - What gets installed for users
- `insights.md` - Architecture decisions

## Git Discipline
- Commit every 30 minutes
- Meaningful commit messages
- Test before pushing
- Update docs with code

---
*This project demonstrates living-docs by using itself. See docs/current.md for full status.*