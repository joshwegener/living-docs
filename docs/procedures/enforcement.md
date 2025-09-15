# Enforcement Rules - Detailed Procedures

## 🚨 MANDATORY ENFORCEMENT RULES

### Before ANY Status Report
**YOU MUST RUN THESE COMMANDS FIRST:**
```bash
ls -la docs/active/        # See what's ACTUALLY active
ls -la docs/completed/      # See what's ACTUALLY done
head -20 docs/bugs.md      # See ACTUAL bugs
wc -l docs/ideas.md        # Count ACTUAL ideas
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
echo "- [ ] [Bug description]" >> docs/bugs.md
```

### After Completing Task
**TRIGGER**: Task finished
**ACTION**:
```bash
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
grep "Z" docs/bugs.md  # Check if Z appears in bugs
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

## ⚠️ FINAL WARNING
**Breaking these rules means living-docs becomes dead-docs. You created this system to prevent documentation drift. USE IT CORRECTLY.**