# Compliance Violations - Branch 007-adapter-installation

## Review Date: 2025-09-22
## Status: FAILED
## Violations: 4

## Critical Violations Found

### 1. TDD_TESTS_FIRST - Implementation Before Tests
- **Affected Files**:
  - lib/adapter/install.sh
  - lib/adapter/manifest.sh
  - lib/adapter/prefix.sh
  - lib/adapter/rewrite.sh
  - lib/validation/conflicts.sh
  - lib/validation/paths.sh
- **Evidence**: Tests in tests/bats/ were created AFTER implementation
- **Impact**: Core TDD principle violated

### 2. TDD_TESTS_FIRST - Test Quality
- **Affected Files**: tests/bats/test_adapter_*.bats
- **Evidence**: Tests are SKIPPED, not FAILING (RED phase missing)
- **Impact**: Tests don't validate implementation properly

### 3. SPEC_WORKFLOW - Retrospective Specs
- **Affected Files**: specs/005-debug-logging/, specs/006-troubleshooting-guide/
- **Evidence**: Commit 9263b6b shows retrospective spec creation
- **Impact**: Planning phase bypassed

### 4. UPDATE_TASKS_MD - Incorrect Status
- **Affected Files**: specs/007-adapter-installation/tasks.md
- **Evidence**: Tasks marked complete despite TDD violations
- **Impact**: Misleading progress tracking

## Remediation Plan

### Immediate Actions
1. Document violations in PR description
2. Create technical debt tickets
3. Update tasks.md with actual compliance status

### Future Fixes Required
1. Write proper failing tests for lib/adapter/*
2. Write proper failing tests for lib/validation/*
3. Refactor implementation to follow TDD cycle
4. Update all skipped tests to have real assertions

## Lessons Learned
- Enforce test-first development from start
- Don't retroactively create specs
- Use CI hooks to prevent non-TDD commits
- Regular compliance reviews during development

## Technical Debt Created
- All lib/ functions lack proper TDD foundation
- Test coverage misleading (skipped vs failing)
- Specs created after implementation
- Tasks.md doesn't reflect true state

---
*This document acknowledges compliance failures for transparency and future remediation.*