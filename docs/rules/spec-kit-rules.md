# spec-kit Framework Rules

## Gate: SPEC_WORKFLOW
**Phase**: PLANNING
**Enforcement**: MANDATORY

When working with spec-kit installed:
1. Use `.specify/scripts/bash/create-new-feature.sh --json "{name}"` to create specs
2. Follow the spec → plan → tasks workflow strictly
3. Specs live in `docs/specs/NNN-feature-name/`

## Gate: TDD_TESTS_FIRST
**Phase**: TESTING
**Enforcement**: MANDATORY
**Condition**: Tests MUST be written before implementation

Requirements:
- Tests must fail initially (RED phase)
- Git commits must show tests before implementation
- Integration tests come before unit tests
- No implementation without failing tests

Failure message: "VIOLATION: Implementation found before tests. Write failing tests first."

## Gate: UPDATE_TASKS_MD
**Phase**: IMPLEMENTATION
**Enforcement**: MANDATORY
**Condition**: tasks.md must be updated after each task completion

Requirements:
- Mark tasks [x] immediately when complete
- Don't batch updates
- Update task status in real-time
- If tasks.md exists, it must be current

Failure message: "VIOLATION: Completed task not marked in tasks.md. Update now."

## Gate: PHASE_ORDERING
**Phase**: ALL
**Enforcement**: MANDATORY

spec-kit phases must be followed in order:
1. Phase 0: Research (research.md)
2. Phase 1: Design (data-model.md, contracts/, quickstart.md)
3. Phase 2: Tasks (tasks.md)
4. Phase 3: Implementation
5. Phase 4: Validation

Failure message: "VIOLATION: Phase order not followed. Complete previous phase first."

## Workflow: Feature Development

```bash
# 1. Create spec
./.specify/scripts/bash/create-new-feature.sh --json "feature-name"

# 2. Create tracker in docs/active/
cat > docs/active/NNN-feature-tracker.md << 'EOF'
---
spec: /docs/specs/NNN-feature/
status: planning
current_phase: 0
started: YYYY-MM-DD
framework: spec-kit
tasks_completed: []
---
EOF

# 3. Run /plan command
# 4. Run /tasks command
# 5. Execute tasks in order
# 6. Update tracker status as you progress
# 7. Move tracker to completed/ when done
```

## Constitutional Requirements
- Test-Driven Development is NON-NEGOTIABLE
- Libraries must be self-contained
- CLI interface for every library
- Observability and structured logging required
- MAJOR.MINOR.BUILD versioning