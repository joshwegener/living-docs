# Feature Specification: Modular Spec-Specific Rules

**Feature Branch**: `002-modular-spec-rules`
**Created**: 2025-09-16
**Status**: Draft
**Input**: User description: "create modular spec-specific rules to be enforced in bootstrap.md via include to the ruleset that spec repo project is using"

## Execution Flow (main)
```
1. Parse user description from Input
   � Parsed: Need modular rule files per spec framework
2. Extract key concepts from description
   � Identified: modular rules, bootstrap inclusion, framework-specific enforcement
3. For each unclear aspect:
   � Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   � User flows defined for rule management
5. Generate Functional Requirements
   � Each requirement testable and clear
6. Identify Key Entities (if data involved)
   � Rule files, bootstrap references, configuration
7. Run Review Checklist
   � Check for ambiguities and implementation details
8. Return: SUCCESS (spec ready for planning)
```

---

## � Quick Guidelines
-  Focus on WHAT users need and WHY
- L Avoid HOW to implement (no tech stack, APIs, code structure)
- =e Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As an AI assistant working on a project with living-docs and spec frameworks installed, I need framework-specific rules and gates automatically included in my bootstrap instructions so that I can properly enforce the correct workflow for each installed framework without cluttering the main bootstrap with every possible framework's rules.

### Compliance Review Approaches

#### For AI Systems WITH Sub-Agent Support (Claude, etc.)
- Independent review agent in `.claude/agents/compliance-reviewer.md`
- Isolated context window prevents rationalization
- Invoked via `/review` command

#### For AI Systems WITHOUT Sub-Agent Support (GitHub Copilot, Cursor, OpenAI, etc.)
1. **Spawned Terminal/Window Review** (Recommended):
   - `scripts/spawn-review.sh` opens new terminal window
   - Fresh AI context loads ONLY review instructions + git diff
   - No access to main window's context/rationalizations
   - Returns PASS/FAIL to main terminal
   - Example: `open -a Terminal scripts/review-compliance.sh` (macOS)
   - Example: `gnome-terminal -- scripts/review-compliance.sh` (Linux)

2. **Script-Based Review**:
   - `scripts/review-compliance.sh` runs checks programmatically
   - Outputs violations to console
   - AI must acknowledge and fix before proceeding
   - Can be run in current context but less effective

3. **Fresh Context Review**:
   - User opens new conversation/session manually
   - Provides ONLY the review instructions and current git diff
   - Fresh AI context can't rationalize past decisions
   - Binary PASS/FAIL response required

4. **Human-in-the-Loop**:
   - Checklist in PR template
   - User manually verifies each gate
   - CI/CD runs compliance checks

### Acceptance Scenarios
1. **Given** a project has spec-kit installed, **When** the AI reads bootstrap.md, **Then** it should see spec-kit specific rules included automatically
2. **Given** a project has both spec-kit and aider installed, **When** the AI reads bootstrap.md, **Then** it should see both spec-kit-rules and aider-rules referenced
3. **Given** a new spec framework is installed, **When** the wizard updates the configuration, **Then** the corresponding rules file should be created and referenced
4. **Given** an AI is working from tasks.md, **When** it completes a task, **Then** the framework-specific rules should enforce immediate task.md updates
5. **Given** a spec is being implemented, **When** work begins, **Then** a tracker file should be created in docs/active/ linking to the spec
6. **Given** a spec implementation is complete, **When** the work is finished, **Then** the tracker moves to docs/completed/ but the spec stays in docs/specs/
7. **Given** an AI has completed tasks without updating tasks.md, **When** the review agent runs, **Then** it should FAIL with specific line numbers to update
8. **Given** implementation was done without tests, **When** the review agent runs, **Then** it should FAIL and require tests to be written first
9. **Given** all rules have been followed, **When** the review agent runs, **Then** it should PASS and allow commit

### Edge Cases
- What happens when a referenced rule file doesn't exist? System should warn but continue
- How does system handle conflicting rules between frameworks? Framework rules should be additive, not conflicting
- What if a framework is uninstalled? Rules reference should be removed from bootstrap
- What if the review agent itself has a bug? Manual override with documented justification should be possible
- How do AI systems without sub-agents handle this? Fallback to script-based review or fresh context review

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST maintain separate rule files for each spec framework in a designated location
- **FR-002**: System MUST dynamically include relevant rule files in bootstrap.md based on installed frameworks
- **FR-003**: Each rule file MUST contain framework-specific gates, workflows, and enforcement procedures
- **FR-004**: Bootstrap.md MUST have a dedicated section that references active framework rules
- **FR-005**: Rule files MUST be automatically discoverable based on naming convention
- **FR-006**: System MUST handle missing rule files gracefully with warnings
- **FR-007**: Rule inclusion MUST be based on .living-docs.config INSTALLED_SPECS field
- **FR-008**: Each rule file MUST enforce its framework's specific workflow (e.g., spec-kit's TDD phases)
- **FR-009**: Rules MUST enforce documentation updates (tasks.md, logs, etc.) at appropriate gates
- **FR-010**: System MUST support addition of new frameworks without modifying core bootstrap
- **FR-011**: Spec implementation tracking MUST use lightweight tracker files in docs/active/
- **FR-012**: Specs MUST remain permanently in docs/specs/ as reference documentation
- **FR-013**: Active spec trackers MUST link to their spec and show current phase/progress
- **FR-014**: Completed spec trackers MUST move to docs/completed/ while specs stay in place
- **FR-015**: System MUST provide independent compliance review agent in .claude/agents/compliance-reviewer.md
- **FR-016**: Review agent MUST have isolated context window (no access to main agent's rationalizations)
- **FR-017**: Review agent MUST check ALL bootstrap gates and framework-specific rules
- **FR-018**: Review agent MUST produce binary PASS/FAIL with specific violations listed
- **FR-019**: Review agent MUST verify tasks.md updates match actual work completed
- **FR-020**: Review agent MUST confirm tests existed and failed before implementation
- **FR-021**: Failed review MUST block commit with exact remediation commands
- **FR-022**: Review agent MUST be invokable via /review command
- **FR-023**: Review agent MUST maintain audit trail of all reviews
- **FR-024**: System MUST provide fallback review methods for AI systems without sub-agent support
- **FR-025**: Fallback methods MUST include spawned terminal, script-based, and fresh-context review options
- **FR-026**: Review instructions MUST be adaptable to different AI system capabilities

### Key Entities
- **Rule File**: Framework-specific enforcement rules stored as markdown, containing gates and workflows
- **Bootstrap Reference**: Dynamic section in bootstrap.md that includes active rule files
- **Framework Configuration**: Entry in .living-docs.config that determines which rules are active
- **Enforcement Gate**: Specific checkpoint in rule file that must be followed for that framework
- **Spec Tracker**: Lightweight file in docs/active/ that tracks implementation progress of a spec
- **Permanent Spec**: Full specification directory in docs/specs/ containing spec.md, plan.md, tasks.md
- **Compliance Review Agent**: Independent sub-agent in .claude/agents/ with isolated context that verifies all rules/gates are followed

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked (none found)
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---