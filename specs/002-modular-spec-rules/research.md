# Research: Modular Spec-Specific Rules

## Phase 1: Modular Rule Infrastructure

### Decision: Rule File Location
**Chosen**: `docs/rules/[framework]-rules.md`
**Rationale**: Keeps all documentation together, discoverable, version-controlled
**Alternatives considered**:
- `.specify/rules/` - Too hidden, framework-specific
- `templates/rules/` - Confusing with adapter templates
- Root level - Would clutter project root

### Decision: Dynamic Inclusion Method
**Chosen**: Markdown reference syntax with sed substitution
**Rationale**: Native markdown, readable in raw form, simple to implement
**Alternatives considered**:
- Shell sourcing - Not markdown-native
- Template variables - More complex parsing needed
- Symbolic links - Platform compatibility issues

### Decision: Discovery Mechanism
**Chosen**: Parse INSTALLED_SPECS from .living-docs.config
**Rationale**: Single source of truth, already maintained by wizard
**Alternatives considered**:
- Directory scanning - Could include non-installed frameworks
- Separate config file - Duplication of state
- Hard-coded list - Not maintainable

### Decision: Tracker File Format
**Chosen**: Lightweight markdown in docs/active/ with YAML frontmatter
**Rationale**: Human-readable, parseable, fits existing structure
**Alternatives considered**:
- JSON files - Less readable
- Symlinks to specs - Platform issues
- Duplicating spec content - Maintenance burden

## Phase 2: Compliance Review System

### Decision: Review Agent Location
**Chosen**: `.claude/agents/compliance-reviewer.md` (and equivalents for other AI)
**Rationale**: Clear separation, AI-specific organization
**Alternatives considered**:
- In bootstrap.md - Would bloat the file
- Separate tool - Over-engineering for current needs
- docs/procedures/ - Not AI-agent specific

### Decision: Fallback Review Methods
**Chosen**: Multiple options (spawned terminal, script, fresh context)
**Rationale**: Different AI systems have different capabilities
**Alternatives considered**:
- Single method - Wouldn't work for all AIs
- No fallback - Would exclude non-Claude users
- External service - Too complex, privacy concerns

### Decision: Review Output Format
**Chosen**: Binary PASS/FAIL with specific violation list
**Rationale**: Clear, actionable, prevents rationalization
**Alternatives considered**:
- Score-based - Too much room for interpretation
- Suggestions only - Wouldn't enforce rules
- Detailed narrative - Could enable justification of violations

## Implementation Approach

### Phase Separation Rationale
Implementing in two phases reduces risk and allows value delivery:
- Phase 1 provides immediate benefit (cleaner bootstrap)
- Phase 2 can be refined based on Phase 1 learnings
- Users get value even if Phase 2 is delayed

### Backward Compatibility
All changes will be additive:
- Existing bootstrap.md continues to work
- Missing rule files generate warnings, not errors
- Manual overrides remain possible

### Testing Strategy
- Test on both macOS (BSD sed) and Linux (GNU sed)
- Verify with multiple frameworks installed
- Test missing rule file handling
- Validate tracker file lifecycle

## Risk Mitigation

### Risk: Platform Differences
**Mitigation**: Test sed commands on both platforms, use POSIX-compatible syntax

### Risk: Rule Conflicts
**Mitigation**: Rules are additive, specific rules override general ones

### Risk: AI Circumvention
**Mitigation**: Phase 2's isolated context prevents rationalization

### Risk: Performance Impact
**Mitigation**: Simple file includes, no complex parsing, <100ms target

## Next Steps
With research complete, Phase 1 design can proceed with:
1. Rule file templates for each adapter
2. Bootstrap inclusion mechanism
3. Tracker file lifecycle implementation
4. Wizard.sh modifications