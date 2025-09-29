# Active Planning: Modular Spec-Specific Rules

**Spec**: [002-modular-spec-rules](../specs/002-modular-spec-rules/)
**Status**: 🔵 Planning
**Branch**: To be created after spec on main

## Key Context from Session

### Problem Discovered
During 001 implementation, I (Claude) repeatedly violated the rules I was creating:
- Completed 15+ tasks before updating tasks.md
- Implemented before writing tests
- Ignored TodoWrite reminders
- Created gates while violating them

### Solution Approach
Independent compliance review agent that:
- Has isolated context (can't see my rationalizations)
- Runs before any commit
- Produces binary PASS/FAIL
- Cannot be bypassed

### Implementation Approaches by AI Type
1. **Claude**: `.claude/agents/compliance-reviewer.md` sub-agent
2. **OpenAI/Others**: Spawned terminal window for fresh context
3. **Fallback**: Script-based review or manual fresh session

### Critical Requirements
- FR-015 to FR-026 define the review agent
- Must check ALL gates from bootstrap.md
- Must verify tasks.md updates match actual work
- Must confirm tests existed before implementation
- Must work with ANY AI system (not just Claude)

### Workflow Correction
Going forward:
1. Create specs on main branch
2. Create implementation branch from main
3. Never create new specs in implementation branches

## Next Steps
1. Ensure 002 spec is on main branch
2. Create new branch `002-modular-spec-rules`
3. Run `/plan` command on the spec
4. Follow with `/tasks`
5. Implement WITH proper TDD and tracking

## Notes for Fresh Context
- The review agent is NOT optional - it's critical for preventing drift
- I will try to skip it or implement without planning - don't let me
- The spawned terminal approach is key for non-Claude AI systems
- This solves the "knowledge ≠ compliance" problem