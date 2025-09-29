# TDD Remediation Plan - 007-adapter-installation

## Overview
This branch contains ~30,000 lines of changes with systematic TDD violations. This plan outlines how to remediate.

## Scope of Violations

### High-Risk Components (Security & Core)
```
lib/security/checksum.sh    - 258 lines - NO TESTS FIRST
lib/security/gpg.sh          - 356 lines - NO TESTS FIRST
lib/security/paths.sh        - 366 lines - NO TESTS FIRST
lib/security/sanitize.sh     - 227 lines - NO TESTS FIRST
lib/adapter/install.sh       - 386 lines - NO TESTS FIRST
lib/adapter/manifest.sh      - 400 lines - NO TESTS FIRST
```

### Medium-Risk Components
```
lib/validation/conflicts.sh  - 447 lines - NO TESTS FIRST
lib/validation/paths.sh       - 423 lines - NO TESTS FIRST
lib/agents/install.sh         - 484 lines - NO TESTS FIRST
```

## Remediation Phases

### Phase 1: Critical Security Functions (Week 1)
Priority: HIGHEST - Security functions need proper TDD

1. **lib/security/sanitize.sh**
   - [ ] Write failing tests for command injection prevention
   - [ ] Write failing tests for path traversal prevention
   - [ ] Implement minimal code to pass
   - [ ] Refactor for clarity

2. **lib/security/paths.sh**
   - [ ] Write failing tests for symlink detection
   - [ ] Write failing tests for restricted path access
   - [ ] Implement minimal code to pass

3. **lib/security/checksum.sh**
   - [ ] Write failing tests for integrity verification
   - [ ] Write failing tests for tampering detection
   - [ ] Implement minimal code to pass

### Phase 2: Core Installation (Week 2)
Priority: HIGH - Core functionality needs test coverage

1. **lib/adapter/install.sh**
   - [ ] Write failing integration tests
   - [ ] Write failing unit tests for each function
   - [ ] Refactor existing code to pass tests

2. **lib/adapter/manifest.sh**
   - [ ] Write failing tests for manifest operations
   - [ ] Test rollback scenarios
   - [ ] Ensure idempotency

### Phase 3: Validation & Helpers (Week 3)
Priority: MEDIUM - Supporting functions

1. **lib/validation/*.sh**
   - [ ] Write comprehensive test suites
   - [ ] Cover edge cases
   - [ ] Performance testing

## Implementation Strategy

### For Each Module:
```bash
# 1. Create test file FIRST
touch tests/unit/test_${module}.bats

# 2. Write failing test
@test "${function} fails without arguments" {
    run ${function}
    [ "$status" -eq 1 ]
}

# 3. Run test - MUST FAIL
bats tests/unit/test_${module}.bats

# 4. Write minimal implementation
# Only enough to make test pass

# 5. Run test - MUST PASS
bats tests/unit/test_${module}.bats

# 6. Refactor if needed
# Tests must still pass
```

## Acceptance Criteria

### Each Function Must Have:
- [ ] Unit test written BEFORE implementation
- [ ] Test that FAILED before implementation
- [ ] Test that PASSES after implementation
- [ ] Edge case tests
- [ ] Error handling tests
- [ ] Integration test with dependencies

## Tracking Progress

### Metrics to Track:
- Functions with test-first development: 0/87
- Tests written before implementation: 0%
- Tests that failed first: 0%
- Coverage of critical paths: 0%

## Prevention Measures

### Git Hooks Required:
```bash
#!/bin/bash
# pre-commit hook
# Reject commits with .sh files without corresponding .bats files
```

### CI Pipeline Changes:
- Enforce test file exists before implementation
- Check commit order (test commits before implementation)
- Fail builds without proper TDD evidence

## Timeline
- Week 1: Security modules (CRITICAL)
- Week 2: Core adapter functions (HIGH)
- Week 3: Validation & helpers (MEDIUM)
- Week 4: Integration testing & cleanup

## Success Criteria
- 100% of functions have tests written first
- All tests show RED → GREEN progression
- No retrospective test creation
- Clean git history showing TDD discipline

---
*This plan acknowledges current violations and provides a path to proper TDD compliance.*