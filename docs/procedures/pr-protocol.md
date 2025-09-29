# CRITICAL PR Protocol - MANDATORY

## Overview
ALL pull requests MUST follow this protocol. No exceptions for security fixes or urgent changes.

## PR Workflow

### 1. PR Ready Phase
When your code is complete and tests pass:
```bash
# Ensure all tests pass
./scripts/test-adapters.sh --full

# Create PR
git push origin your-branch
gh pr create --title "fix(SEC-001): Shell hardening" --body "..."
```

### 2. Spawn Ephemeral Reviewer
**CRITICAL**: Tell orchestrator to spawn ephemeral reviewer
- Reviewer opens fresh terminal window
- Reviewer runs: `/review-branch base-branch`
- Independent compliance check begins

### 3. Fix ALL Findings
- Reviewer will identify violations
- **MANDATORY**: Fix every finding, no exceptions
- Push fixes to same branch
- Repeat review if needed

### 4. Merge Protocol
After ALL findings resolved:
```bash
# Merge the PR
gh pr merge --squash

# Immediately after merge
git checkout main
git pull
```

### 5. Version Bump (REQUIRED)
```bash
# Edit README.md
# Change version (e.g., v5.1.0 -> v5.1.1)
vim README.md

# Commit version bump
git add README.md
git commit -m "chore: bump version to v5.1.1"
```

### 6. Tag Release
```bash
# Create release tag
git tag v5.1.1
git push origin main --tags

# Create GitHub release
gh release create v5.1.1 --generate-notes
```

### 7. Destroy Reviewer
- Close ephemeral reviewer window
- Clean up review artifacts

## Example Flow

```bash
# Developer completes SEC-001 fixes
git checkout -b sec-001-shell-hardening
# ... make changes ...
git commit -m "fix(security): add set -euo pipefail to all scripts"
git push origin sec-001-shell-hardening

# Create PR
gh pr create

# REQUEST REVIEWER via orchestrator
# Wait for review completion

# After fixes approved
gh pr merge --squash

# Version bump
git checkout main
git pull
vim README.md  # v5.1.0 -> v5.1.1
git commit -m "chore: bump version to v5.1.1"
git tag v5.1.1
git push origin main --tags
```

## Compliance Checklist

- [ ] Tests written BEFORE implementation (TDD)
- [ ] All tests passing
- [ ] Cross-platform tested (macOS/Linux)
- [ ] Ephemeral reviewer spawned
- [ ] `/review-branch` completed
- [ ] ALL findings fixed
- [ ] Version bumped in README
- [ ] Release tagged
- [ ] Reviewer window closed

## Security PR Additional Requirements

For SEC-001, SEC-002, and other security fixes:
- [ ] ShellCheck clean at error/warning level
- [ ] No credential exposure
- [ ] Path traversal prevented
- [ ] Input sanitization verified
- [ ] Error handling comprehensive

## Violations

Merging without following this protocol will result in:
1. Immediate revert
2. Security review required
3. TDD compliance audit
4. Possible branch protection

---
*This protocol ensures quality, security, and maintainability of living-docs.*