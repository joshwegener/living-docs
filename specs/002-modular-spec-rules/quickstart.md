# Quickstart: Modular Spec-Specific Rules

## Prerequisites
- living-docs installed and configured
- At least one spec framework installed (spec-kit, aider, etc.)
- Bootstrap.md present in docs/

## Phase 1: Basic Setup (5 minutes)

### 1. Verify Installation
```bash
# Check installed frameworks
grep INSTALLED_SPECS .living-docs.config
# Expected: INSTALLED_SPECS="spec-kit" (or other frameworks)

# Verify bootstrap exists
ls docs/bootstrap.md
# Expected: File exists
```

### 2. Create Rule Files
```bash
# For each installed framework, create a rule file
echo "# spec-kit Rules" > docs/rules/spec-kit-rules.md
echo "See adapter rules at: adapters/spec-kit/rules.md" >> docs/rules/spec-kit-rules.md
```

### 3. Update Bootstrap
```bash
# Add rule inclusion section to bootstrap.md
cat >> docs/bootstrap.md << 'EOF'

## 🛠️ Active Framework Rules
<!-- RULES_START -->
- [spec-kit Rules](./rules/spec-kit-rules.md) - TDD phases, tasks.md enforcement
<!-- RULES_END -->
EOF
```

### 4. Test Rule Loading
```bash
# Verify rules are referenced
grep -A3 "Active Framework Rules" docs/bootstrap.md
# Expected: Shows rule file references
```

## Phase 1: Advanced Usage (10 minutes)

### Create a Spec with Tracker
```bash
# Start a new feature
./.specify/scripts/bash/create-new-feature.sh --json "test-feature"

# Create tracker file
cat > docs/active/003-test-feature-tracker.md << 'EOF'
---
spec: /docs/specs/003-test-feature/
status: planning
current_phase: 0
started: 2025-09-16
framework: spec-kit
tasks_completed: []
---

# Test Feature Implementation

Tracking implementation of test-feature spec.

## Current Status
- Phase: Planning
- Next: Create plan.md
EOF
```

### Update Tracker Progress
```bash
# After completing planning
sed -i '' 's/status: planning/status: implementing/' docs/active/003-test-feature-tracker.md
sed -i '' 's/current_phase: 0/current_phase: 1/' docs/active/003-test-feature-tracker.md
```

### Complete the Tracker
```bash
# When implementation is done
mv docs/active/003-test-feature-tracker.md \
   docs/completed/$(date +%Y-%m-%d)-test-feature-tracker.md
```

## Phase 2: Compliance Review (15 minutes)

### Setup Review Agent (Claude)
```bash
# Create compliance reviewer for Claude
mkdir -p .claude/agents
cat > .claude/agents/compliance-reviewer.md << 'EOF'
# Compliance Review Agent

## Context Requirements
- Current git diff
- Active rule files from docs/rules/
- Current tasks.md if exists

## Review Gates
1. TDD_TESTS_FIRST: Tests must exist and fail before implementation
2. TASKS_UPDATE: tasks.md must be updated when tasks complete
3. TRACKER_UPDATE: Active tracker must reflect current phase

## Output Format
PASS or FAIL with specific violations listed
EOF
```

### Run Compliance Check (Manual)
```bash
# For AI with sub-agents (Claude)
echo "/review" | pbcopy
echo "Paste this command in Claude to trigger review"

# For other AIs - spawn fresh terminal
open -a Terminal ./scripts/review-compliance.sh

# Or script-based check
./scripts/check-compliance.sh
```

### Setup Fallback Review Script
```bash
cat > scripts/check-compliance.sh << 'EOF'
#!/bin/bash
echo "Checking compliance..."

# Check for tests before implementation
if git diff --name-only | grep -q "^src/"; then
    if ! git diff --name-only | grep -q "^tests/"; then
        echo "FAIL: Implementation without tests"
        exit 1
    fi
fi

# Check tasks.md updates
if [ -f "docs/specs/*/tasks.md" ]; then
    if ! git diff --name-only | grep -q "tasks.md"; then
        echo "WARNING: tasks.md not updated"
    fi
fi

echo "PASS: Basic compliance checks passed"
EOF
chmod +x scripts/check-compliance.sh
```

## Verification Checklist

### Phase 1 Success Criteria
- [ ] Rule files created for each installed framework
- [ ] Bootstrap.md includes rule references
- [ ] Tracker files can be created and moved through lifecycle
- [ ] No errors when frameworks missing rule files (warnings only)

### Phase 2 Success Criteria
- [ ] Compliance review agent created
- [ ] Review can be triggered independently
- [ ] Failed reviews block commits (when integrated)
- [ ] Fallback methods work for non-Claude AIs

## Troubleshooting

### Rule File Not Found
```bash
# Warning appears but system continues
# Create the missing rule file:
touch docs/rules/[framework]-rules.md
```

### Bootstrap Not Updating
```bash
# Check for markers
grep "RULES_START\|RULES_END" docs/bootstrap.md
# If missing, add them manually around rule section
```

### Tracker Status Invalid
```bash
# Valid statuses:
# planning, implementing, testing, completed, blocked, failed
# Fix with:
sed -i '' 's/status: .*/status: implementing/' [tracker-file]
```

## Next Steps
1. Customize rule files for your team's workflow
2. Add project-specific gates and checks
3. Integrate compliance review into CI/CD
4. Document team conventions in framework rule files