# Data Model: Modular Spec-Specific Rules

## Core Entities

### RuleFile
**Purpose**: Framework-specific enforcement rules
**Location**: `docs/rules/[framework]-rules.md`
**Fields**:
- `framework`: String (spec-kit, aider, cursor, agent-os)
- `version`: String (rule file version, not framework version)
- `gates`: Array of EnforcementGate
- `workflows`: Array of WorkflowDefinition
- `priority`: Integer (for conflict resolution)

**Validation**:
- Must be valid markdown
- Must include framework identifier header
- Gates must have clear PASS/FAIL criteria

### EnforcementGate
**Purpose**: Specific checkpoint that must be passed
**Fields**:
- `id`: String (unique within rule file)
- `name`: String (human-readable)
- `phase`: Enum (PLANNING, TESTING, IMPLEMENTATION, COMPLETION)
- `condition`: String (what must be true to pass)
- `enforcement`: Enum (MANDATORY, RECOMMENDED, OPTIONAL)
- `failure_message`: String (shown when gate fails)

### WorkflowDefinition
**Purpose**: Step-by-step process for framework
**Fields**:
- `id`: String
- `name`: String
- `steps`: Array of WorkflowStep
- `applies_to`: String (glob pattern for file matching)

### SpecTracker
**Purpose**: Lightweight file tracking spec implementation
**Location**: `docs/active/[NNN]-[spec-name]-tracker.md`
**Fields**:
```yaml
---
spec: /docs/specs/[NNN]-[spec-name]/
status: planning|implementing|testing|completed
current_phase: 0|1|2|3|4
started: ISO-8601 date
framework: spec-kit|aider|etc
tasks_completed: [1,2,3,4]
---
```

### BootstrapInclusion
**Purpose**: Reference to active rule files in bootstrap.md
**Location**: Within bootstrap.md designated section
**Format**:
```markdown
## 🛠️ Active Framework Rules
<!-- RULES_START -->
- [spec-kit Rules](./rules/spec-kit-rules.md) - TDD phases, tasks.md enforcement
- [aider Rules](./rules/aider-rules.md) - Convention management, review process
<!-- RULES_END -->
```

### ComplianceReviewAgent
**Purpose**: Independent review of rule compliance (Phase 2)
**Location**: `.claude/agents/compliance-reviewer.md`
**Fields**:
- `context_requirements`: Array (what to load)
- `review_gates`: Array (what to check)
- `output_format`: Enum (PASS_FAIL, DETAILED)
- `isolation_level`: Enum (FULL, PARTIAL)

## State Transitions

### SpecTracker Lifecycle
```
created (planning) → implementing → testing → completed → archived
                ↓           ↓          ↓
             blocked     blocked    failed
```

### RuleFile Activation
```
not_installed → installed → active → disabled
                    ↓         ↓
                 missing   outdated
```

## Relationships

1. **BootstrapInclusion** references multiple **RuleFile** (1:N)
2. **RuleFile** contains multiple **EnforcementGate** (1:N)
3. **RuleFile** contains multiple **WorkflowDefinition** (1:N)
4. **SpecTracker** references one **Spec** (1:1)
5. **SpecTracker** uses one **RuleFile** (N:1)
6. **ComplianceReviewAgent** validates against all active **RuleFile** (1:N)

## Configuration Schema

### .living-docs.config Addition
```bash
# Existing field used for discovery
INSTALLED_SPECS="spec-kit aider cursor"

# New optional field for rule control
RULE_ENFORCEMENT="strict|standard|relaxed"
```

## File Naming Conventions

### Rule Files
- Pattern: `[framework]-rules.md`
- Examples: `spec-kit-rules.md`, `aider-rules.md`

### Tracker Files
- Pattern: `[NNN]-[spec-name]-tracker.md`
- Examples: `002-modular-spec-rules-tracker.md`

### Review Agents
- Pattern: `compliance-reviewer.md`
- Location: Framework-specific agent directories

## Validation Rules

1. **Rule File Validation**:
   - Must exist if framework is in INSTALLED_SPECS
   - Must be valid markdown
   - Must include at least one gate

2. **Tracker Validation**:
   - spec field must point to existing spec directory
   - status transitions must be valid
   - tasks_completed must be ascending

3. **Bootstrap Validation**:
   - RULES_START/RULES_END markers must exist
   - All referenced rule files should exist
   - No duplicate framework references