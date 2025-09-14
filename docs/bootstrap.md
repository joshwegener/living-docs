# Bootstrap - AI Assistant Instructions

## 📊 Project Dashboard
**@docs/current.md** - Complete project status, metrics, and documentation map

## 📋 Status Reporting
When asked for project status, check current.md and report:
1. **Active Tasks**: Count items in `active/` directory with priorities
2. **Open Bugs**: Count from bugs.md with severity breakdown
3. **Ideas Backlog**: Total count from ideas.md
4. **Recent Completions**: Latest 3-5 from `completed/` directory
5. **Current Focus**: Main work areas being addressed

## 📁 Documentation Structure
```
/
├── CLAUDE.md or AI.md (references this bootstrap)
├── bugs.md (lightweight issue tracking)
├── ideas.md (feature backlog)
└── docs/
    ├── bootstrap.md (this file - AI instructions)
    ├── current.md (project dashboard)
    ├── log.md (one-liner updates)
    ├── active/ (current work)
    ├── completed/ (finished tasks)
    ├── issues/ (detailed bug specs)
    └── procedures/ (how-to guides)
```

## 🔄 Workflow Patterns

### Starting Work
1. Check current.md for priorities
2. Review active/ for ongoing tasks
3. Pick from bugs.md for quick fixes

### During Work
1. Update task files in active/
2. Add one-liners to log.md for major steps
3. Commit every 30 minutes

### Completing Work
1. Move task to completed/ with date prefix
2. Update current.md if needed
3. Mark bugs as fixed in bugs.md

## 🛠️ Common Commands
```bash
# Add a bug
echo "- [ ] Bug description" >> bugs.md

# Add an idea
echo "- [ ] Feature idea" >> ideas.md

# Update log
echo "$(date '+%I:%M %p') - Role: Action taken" >> docs/log.md

# Complete a task
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md
```

## 🎯 Key Principles
- Always check current.md first for context
- Keep updates brief and factual
- Use existing documentation structure
- Don't create new files unless necessary
- Prefer editing over creating

---
*This file contains instructions for AI assistants. Project data lives in current.md*