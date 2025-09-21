# Tasks: Security & Infrastructure Improvements

**Input**: Design documents from `/specs/004-living-docs-review/`
**Prerequisites**: plan.md (required), research.md, data-model.md, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: bash 4.0+, zero dependencies, CI/CD with GitHub Actions
2. Load optional design documents:
   → data-model.md: Extract Release, Documentation, TestSuite, Configuration entities
   → quickstart.md: Extract 5 validation scenarios
   → research.md: Extract security approach, testing framework
3. Generate tasks by category:
   → Setup: security libraries, CI/CD infrastructure
   → Tests: security validation, drift detection tests
   → Core: checksum verification, GPG signing, rollback mechanism
   → Integration: GitHub Actions, test runners, coverage
   → Polish: documentation linting, accessibility, troubleshooting
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001-T035)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All 30 functional requirements covered
   → Security tasks prioritized first
   → All quickstart scenarios testable
9. Return: SUCCESS (35 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: Main scripts at root, libraries in `lib/`, tests in `tests/`
- **Adapters**: Framework-specific in `adapters/`
- **CI/CD**: GitHub Actions in `.github/workflows/`

## Phase 3.1: Setup
- [x] T001 Create security library structure in lib/security/
- [x] T002 [P] Initialize Bats test framework in tests/bats/
- [x] T003 [P] Configure shellcheck and Vale linting in .github/
- [x] T004 [P] Set up kcov for coverage reporting

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [x] T005 [P] Security test: Checksum verification in tests/bats/test_checksum.bats
- [x] T006 [P] Security test: GPG signature validation in tests/bats/test_gpg.bats  
- [x] T007 [P] Security test: Input sanitization in tests/bats/test_sanitization.bats
- [x] T008 [P] Security test: Path traversal prevention in tests/bats/test_paths.bats
- [x] T009 [P] Infrastructure test: Rollback mechanism in tests/bats/test_rollback.bats
- [x] T010 [P] Infrastructure test: Drift detection in tests/bats/test_drift.bats
- [x] T011 [P] Infrastructure test: Progress indicators in tests/bats/test_progress.bats
- [x] T012 [P] Infrastructure test: Debug mode in tests/bats/test_debug.bats
- [x] T013 [P] Integration test: Secure installation scenario in tests/integration/test_secure_install.sh
- [x] T014 [P] Integration test: Update with rollback scenario in tests/integration/test_update_rollback.sh
- [x] T015 [P] Integration test: Drift detection scenario in tests/integration/test_drift_scenario.sh

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [x] T016 Checksum generation functions in lib/security/checksum.sh (FR-001)
- [x] T017 Checksum verification in wizard.sh update command (FR-001)
- [x] T018 [P] GPG signing functions in lib/security/gpg.sh (FR-002)
- [x] T019 [P] Input sanitization library in lib/security/sanitize.sh (FR-003, FR-004)
- [x] T020 [P] Path validation functions in lib/security/paths.sh (FR-005, FR-006)
- [x] T021 Rollback mechanism in lib/backup/rollback.sh (FR-020)
- [x] T022 Snapshot creation before updates in wizard.sh (FR-020)
- [x] T023 [P] Drift detection algorithm in lib/drift/detector.sh (FR-007, FR-008)
- [x] T024 [P] Progress indicator library in lib/ui/progress.sh (FR-018)
- [x] T025 [P] Debug mode implementation in lib/debug/logger.sh (FR-021)
- [x] T026 Dry-run mode flag handling in wizard.sh (FR-019)

## Phase 3.4: Integration
- [x] T027 GitHub Actions test pipeline in .github/workflows/test.yml (FR-012)
- [x] T028 GitHub Actions security scanning in .github/workflows/security.yml (FR-013)
- [x] T029 Release automation workflow in .github/workflows/release.yml (FR-015)
- [x] T030 Unified test runner in tests/run-tests.sh (FR-014)
- [x] T031 Coverage reporting integration with kcov (FR-014)
- [x] T032 Vale documentation linting setup in .vale.ini (FR-024)

## Phase 3.5: Polish
- [x] T033 [P] Troubleshooting guide in docs/troubleshooting.md (FR-022)
- [x] T034 [P] Mermaid diagram validation in lib/docs/mermaid.sh (FR-025)
- [x] T035 [P] Accessibility compliance checking in lib/a11y/check.sh (FR-026)

## Dependencies
- Setup (T001-T004) enables all other tasks
- Tests (T005-T015) must fail before implementation (T016-T026)
- T016-T017 (checksum) blocks T029 (release automation)
- T021-T022 (rollback) required for safe updates
- T027-T029 (CI/CD) can proceed after core security (T016-T020)
- All implementation before polish (T033-T035)

## Parallel Execution Examples

### Launch security tests together (T005-T008):
```bash
Task subagent_type=general-purpose prompt="Write failing Bats test for checksum verification in tests/bats/test_checksum.bats"
Task subagent_type=general-purpose prompt="Write failing Bats test for GPG signature validation in tests/bats/test_gpg.bats"
Task subagent_type=general-purpose prompt="Write failing Bats test for input sanitization in tests/bats/test_sanitization.bats"
Task subagent_type=general-purpose prompt="Write failing Bats test for path traversal prevention in tests/bats/test_paths.bats"
```

### Launch security libraries together (T018-T020):
```bash
Task subagent_type=general-purpose prompt="Implement GPG signing functions in lib/security/gpg.sh"
Task subagent_type=general-purpose prompt="Implement input sanitization library in lib/security/sanitize.sh"
Task subagent_type=general-purpose prompt="Implement path validation functions in lib/security/paths.sh"
```

### Launch documentation tasks together (T033-T035):
```bash
Task subagent_type=general-purpose prompt="Create troubleshooting guide in docs/troubleshooting.md"
Task subagent_type=general-purpose prompt="Implement Mermaid diagram validation in lib/docs/mermaid.sh"
Task subagent_type=general-purpose prompt="Implement accessibility compliance checking in lib/a11y/check.sh"
```

## Notes
- Security tasks (T005-T008, T016-T020) are highest priority
- All security tests must fail before implementing fixes
- wizard.sh modifications (T017, T022, T026) must be sequential
- CI/CD workflows can be developed in parallel
- Each task specifies exact file paths
- Commit after each task with descriptive message

## Functional Requirements Coverage

| Requirement | Tasks | Status |
|------------|-------|--------|
| FR-001 Checksum verification | T005, T016, T017 | Ready |
| FR-002 GPG signing | T006, T018 | Ready |
| FR-003-004 Input sanitization | T007, T019 | Ready |
| FR-005-006 Path validation | T008, T020 | Ready |
| FR-007-008 Drift detection | T010, T023 | Ready |
| FR-009-011 Documentation accuracy | T010, T023, T032 | Ready |
| FR-012-013 CI/CD testing | T027, T028 | Ready |
| FR-014 Test unification | T030, T031 | Ready |
| FR-015 Release automation | T029 | Ready |
| FR-016-017 Status tracking | T011, T024 | Ready |
| FR-018 Progress indicators | T011, T024 | Ready |
| FR-019 Dry-run mode | T026 | Ready |
| FR-020 Rollback mechanism | T009, T021, T022 | Ready |
| FR-021 Debug mode | T012, T025 | Ready |
| FR-022 Troubleshooting | T033 | Ready |
| FR-023-024 Documentation linting | T032 | Ready |
| FR-025 Mermaid support | T034 | Ready |
| FR-026 Accessibility | T035 | Ready |
| FR-027-030 Performance/Future-proofing | All tasks | Ready |

## Validation Checklist
*GATE: All must be checked before execution*

- [x] All 30 functional requirements have corresponding tasks
- [x] Security tasks prioritized first (T005-T008, T016-T020)
- [x] All tests come before implementation
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No parallel task modifies wizard.sh simultaneously
- [x] All quickstart scenarios covered by tests
- [x] CI/CD workflows properly sequenced