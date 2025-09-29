# TDD Remediation - Week 3-4: Validation & Helper Libraries

**Status**: PENDING
**Priority**: MEDIUM
**Estimated**: 60 hours
**Debt From**: Branch 007-adapter-installation

## Overview
Fix validation libraries and helper functions across two weeks.

## Scope - Week 3
Retrofit proper TDD for:
- lib/adapter/prefix.sh (353 lines)
- lib/adapter/rewrite.sh (296 lines)
- lib/validation/conflicts.sh (447 lines)
- lib/validation/paths.sh (423 lines)

## Scope - Week 4
Retrofit proper TDD for:
- lib/agents/install.sh (484 lines)
- lib/backup/rollback.sh (261 lines)
- lib/drift/detector.sh (811 lines)
- lib/debug/logger.sh (439 lines)

## Requirements
1. Maintain TDD discipline throughout
2. Test edge cases thoroughly
3. Performance testing for large projects
4. Error injection testing

## Week 3 Tasks
- [ ] prefix.sh: Test namespace collision prevention
- [ ] rewrite.sh: Test path variable substitution
- [ ] conflicts.sh: Test multi-adapter scenarios
- [ ] paths.sh: Test validation accuracy

## Week 4 Tasks
- [ ] agents/install.sh: Test AI tool detection
- [ ] backup/rollback.sh: Test restore reliability
- [ ] drift/detector.sh: Test drift detection accuracy
- [ ] debug/logger.sh: Test structured logging

## Success Criteria
- Every function has RED→GREEN→REFACTOR history
- Performance benchmarks established
- Edge cases documented and tested
- Integration tests with dependent modules

## Technical Debt Impact
These modules provide critical infrastructure without test safety net.

---
*Part of 8-week TDD remediation plan from compliance review*