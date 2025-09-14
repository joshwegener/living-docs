# CLAUDE.md - AI Assistant Instructions

## Documentation System
@docs/current.md - Complete project documentation map, status dashboard, and reporting instructions

## Project Overview
{{PROJECT_DESCRIPTION}}

## Key Principles
1. Follow the documentation structure in docs/current.md
2. Update log.md with one-liner summaries after significant changes
3. Track bugs in bugs.md (one-liners, promote to issues/ for details)
4. Keep active work visible in docs/active/
5. Move completed work to docs/completed/ with dates

## Development Workflow
1. Check docs/current.md for project status
2. Review docs/active/ for current priorities
3. Make changes and test thoroughly
4. Update relevant documentation
5. Add entry to log.md when done

## Quick Commands
```bash
# Add a bug
echo "- [ ] Bug description" >> bugs.md

# Add an idea
echo "- [ ] Feature idea" >> ideas.md

# Update log
echo "$(date '+%I:%M %p') - AI: Completed task description" >> docs/log.md
```

## Project-Specific Instructions
{{CUSTOM_INSTRUCTIONS}}