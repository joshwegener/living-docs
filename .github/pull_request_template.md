## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested these changes locally
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## ⚠️ CRITICAL PR Protocol Checklist (MANDATORY)
**Every step must be completed. No exceptions.**

### Pre-Merge (Development)
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] TDD compliance: Tests written BEFORE implementation

### Compliance Review (Required)
- [ ] **Ephemeral reviewer spawned** (fresh Claude Code window)
- [ ] **`/review-branch` executed** in fresh context
- [ ] **ALL findings addressed** (no partial fixes)
- [ ] **Clean approval received** from reviewer
- [ ] **Reviewer window destroyed** after approval

### Post-Merge (Manual Steps)
- [ ] **Version bumped** in README.md (patch/minor/major)
- [ ] **Release tagged** with `git tag vX.X.X`
- [ ] **Tag pushed** with `git push origin vX.X.X`
- [ ] **docs/log.md updated** with one-liner entry

## Version Bump Type
- [ ] **Patch** (vX.X.X) - Bug fixes, documentation
- [ ] **Minor** (vX.X.X) - New features, adapters
- [ ] **Major** (vX.X.X) - Breaking changes, architecture

**Failure to follow this protocol will result in PR rejection.**
