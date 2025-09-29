# TDD Remediation - Week 2: Core Adapter Functions

**Status**: PENDING
**Priority**: HIGH
**Estimated**: 40 hours
**Debt From**: Branch 007-adapter-installation

## Overview
Fix core adapter management functions that handle installation, removal, and updates.

## Scope
Retrofit proper TDD for:
- lib/adapter/install.sh (386 lines)
- lib/adapter/manifest.sh (400 lines)
- lib/adapter/remove.sh (400 lines)
- lib/adapter/update.sh (590 lines)

## Requirements
1. Follow strict TDD cycle
2. Each function gets 3-5 test cases minimum
3. Integration tests between modules
4. Mock external dependencies properly

## Tasks
- [ ] Day 1-2: install.sh TDD retrofit
  - [ ] Test staging in temp directory
  - [ ] Test atomic moves
  - [ ] Test rollback on failure
  - [ ] Test manifest creation

- [ ] Day 2-3: manifest.sh TDD retrofit
  - [ ] Test JSON generation
  - [ ] Test file tracking
  - [ ] Test checksum validation
  - [ ] Test backup/restore

- [ ] Day 3-4: remove.sh TDD retrofit
  - [ ] Test complete removal
  - [ ] Test orphan detection
  - [ ] Test missing file handling
  - [ ] Test directory cleanup

- [ ] Day 4-5: update.sh TDD retrofit
  - [ ] Test customization preservation
  - [ ] Test diff generation
  - [ ] Test merge conflicts
  - [ ] Test version checking

## Success Criteria
- Tests demonstrate failure before implementation
- Each module has comprehensive test coverage
- Integration tests pass between modules
- No production code without failing test first

## Technical Debt Impact
These modules manage user installations without proper test foundation, risking data loss.

---
*Part of 8-week TDD remediation plan from compliance review*