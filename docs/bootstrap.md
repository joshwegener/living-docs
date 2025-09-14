# Bootstrap - AI Assistant Instructions

## 🚨 MANDATORY ENFORCEMENT RULES

### Before ANY Status Report
**YOU MUST RUN THESE COMMANDS FIRST:**
```bash
ls -la docs/active/        # See what's ACTUALLY active
ls -la docs/completed/      # See what's ACTUALLY done
head -20 bugs.md           # See ACTUAL bugs
wc -l ideas.md             # Count ACTUAL ideas
```
**NEVER report status without running these commands first.**

### Before Claiming "Complete"
**YOU MUST VERIFY:**
```bash
# Is the file in completed/?
ls docs/completed/*feature-name*
# If no, IT'S NOT COMPLETE - move it first:
mv docs/active/XX-feature.md docs/completed/$(date +%Y-%m-%d)-feature.md
```

### Before Claiming "It Works"
**YOU MUST TEST:**
```bash
# Create test directory and actually run it
mkdir -p /tmp/test-living-docs
cd /tmp/test-living-docs
bash /path/to/wizard.sh
# Show the output - if it fails, IT DOESN'T WORK
```

## 📊 Project Dashboard
**@docs/current.md** - Complete project status, metrics, and documentation map

## 📋 Status Reporting (WITH VERIFICATION)
When asked for project status:
1. **FIRST** run the verification commands above
2. **THEN** report based on what you actually see:
   - **Active Tasks**: Count from `ls docs/active/`
   - **Open Bugs**: Count from `grep "^- \[ \]" bugs.md | wc -l`
   - **Ideas Backlog**: Count from `grep "^- \[ \]" ideas.md | wc -l`
   - **Recent Completions**: List from `ls -t docs/completed/ | head -5`
   - **Current Focus**: Based on active/ contents

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

## 🔄 WORKFLOW GATES (MANDATORY CHECKPOINTS)

### ⛔ GATE 1: Starting Work
**BEFORE starting ANY task:**
```bash
# CHECK: Does the task exist in active/?
ls docs/active/*task-name*
# If NO: Create it first
echo "# Task Name\n\n**Status**: 🟡 In Progress\n" > docs/active/XX-task-name.md
```

### ⛔ GATE 2: When You Find a Bug
**IMMEDIATELY when discovering a bug:**
```bash
# ADD IT NOW - not later
echo "- [ ] Bug description" >> bugs.md
# If critical, also create detailed spec
echo "# Bug Details" > docs/issues/critical-X-description.md
```

### ⛔ GATE 3: Completing Work
**BEFORE saying anything is "done":**
```bash
# 1. Move the file
mv docs/active/XX-feature.md docs/completed/$(date +%Y-%m-%d)-feature.md
# 2. Update the log
echo "$(date '+%I:%M %p') - DEV: Completed feature-name" >> docs/log.md
# 3. If it fixed bugs, mark them
# Edit bugs.md and change - [ ] to - [x]
```

### ⛔ GATE 4: Making Claims
**BEFORE claiming ANY feature/support:**
```bash
# TEST IT FIRST
# Example: "We support spec-kit"
ls -la .claude/commands/  # Do these files exist?
# If NO: You DON'T support it - add to bugs.md instead
```

## ⏰ MOMENT TRIGGERS (When → Then)

### Every 30 Minutes
**TRIGGER**: Timer/significant progress
**ACTION**:
```bash
git add -A && git commit -m "Progress: [specific description]"
```

### After Writing Code
**TRIGGER**: New function/feature added
**ACTION**:
```bash
echo "$(date '+%I:%M %p') - DEV: Added [specific feature]" >> docs/log.md
```

### After Finding Issue
**TRIGGER**: Bug discovered
**ACTION**:
```bash
echo "- [ ] [Bug description]" >> bugs.md
```

### After Completing Task
**TRIGGER**: Task finished
**ACTION**:
```bash
mv docs/active/task.md docs/completed/$(date +%Y-%m-%d)-task.md
```

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

## 🔍 TRUTH VERIFICATION PROTOCOL

### The Cardinal Rule
**"If you didn't verify it, you can't claim it."**

### Verification Commands By Claim Type

**"Feature X is complete"**
```bash
ls docs/completed/*feature-X*  # Must exist in completed/
```

**"We support Y"**
```bash
# Show working code/config that implements Y
grep -r "Y" --include="*.sh" .  # Find implementation
```

**"No bugs with Z"**
```bash
grep "Z" bugs.md  # Check if Z appears in bugs
```

**"X tasks in progress"**
```bash
ls docs/active/ | wc -l  # Count actual files
```

### Red Flags That You're Lying to Yourself
- ❌ Saying "complete" but file still in active/
- ❌ Claiming feature works but never tested it
- ❌ Reporting old status without checking current state
- ❌ Marking bugs fixed without verifying the fix
- ❌ Creating documentation without creating functionality

## 🎯 Key Principles (ENFORCED)
1. **Truth Over Optimism**: Report what IS, not what SHOULD BE
2. **Verify Before Claiming**: Run commands, see output, then speak
3. **Document As You Go**: Not after, not "later", but NOW
4. **If It's Not Tested, It's Broken**: Assume failure until proven
5. **Files Don't Lie**: Trust directory listings over memory

## ⚠️ FINAL WARNING
**Breaking these rules means living-docs becomes dead-docs. You created this system to prevent documentation drift. USE IT CORRECTLY.**

---
*This file enforces living-docs discipline. Ignore at your own peril.*