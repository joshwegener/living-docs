# TDD Remediation - Week 1: Security Modules

**Status**: PENDING
**Priority**: CRITICAL
**Estimated**: 40 hours
**Debt From**: Branch 007-adapter-installation

## Overview
Fix critical security modules that were implemented without TDD. These handle command injection and path traversal prevention.

## Scope
Retrofit proper TDD for:
- lib/security/sanitize.sh (227 lines)
- lib/security/paths.sh (366 lines)
- lib/security/checksum.sh (258 lines)
- lib/security/gpg.sh (356 lines)

## Requirements
1. Write failing tests FIRST
2. Tests must actually FAIL (not skip)
3. Implement minimal code to pass
4. Refactor for clarity
5. Document RED→GREEN→REFACTOR cycle

## Tasks
- [ ] Day 1-2: sanitize.sh TDD retrofit
  - [ ] Write 20+ failing test cases
  - [ ] Test command injection scenarios
  - [ ] Test SQL injection prevention
  - [ ] Verify escaping mechanisms

- [ ] Day 2-3: paths.sh TDD retrofit
  - [ ] Write symlink detection tests
  - [ ] Test path traversal attempts
  - [ ] Test restricted directory access
  - [ ] Verify canonicalization

- [ ] Day 3-4: checksum.sh TDD retrofit
  - [ ] Test integrity verification
  - [ ] Test tampering detection
  - [ ] Test algorithm selection
  - [ ] Verify error handling

- [ ] Day 4-5: gpg.sh TDD retrofit
  - [ ] Test signature verification
  - [ ] Test key management
  - [ ] Test trust levels
  - [ ] Test failure scenarios

## Success Criteria
- All functions have tests written BEFORE implementation
- Git history shows test commits before implementation
- 100% of security-critical paths covered
- No skipped tests - all must run

## Technical Debt Impact
Currently these modules process user input without proper test coverage, creating security risk.

---
*Part of 8-week TDD remediation plan from compliance review*