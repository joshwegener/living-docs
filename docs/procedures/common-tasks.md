# Common Tasks - Command Reference

## 🛠️ Quick Commands

### Bug Management
```bash
# Add a bug
echo "- [ ] Bug description" >> docs/bugs.md

# Mark bug as fixed
# Edit docs/bugs.md and change - [ ] to - [x]
```

### Idea Management
```bash
# Add an idea
echo "- [ ] Feature idea" >> docs/ideas.md
```

### Task Management
```bash
# Start a new task
echo "# Task Name\n\n**Status**: 🟡 In Progress\n" > docs/active/XX-task-name.md

# Complete a task
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md
```

### Log Updates
```bash
# Update log with any action
echo "$(date '+%I:%M %p') - Role: Action taken" >> docs/log.md

# Roles: PM, DEV, QA, DOC
```

### Status Checks
```bash
# Check current work
ls docs/active/

# Check recent completions
ls -t docs/completed/ | head -5

# Count open bugs
grep "^- \[ \]" docs/bugs.md | wc -l

# Count ideas
grep "^- \[ \]" docs/ideas.md | wc -l
```

### Git Operations
```bash
# Commit progress (every 30 minutes)
git add -A && git commit -m "Progress: [specific description]"
```

### Testing
```bash
# Test wizard.sh installation
mkdir -p /tmp/test-living-docs
cd /tmp/test-living-docs
bash /path/to/wizard.sh
```

## 📋 Status Reporting Commands
When asked for project status, run these in order:
1. `ls docs/active/` - Active tasks
2. `grep "^- \[ \]" docs/bugs.md | wc -l` - Open bugs
3. `grep "^- \[ \]" docs/ideas.md | wc -l` - Ideas count
4. `ls -t docs/completed/ | head -5` - Recent completions