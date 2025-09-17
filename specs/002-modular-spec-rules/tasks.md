# Tasks: Modular Spec-Specific Rules

**Input**: Design documents from `/specs/002-modular-spec-rules/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Bash, Markdown
   → Structure: Single project (extending wizard.sh)
2. Load optional design documents:
   → data-model.md: RuleFile, SpecTracker, BootstrapInclusion
   → contracts/: rule-loading.sh, tracker-lifecycle.sh, compliance-review.sh
   → research.md: docs/rules/ location, markdown includes
3. Generate tasks by category:
   → Setup: Directory structure, test framework
   → Tests: Contract tests for each service
   → Core: Rule loading, tracker management
   → Integration: Bootstrap updates, wizard integration
   → Polish: Documentation, edge cases
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Tasks numbered T001-T035
6. Two-phase approach per plan.md
7. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- Scripts: `scripts/` at repository root
- Tests: `tests/` at repository root
- Docs: `docs/` at repository root
- Wizard: `wizard.sh` at repository root

---

# PHASE 1: MODULAR RULE INFRASTRUCTURE

## Phase 3.1: Setup & Structure
- [x] T001 Create docs/rules/ directory for framework rule files
- [x] T002 Create tests/rules/ directory for rule loading tests
- [x] T003 [P] Create tests/tracker/ directory for tracker lifecycle tests
- [x] T004 [P] Create scripts/rules/ directory for rule management scripts

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

### Contract Tests - Rule Loading
- [x] T005 [P] Write test tests/rules/test_get_installed_specs.sh - verify parsing of .living-docs.config
- [x] T006 [P] Write test tests/rules/test_discover_rule_files.sh - verify rule file discovery logic
- [x] T007 [P] Write test tests/rules/test_validate_rule_file.sh - verify rule file validation
- [x] T008 Write test tests/rules/test_include_rules_in_bootstrap.sh - verify bootstrap update logic

### Contract Tests - Tracker Lifecycle
- [x] T009 [P] Write test tests/tracker/test_create_tracker.sh - verify tracker creation
- [x] T010 [P] Write test tests/tracker/test_update_tracker_status.sh - verify status transitions
- [x] T011 [P] Write test tests/tracker/test_complete_tracker.sh - verify tracker completion
- [x] T012 [P] Write test tests/tracker/test_tracker_info.sh - verify metadata extraction

### Integration Tests
- [x] T013 Write test tests/integration/test_wizard_rule_loading.sh - end-to-end rule loading
- [x] T014 Write test tests/integration/test_tracker_workflow.sh - complete tracker lifecycle

## Phase 3.3: Core Implementation

### Rule Loading Implementation
- [x] T015 Implement scripts/rules/rule-loading.sh::get_installed_specs() - parse .living-docs.config
- [x] T016 Implement scripts/rules/rule-loading.sh::discover_rule_files() - find rule files
- [x] T017 Implement scripts/rules/rule-loading.sh::validate_rule_file() - validate markdown
- [x] T018 Implement scripts/rules/rule-loading.sh::include_rules_in_bootstrap() - update bootstrap

### Tracker Management Implementation
- [x] T019 Implement scripts/tracker/tracker-lifecycle.sh::create_tracker() - create tracker files
- [x] T020 Implement scripts/tracker/tracker-lifecycle.sh::update_tracker_status() - status updates
- [x] T021 Implement scripts/tracker/tracker-lifecycle.sh::complete_tracker() - move to completed
- [x] T022 Implement scripts/tracker/tracker-lifecycle.sh::get_tracker_info() - extract metadata

## Phase 3.4: Framework Integration

### Wizard.sh Integration
- [x] T023 Update wizard.sh to call rule-loading.sh during bootstrap updates
- [x] T024 Add RULES_START/RULES_END markers to bootstrap.md template
- [x] T025 Update wizard.sh to handle missing rule files gracefully (warnings only)

### Create Initial Rule Files
- [x] T026 [P] Create docs/rules/spec-kit-rules.md with TDD gates and tasks.md enforcement
- [x] T027 [P] Create docs/rules/aider-rules.md with convention management rules
- [x] T028 [P] Create docs/rules/cursor-rules.md with cursor-specific workflows
- [x] T029 [P] Create docs/rules/agent-os-rules.md with agent-os patterns

---

# PHASE 2: COMPLIANCE REVIEW SYSTEM

## Phase 3.5: Compliance Tests First ⚠️ MUST COMPLETE BEFORE 3.6

### Contract Tests - Compliance Review
- [ ] T030 [P] Write test tests/compliance/test_review_compliance.sh - verify review logic
- [ ] T031 [P] Write test tests/compliance/test_check_gate.sh - verify gate validation
- [ ] T032 Write test tests/compliance/test_spawn_review.sh - verify isolation mechanism

## Phase 3.6: Compliance Implementation

### Review System Implementation
- [ ] T033 Implement scripts/compliance/compliance-review.sh::review_compliance() - main review
- [ ] T034 Implement scripts/compliance/compliance-review.sh::check_gate() - gate validation
- [ ] T035 Implement scripts/compliance/spawn-review.sh - terminal isolation script

### Review Agent Creation
- [ ] T036 [P] Create .claude/agents/compliance-reviewer.md - Claude review agent
- [ ] T037 [P] Create .github/copilot-review.md - GitHub Copilot fallback
- [ ] T038 [P] Create scripts/fresh-context-review.sh - generic AI review script

## Phase 3.7: Polish & Documentation

- [ ] T039 [P] Add comprehensive error handling to all scripts
- [ ] T040 [P] Test on macOS with BSD sed
- [ ] T041 [P] Test on Linux with GNU sed
- [ ] T042 Update docs/current.md with new rule system documentation
- [ ] T043 Create docs/procedures/rule-management.md - how to manage rules
- [ ] T044 Update README.md with modular rules feature

---

## Parallel Execution Examples

### Example 1: Run all initial tests in parallel (T005-T012)
```bash
# Using Task agents for parallel test creation
Task -p "Write test for get_installed_specs" &
Task -p "Write test for discover_rule_files" &
Task -p "Write test for validate_rule_file" &
wait
```

### Example 2: Create all rule files simultaneously (T026-T029)
```bash
# Parallel rule file creation
Task -p "Create spec-kit-rules.md" &
Task -p "Create aider-rules.md" &
Task -p "Create cursor-rules.md" &
Task -p "Create agent-os-rules.md" &
wait
```

### Example 3: Platform testing in parallel (T040-T041)
```bash
# Test on multiple platforms
Task -p "Test on macOS" &
Task -p "Test on Linux VM" &
wait
```

## Dependencies & Order

### Critical Path
1. **Setup** (T001-T004) → Must complete first
2. **Tests** (T005-T014) → Must fail before implementation
3. **Implementation** (T015-T022) → Makes tests pass
4. **Integration** (T023-T029) → Connects to wizard
5. **Phase 2 Tests** (T030-T032) → Before compliance implementation
6. **Phase 2 Implementation** (T033-T038) → Compliance system
7. **Polish** (T039-T044) → Final cleanup

### Task Groups That Can Run in Parallel
- All [P] marked tasks in same phase
- Different test files (T005-T012)
- Different rule files (T026-T029)
- Different review agents (T036-T038)
- Platform tests (T040-T041)

### Task Groups That Must Be Sequential
- Tests before their implementation
- Bootstrap updates (single file)
- Wizard.sh modifications (single file)
- Phase 1 must complete before Phase 2

## Validation Checklist

- [x] All contracts have test tasks (3 contracts → T005-T012, T030-T032)
- [x] All entities have implementation (RuleFile → T015-T018, SpecTracker → T019-T022)
- [x] Tests precede implementation (TDD enforced)
- [x] Parallel opportunities marked with [P]
- [x] Two-phase approach maintained
- [x] All user stories covered

## Notes

- Tests MUST fail first (RED phase) before implementation
- Use `set -e` in test scripts to fail fast
- Mock .living-docs.config for testing different configurations
- Test both missing and malformed rule files
- Ensure backward compatibility with existing bootstrap.md files

---
*Generated from plan.md, data-model.md, contracts/, and research.md*