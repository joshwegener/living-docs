---
description: "Implementation plan for robust adapter installation & management"
scripts:
  sh: ./scripts/update-agent-context.sh __AGENT__
  ps: ./scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

# Implementation Plan: Robust Adapter Installation & Management

**Branch**: `007-adapter-installation` | **Date**: 2025-01-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-adapter-installation/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → SUCCESS: Spec loaded from /specs/007-adapter-installation/spec.md
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → No NEEDS CLARIFICATION found - all requirements clear
   → Detect Project Type: Shell scripts (wizard.sh, adapter system)
   → Set Structure Decision: Option 1 (Single project - scripts/libraries)
3. Fill the Constitution Check section
   → Project principles: Simplicity, Universal Application, Tool Agnostic
4. Evaluate Constitution Check section
   → No violations - approach aligns with simplicity and tool-agnostic principles
   → Update Progress Tracking: Initial Constitution Check PASS
5. Execute Phase 0 → research.md
   → Research existing adapter system, path handling, manifest tracking
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, CLAUDE.md
7. Re-evaluate Constitution Check section
   → No new violations - design maintains simplicity
   → Update Progress Tracking: Post-Design Constitution Check PASS
8. Plan Phase 2 → Describe task generation approach
9. STOP - Ready for /tasks command
```

## Summary
Implement robust adapter installation system with 7 key improvements: command prefixing to prevent conflicts, safe path rewriting for custom installations, agent template support, manifest tracking for clean removal, update detection with customization preservation, temporary directory staging, and configurable per-adapter settings.

## Technical Context
**Language/Version**: Bash 3.2+ (macOS/Linux compatible)
**Primary Dependencies**: sed, awk, grep, git, curl
**Storage**: File system manifest files (.living-docs-manifest.json per adapter)
**Testing**: Shell script testing with test fixtures
**Target Platform**: macOS and Linux
**Project Type**: single (shell scripts and libraries)
**Performance Goals**: < 5 seconds for adapter installation
**Constraints**: Must work with existing wizard.sh, preserve backward compatibility
**Scale/Scope**: Support 10+ adapters, handle 100+ files per adapter

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Living-Docs Principles
- [x] **Simplicity First**: Solution uses standard shell tools, no new dependencies
- [x] **Universal Application**: Works across all environments (macOS/Linux)
- [x] **Tool Agnostic**: Supports any AI assistant framework
- [x] **Dogfood Everything**: Uses own manifest system for self-management
- [x] **Minimal Impact**: Temporary directory approach prevents partial installs

## Project Structure

### Documentation (this feature)
```
specs/007-adapter-installation/
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
lib/
├── adapter/
│   ├── install.sh       # Safe installation with temp directory
│   ├── prefix.sh        # Command prefixing logic
│   ├── rewrite.sh       # Path rewriting engine
│   ├── manifest.sh      # Manifest tracking
│   ├── remove.sh        # Complete removal
│   └── update.sh        # Update detection and merge
├── validation/
│   ├── paths.sh         # Path validation
│   └── conflicts.sh    # Conflict detection
└── agents/
    └── install.sh       # Agent template installation

tests/
├── fixtures/            # Test adapters with various configurations
├── integration/         # Full workflow tests
└── unit/               # Individual function tests
```

**Structure Decision**: Option 1 - Single project with library modules

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context**:
   - How are adapters currently installed? → Research wizard.sh flow
   - What path patterns need rewriting? → Analyze spec-kit hardcoded paths
   - How to detect command conflicts? → Study existing command structure

2. **Generate and dispatch research agents**:
   ```
   Task: "Research current wizard.sh adapter installation flow"
   Task: "Find all hardcoded path patterns in spec-kit v0.0.47"
   Task: "Analyze command naming conflicts across adapters"
   Task: "Research manifest file formats for tracking installations"
   Task: "Study git diff algorithms for smart merge capabilities"
   ```

3. **Consolidate findings** in `research.md`:
   - Current adapter system analysis
   - Path rewriting requirements
   - Manifest tracking approaches
   - Update detection strategies

**Output**: research.md with implementation approach defined

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Adapter: metadata, files, dependencies
   - Manifest: installed files, versions, customizations
   - PathMapping: original → rewritten paths
   - CommandPrefix: adapter → prefix mapping

2. **Generate API contracts** for adapter operations:
   - install_adapter(name, options) → manifest
   - remove_adapter(name) → success/failure
   - update_adapter(name) → changes applied
   - validate_paths(adapter) → validation report

3. **Generate contract tests**:
   - Test adapter installation with various configurations
   - Test path rewriting for all known patterns
   - Test command prefixing logic
   - Test manifest tracking and removal

4. **Extract test scenarios** from user stories:
   - Install spec-kit with custom paths
   - Remove adapter completely
   - Update adapter preserving customizations
   - Handle conflicting commands

5. **Update CLAUDE.md incrementally**:
   - Add adapter management context
   - Document new lib/ structure
   - Update with manifest format

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, CLAUDE.md

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Each library module → implementation task
- Each validation → test task
- Integration with wizard.sh → integration task
- Documentation updates → doc task

**Ordering Strategy**:
1. Core libraries first (manifest, rewrite)
2. Validation and safety checks
3. Integration with wizard.sh
4. Testing and documentation

**Estimated Output**: 30-35 numbered tasks in tasks.md

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)
**Phase 4**: Implementation (execute tasks following living-docs principles)
**Phase 5**: Validation (test all adapters, verify backward compatibility)

## Complexity Tracking
*No violations - solution maintains simplicity*

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
- [x] Complexity deviations documented (none)

---
*Based on living-docs principles - See CLAUDE.md*