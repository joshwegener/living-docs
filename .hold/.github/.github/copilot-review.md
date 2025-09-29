# GitHub Copilot Compliance Review

## For AI Systems Without Sub-Agent Support

Since GitHub Copilot cannot spawn independent agents, use this manual review process:

## Option 1: Script-Based Review

Run the compliance check script:
```bash
./scripts/compliance/check-compliance.sh
```

This will:
1. Check for tests before implementation
2. Verify tasks.md updates
3. Validate phase ordering
4. Output PASS/FAIL with violations

## Option 2: Fresh Context Review

1. Open a new Copilot conversation
2. Paste ONLY this instruction file
3. Paste ONLY the git diff to review
4. Ask: "Review this diff for compliance with the rules"

## Review Checklist

When reviewing manually, check:

### ☐ TDD Compliance
- [ ] Tests exist for all new implementations
- [ ] Tests were written before implementation
- [ ] Tests cover the new functionality

### ☐ Documentation Updates
- [ ] tasks.md updated if it exists
- [ ] New patterns documented in CONVENTIONS.md
- [ ] README updated if API changed

### ☐ Phase Ordering
- [ ] Spec exists before implementation
- [ ] Plan exists before tasks
- [ ] Tasks exist before code

### ☐ Git Discipline
- [ ] Commits are atomic
- [ ] Commit messages are descriptive
- [ ] Tests committed before implementation

## Command to Generate Diff for Review

```bash
# For staged changes
git diff --staged

# For last commit
git diff HEAD~1

# For branch changes
git diff main...HEAD
```

## Automated Check

```bash
# Run this before committing
./scripts/compliance/check-compliance.sh

# If it fails, fix violations before proceeding
```

## Example Violations

### TDD Violation
```
ERROR: src/feature.js has no corresponding test file
FIX: Create tests/feature.test.js with failing tests first
```

### Phase Violation
```
ERROR: Implementation without spec in docs/specs/
FIX: Create spec first with create-new-feature.sh
```

### Documentation Violation
```
WARNING: tasks.md not updated
FIX: Mark completed tasks with [x]
```