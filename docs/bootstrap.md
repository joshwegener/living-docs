# Bootstrap - AI Assistant Instructions

## 📊 Project Dashboard
**@docs/current.md** - Complete project status, metrics, and documentation map

## 📁 Documentation Structure
```
/
├── CLAUDE.md or AI.md (references this bootstrap)
└── docs/
    ├── bugs.md (lightweight issue tracking)
    ├── ideas.md (feature backlog)
    ├── bootstrap.md (this file - AI instructions)
    ├── current.md (project dashboard)
    ├── log.md (one-liner updates)
    ├── active/ (current work)
    ├── completed/ (finished tasks)
    ├── issues/ (detailed bug specs)
    └── procedures/ (how-to guides)
```

## 🔄 WORKFLOW GATES (Critical Decision Points)

### ⛔ GATE 1: Starting Work
**BEFORE starting ANY task:**
```bash
ls docs/active/*task-name*  # Check if task exists
# If NO: Create it first
echo "# Task Name\n\n**Status**: 🟡 In Progress\n" > docs/active/XX-task-name.md
```

### ⛔ GATE 2: When You Find a Bug
**IMMEDIATELY when discovering a bug:**
```bash
echo "- [ ] Bug description" >> docs/bugs.md
```

### ⛔ GATE 3: Completing Work
**BEFORE saying anything is "done":**
```bash
mv docs/active/XX-feature.md docs/completed/$(date +%Y-%m-%d)-feature.md
echo "$(date '+%I:%M %p') - DEV: Completed feature-name" >> docs/log.md
```

### ⛔ GATE 4: Making Claims
**BEFORE claiming ANY feature/support:**
```bash
# TEST IT FIRST - if you didn't verify it, don't claim it
```

## 📋 Status Reporting
**ALWAYS verify before reporting:**
```bash
ls docs/active/                        # Active tasks
grep "^- \[ \]" docs/bugs.md | wc -l  # Open bugs
ls -t docs/completed/ | head -5        # Recent completions
```

## 🔗 Detailed Procedures
- **[procedures/enforcement.md](procedures/enforcement.md)** - Mandatory rules & verification
- **[procedures/common-tasks.md](procedures/common-tasks.md)** - Command reference
- **[procedures/verification.md](procedures/verification.md)** - Truth protocols (when created)

## 🎯 Key Principles
1. **Truth Over Optimism**: Report what IS, not what SHOULD BE
2. **Verify Before Claiming**: Test it or don't claim it
3. **Document As You Go**: Not after, not "later", but NOW
4. **Use the System**: This prevents documentation drift

---
*Keep docs alive by using them. Dead docs = dead project.*