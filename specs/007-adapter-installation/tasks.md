# Implementation Tasks: Robust Adapter Installation & Management

**Feature Branch**: `007-adapter-installation`
**Dependencies**: Bash 3.2+, sed, awk, grep, git, curl
**Estimated Tasks**: 35

## Task Overview
Implement robust adapter installation system with conflict prevention, path rewriting, manifest tracking, and safe updates. Tasks marked [P] can be executed in parallel.

## Setup Tasks (T001-T003)

### T001: Create library directory structure [X]
Create the library modules directory structure for adapter management.
```bash
mkdir -p lib/adapter lib/validation lib/agents
touch lib/adapter/{install,prefix,rewrite,manifest,remove,update}.sh
touch lib/validation/{paths,conflicts}.sh
touch lib/agents/install.sh
```

### T002: Set up test infrastructure [P] [X]
Create test directories and fixtures for adapter testing.
```bash
mkdir -p tests/fixtures tests/integration tests/unit
# Create mock adapters with various configurations
```

### T003: Create manifest JSON schema [P] [X]
Define and validate the manifest JSON schema.
- File: `lib/adapter/manifest-schema.json`
- Define all required fields per data-model.md
- Add validation function

## Contract Test Tasks (T004-T011) - Write Tests First (TDD)

### T004: Write install adapter default test [P] [X]
Implement test for basic adapter installation.
- File: `tests/unit/test_install_adapter_default.sh`
- Test manifest creation, command installation, success return

### T005: Write custom paths installation test [P] [X]
Test adapter installation with custom SCRIPTS_PATH and SPECS_PATH.
- File: `tests/unit/test_install_adapter_custom_paths.sh`
- Verify path rewriting in installed files

### T006: Write adapter removal test [P] [X]
Test complete adapter removal using manifest.
- File: `tests/unit/test_remove_adapter.sh`
- Verify all tracked files removed

### T007: Write update with customizations test [P] [X]
Test updating adapter while preserving user customizations.
- File: `tests/unit/test_update_adapter_customizations.sh`
- Verify customized files preserved

### T008: Write path validation test [P] [X]
Test detection of hardcoded paths before installation.
- File: `tests/unit/test_validate_paths.sh`
- Check for scripts/bash, .spec, memory paths

### T009: Write command prefixing test [P] [X]
Test automatic command name prefixing.
- File: `tests/unit/test_command_prefixing.sh`
- Verify prefix applied to prevent conflicts

### T010: Write conflict handling test [P] [X]
Test detection and resolution of command conflicts.
- File: `tests/unit/test_handle_conflicts.sh`
- Verify existing files preserved

### T011: Write agent installation test [P] [X]
Test installation of agent templates.
- File: `tests/unit/test_install_agents.sh`
- Verify agents installed to correct directory

## Core Library Implementation (T012-T020)

### T012: Implement manifest.sh - tracking system [X]
Create manifest management functions.
- File: `lib/adapter/manifest.sh`
- Functions: create_manifest, read_manifest, update_manifest, validate_manifest
- JSON format per data-model.md

### T013: Implement rewrite.sh - path rewriting engine [X]
Create path variable substitution engine.
- File: `lib/adapter/rewrite.sh`
- Functions: detect_paths, create_mappings, apply_rewrites
- Handle: scripts/bash → {{SCRIPTS_PATH}}, .spec → {{SPECS_PATH}}

### T014: Implement prefix.sh - command namespacing [X]
Create command prefixing logic.
- File: `lib/adapter/prefix.sh`
- Functions: generate_prefix, apply_prefix, check_conflicts
- Auto-detect when prefixing needed

### T015: Implement paths.sh - path validation [P] [X]
Create path validation functions.
- File: `lib/validation/paths.sh`
- Functions: validate_no_absolute, check_variables, verify_references
- Return validation report

### T016: Implement conflicts.sh - conflict detection [P] [X]
Create conflict detection for commands and files.
- File: `lib/validation/conflicts.sh`
- Functions: scan_existing, detect_conflicts, suggest_resolution
- Check all AI directories

### T017: Implement install.sh - safe installation [X]
Create main installation logic with temp directory.
- File: `lib/adapter/install.sh`
- Functions: stage_in_temp, validate_installation, atomic_move
- Integrate all validation and rewriting

### T018: Implement remove.sh - complete removal
Create adapter removal using manifest.
- File: `lib/adapter/remove.sh`
- Functions: load_manifest, remove_files, cleanup_directories
- Handle missing files gracefully

### T019: Implement update.sh - smart updates
Create update logic preserving customizations.
- File: `lib/adapter/update.sh`
- Functions: fetch_upstream, compare_checksums, merge_changes
- Show diffs for customized files

### T020: Implement agents/install.sh - agent support
Create agent template installation.
- File: `lib/agents/install.sh`
- Functions: detect_ai_tool, install_to_agents_dir, track_in_manifest
- Support .claude/agents, .github/copilot-agents

## Integration Tasks (T021-T027)

### T021: Integrate with wizard.sh - installation flow
Modify wizard.sh to use new installation system.
- File: `wizard.sh`
- Add safe installation option
- Call lib/adapter/install.sh

### T022: Add removal option to wizard.sh
Add adapter removal menu option.
- File: `wizard.sh`
- New option: "Remove installed adapter"
- Call lib/adapter/remove.sh

### T023: Add update checking to wizard.sh
Add adapter update checking option.
- File: `wizard.sh`
- New option: "Check for adapter updates"
- Call lib/adapter/update.sh

### T024: Create adapter listing function
Show installed adapters with versions.
- File: `wizard.sh`
- Read all manifests
- Display name, version, file count

### T025: Add dry-run mode support
Implement preview mode for operations.
- File: `lib/adapter/install.sh`
- Environment variable: LIVING_DOCS_DRY_RUN
- Show what would be done without doing it

### T026: Add no-prefix mode option
Allow disabling prefixing for single-adapter users.
- File: `lib/adapter/prefix.sh`
- Environment variable: LIVING_DOCS_NO_PREFIX
- Skip prefixing when set

### T027: Create backup/restore functions
Add manifest backup before updates.
- File: `lib/adapter/manifest.sh`
- Auto-backup before destructive operations
- Restore function for rollback

## Integration Test Tasks (T028-T032)

### T028: Test full installation flow [P]
End-to-end test of adapter installation.
- File: `tests/integration/test_full_installation.sh`
- Clone real adapter, install, verify

### T029: Test multi-adapter scenario [P]
Test installing multiple adapters without conflicts.
- File: `tests/integration/test_multi_adapter.sh`
- Install spec-kit, aider, bmad
- Verify no conflicts

### T030: Test custom path scenario [P]
Full test with non-standard paths.
- File: `tests/integration/test_custom_paths.sh`
- Set all path variables
- Verify complete rewriting

### T031: Test update workflow [P]
Test full update cycle with customizations.
- File: `tests/integration/test_update_workflow.sh`
- Install, customize, update
- Verify preservation

### T032: Test removal completeness [P]
Verify complete cleanup after removal.
- File: `tests/integration/test_removal_complete.sh`
- Install, then remove
- Check no orphan files

## Polish & Documentation Tasks (T033-T035)

### T033: Add comprehensive error handling
Improve error messages and recovery.
- All lib/*.sh files
- Add error codes and messages
- Implement rollback on failure

### T034: Update main documentation
Document new adapter management system.
- Files: `README.md`, `docs/current.md`
- Add adapter management section
- Update wizard.sh documentation

### T035: Create troubleshooting guide
Document common issues and solutions.
- File: `docs/troubleshooting-adapters.md`
- Installation failures
- Path issues, conflicts

## Parallel Execution Examples

### Batch 1: Initial Setup (can run simultaneously)
```bash
# Run all [P] marked tasks in T001-T003
Task agent="setup-1" task="T002"
Task agent="setup-2" task="T003"
```

### Batch 2: All Contract Tests (parallel TDD)
```bash
# Run T004-T011 simultaneously (all are independent test files)
Task agent="test-1" task="T004"
Task agent="test-2" task="T005"
Task agent="test-3" task="T006"
Task agent="test-4" task="T007"
Task agent="test-5" task="T008"
Task agent="test-6" task="T009"
Task agent="test-7" task="T010"
Task agent="test-8" task="T011"
```

### Batch 3: Independent Validation Libraries
```bash
# T015 and T016 can run in parallel (different files)
Task agent="validation-1" task="T015"
Task agent="validation-2" task="T016"
```

### Batch 4: Integration Tests
```bash
# T028-T032 can all run in parallel (independent scenarios)
Task agent="integration-1" task="T028"
Task agent="integration-2" task="T029"
Task agent="integration-3" task="T030"
Task agent="integration-4" task="T031"
Task agent="integration-5" task="T032"
```

## Dependencies & Order
1. **Setup** (T001-T003) must complete first
2. **Tests** (T004-T011) should be written before implementation (TDD)
3. **Core libraries** (T012-T020) can start after tests defined
4. **Integration with wizard.sh** (T021-T027) requires core libraries
5. **Integration tests** (T028-T032) require working implementation
6. **Polish** (T033-T035) can happen anytime after core done

## Success Criteria
- [ ] All contract tests pass (T004-T011)
- [ ] All integration tests pass (T028-T032)
- [ ] wizard.sh successfully uses new system
- [ ] No hardcoded paths in installed adapters
- [ ] Manifests accurately track all files
- [ ] Updates preserve customizations
- [ ] Complete removal leaves no orphans

## Notes
- Priority on T012-T014 (manifest, rewrite, prefix) as core functionality
- T017 (install.sh) integrates all other libraries
- Test with real adapters (spec-kit, aider, bmad) for validation
- Maintain backward compatibility with existing installations

---
*Tasks generated from plan.md, data-model.md, contracts/, and quickstart.md*