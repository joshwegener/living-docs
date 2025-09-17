# Implementation Plan: Modular Spec-Specific Rules


**Branch**: `002-modular-spec-rules` | **Date**: 2025-09-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-modular-spec-rules/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
4. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
5. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
6. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
7. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
8. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Implement a two-phase modular rule system that moves framework-specific enforcement rules out of the main bootstrap.md into separate, dynamically-included rule files. Phase 1 establishes the modular infrastructure, Phase 2 adds compliance review capabilities.

## Technical Context
**Language/Version**: Bash (POSIX-compatible), Markdown
**Primary Dependencies**: sed, grep, existing living-docs wizard.sh
**Storage**: File system (markdown files, .living-docs.config)
**Testing**: Bash script testing, manual verification on macOS/Linux
**Target Platform**: macOS/Linux development environments
**Project Type**: single - CLI tool enhancement
**Performance Goals**: Instant rule loading (<100ms)
**Constraints**: Must work with sed -i differences (macOS vs Linux)
**Scale/Scope**: ~10 framework adapters, ~100 lines per rule file
**User Arguments**: Implement as two phases - Phase 1 for modular rules, Phase 2 for compliance review

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplicity**:
- Projects: 1 (enhancing existing wizard)
- Using framework directly? Yes (direct bash/markdown)
- Single data model? Yes (.living-docs.config)
- Avoiding patterns? Yes (simple file includes)

**Architecture**:
- EVERY feature as library? N/A (extending existing wizard)
- Libraries listed: N/A (script enhancement)
- CLI per library: Using existing wizard.sh commands
- Library docs: Rule files will be self-documenting markdown

**Testing (NON-NEGOTIABLE)**:
- RED-GREEN-Refactor cycle enforced? Yes
- Git commits show tests before implementation? Yes
- Order: Integration tests for rule loading first
- Real dependencies used? Yes (actual files, configs)
- Integration tests for: rule discovery, inclusion, enforcement
- FORBIDDEN: Implementation before test, skipping RED phase

**Observability**:
- Structured logging included? Yes (warnings for missing rules)
- Frontend logs → backend? N/A
- Error context sufficient? Yes (file paths, framework names)

**Versioning**:
- Version number assigned? Using existing wizard version
- BUILD increments on every change? Following wizard versioning
- Breaking changes handled? Backward compatible design

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Option 1 (Single project - extending existing structure)

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `/scripts/bash/update-agent-context.sh claude` for your AI assistant
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy (Two-Phase Approach)**:

**PHASE 1 - Modular Rule Infrastructure**:
- Test rule file discovery mechanism
- Test bootstrap inclusion system
- Test tracker lifecycle management
- Implement rule loading from .living-docs.config
- Implement bootstrap.md dynamic updates
- Implement tracker file operations
- Create rule files for each adapter
- Update wizard.sh to manage rules
- Document rule file format

**PHASE 2 - Compliance Review System**:
- Test compliance review isolation
- Test gate validation logic
- Implement review agent for Claude
- Implement fallback review methods
- Create spawn-terminal scripts
- Create audit trail system
- Test with multiple AI systems
- Document review workflows

**Ordering Strategy**:
- Phase 1 complete before Phase 2 starts
- Within each phase: Tests before implementation
- Infrastructure before features
- Mark [P] for parallel execution where possible

**Estimated Output**:
- Phase 1: 15-20 tasks
- Phase 2: 10-15 tasks
- Total: 25-35 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented (none needed)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*