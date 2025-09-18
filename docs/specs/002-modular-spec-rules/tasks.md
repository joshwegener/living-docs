# Implementation Tasks: Modular Spec-Specific Rules

**Spec**: 002-modular-spec-rules
**Status**: 🔴 BLOCKED - Major violations found
**Created**: 2025-09-17 (retroactively)

## Violations That Must Be Fixed First
- [ ] No plan.md was created before implementation
- [ ] Tasks.md was never created (this is being created now retroactively)
- [ ] Core feature (AI review agent) was never built
- [ ] Script falsely reports compliance when feature is missing

## Phase 1: Tests & Validation 🔴 NOT STARTED
- [ ] Create test harness for AI review agent
- [ ] Write test cases for each compliance rule
- [ ] Create mock violations to test against
- [ ] Define binary PASS/FAIL response format
- [ ] Test isolation mechanism for context window

## Phase 2: Core Implementation 🔴 NOT STARTED
- [ ] Create `.claude/agents/compliance-reviewer.md`
- [ ] Implement isolated context window mechanism
- [ ] Build `/review` command integration
- [ ] Create binary PASS/FAIL logic
- [ ] Implement specific violation reporting
- [ ] Add audit trail functionality
- [ ] Create spawn mechanism for fresh context

## Phase 3: Integration 🟡 PARTIALLY DONE
- [x] Create basic script fallback (fresh-context-review.sh)
- [x] Create compliance checking functions
- [ ] Wire up `/review` command to agent
- [ ] Test on real violations (like this one!)
- [ ] Document usage in bootstrap.md
- [ ] Update wizard.sh to install agent

## Phase 4: Fallback Methods ✅ DONE (but shouldn't be primary)
- [x] Script-based review (compliance-review.sh)
- [x] Spawned terminal review (spawn-review.sh)
- [ ] Fresh context review documentation
- [ ] Human-in-the-loop checklist

## What Actually Got Built (Out of Order)
1. Script-based compliance checking ← This was supposed to be the FALLBACK
2. Rule files in docs/rules/
3. Basic shell scripts

## What Should Have Been Built First
1. The actual AI review agent
2. Isolated context mechanism
3. /review command
4. THEN the fallback scripts

## Critical Insight
**The script says everything is fine because it can't understand what it's checking.**
Only an AI can verify:
- Were tests written before implementation?
- Does the implementation match the spec?
- Were tasks updated as work progressed?
- Are the right files in the right places?

## Next Steps
1. [ ] Acknowledge we violated our own process
2. [ ] Build the AI review agent properly
3. [ ] Use it to review this very implementation
4. [ ] It should FAIL and list these exact violations