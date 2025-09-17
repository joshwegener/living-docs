# Tasks: System Consistency Fixes

**Input**: Design documents from `/specs/001-system-consistency-fixes/`
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Found: bash-based tooling with file system operations
   → Extract: Bash 3.2+, standard unix tools, file-based storage
2. Load optional design documents:
   → data-model.md: Configuration, Documentation Structure, Archive entities
   → contracts/: configuration.schema, directory-structure.schema
   → research.md: Backwards compatibility, simple file operations
3. Generate tasks by category:
   → Setup: backup existing state
   → Tests: validation scripts for each change
   → Core: config creation, directory restructure, archive system
   → Integration: bootstrap updates, spec-kit references
   → Polish: verification, documentation updates
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → Configuration file creation ✓
   → Directory restructure ✓
   → Archive system ✓
   → Bootstrap updates ✓
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: Root-level scripts and docs/
- Configuration: `.living-docs.config` at repository root
- Documentation: `docs/` directory as configured

## Phase 3.1: Setup
- [x] T001 Backup current state (docs/, specs/, .living-docs.config if exists)
- [ ] T002 Create test environment variables for validation
- [x] T003 [P] Create validation scripts in tests/

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [x] T004 [P] Test script for configuration validation in tests/validate-config.sh
- [x] T005 [P] Test script for directory structure in tests/validate-structure.sh
- [x] T006 [P] Test script for archive functionality in tests/validate-archive.sh
- [x] T007 [P] Test script for bootstrap content in tests/validate-bootstrap.sh

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [x] T008 Create .living-docs.config with required fields
- [x] T009 Update wizard.sh to detect and use .living-docs.config
- [x] T010 Move specs/ directory to docs/specs/
- [x] T011 Update all internal references to new specs location (current.md updated)
- [x] T012 [P] Create archive-old-work.sh script
- [x] T013 Archive completed work older than 30 days to docs/archived/
- [ ] T014 Update current.md to reflect archived items

## Phase 3.4: Integration
- [x] T015 Update bootstrap.md with spec-kit command references
- [x] T016 Add dynamic content based on INSTALLED_SPECS (added commands section)
- [x] T017 Update wizard.sh to maintain configuration on updates
- [ ] T018 Add configuration migration for existing users
- [x] T019 Update drift detection to handle new structure
- [x] **BONUS**: Enhanced GATE 1 to enforce tasks.md phase order (prevents TDD violations)
- [x] **BONUS**: Enhanced GATE 3 to enforce tasks.md updates
- [x] **BONUS**: Updated CRITICAL_CHECKLIST for tasks.md tracking

## Phase 3.5: Polish
- [x] T020 [P] Verify all tests pass
- [x] T021 [P] Update docs/procedures/maintenance.md
- [x] T022 Run quickstart.md validation scenario
- [x] T023 Update log.md with completion
- [x] T024 Move task from active/ to completed/

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T017
- T010 blocks T011
- T012 blocks T013
- T013 blocks T014
- Implementation before polish (T020-T024)

## Parallel Example
```bash
# Launch T004-T007 together:
Task: "Test script for configuration validation in tests/validate-config.sh"
Task: "Test script for directory structure in tests/validate-structure.sh"
Task: "Test script for archive functionality in tests/validate-archive.sh"
Task: "Test script for bootstrap content in tests/validate-bootstrap.sh"

# Launch T012 and T015 together (different files):
Task: "Create archive-old-work.sh script"
Task: "Update bootstrap.md with spec-kit command references"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Backup before major changes
- Test on both macOS (sed -i '') and Linux (sed -i)

## Task Generation Rules
1. **Test-First**: Every implementation task has a test that must fail first
2. **Parallel-Safe**: Tasks touching different files can run simultaneously
3. **Atomic**: Each task produces a working state (no broken builds)
4. **Verifiable**: Clear success criteria for each task

## Estimated Time
- Setup: 15 minutes
- Tests: 30 minutes
- Implementation: 2 hours
- Integration: 1 hour
- Polish: 30 minutes
- **Total**: ~4 hours

## Risk Mitigation
- Backup created in T001 allows rollback
- Tests validate each change before proceeding
- Sequential implementation of critical path items
- Configuration migration handles existing installations

---
*Generated from plan.md using spec-kit /tasks workflow*