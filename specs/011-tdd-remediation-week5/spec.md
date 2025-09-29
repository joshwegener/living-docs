# TDD Remediation - Week 5-6: UI & Integration

**Status**: PENDING
**Priority**: MEDIUM
**Estimated**: 60 hours
**Debt From**: Branch 007-adapter-installation

## Overview
Complete TDD retrofit for UI components and comprehensive integration testing.

## Scope - Week 5
Retrofit proper TDD for:
- lib/ui/progress.sh (434 lines)
- lib/docs/mermaid.sh (807 lines)
- lib/a11y/check.sh (956 lines)

## Scope - Week 6
Create comprehensive integration tests:
- Multi-adapter installation scenarios
- Custom path configurations
- Update/rollback workflows
- Security validation chains

## Requirements
1. UI components need mock terminal testing
2. Integration tests must be deterministic
3. Test fixtures for all scenarios
4. CI/CD integration

## Week 5 Tasks
- [ ] progress.sh: Test progress bars, spinners
- [ ] mermaid.sh: Test diagram generation
- [ ] a11y/check.sh: Test accessibility validation

## Week 6 Tasks
- [ ] End-to-end adapter lifecycle tests
- [ ] Multi-tool installation tests
- [ ] Failure recovery tests
- [ ] Performance regression tests

## Success Criteria
- UI components testable without terminal
- Integration tests run in CI
- All paths through wizard.sh tested
- Performance benchmarks met

## Technical Debt Impact
UI and integration layers untested, making refactoring risky.

---
*Part of 8-week TDD remediation plan from compliance review*