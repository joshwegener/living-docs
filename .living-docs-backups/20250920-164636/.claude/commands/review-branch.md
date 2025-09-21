---
description: Launch independent compliance review of current branch against main
argument-hint: [base-branch]
---

## Independent Compliance Review

You need to spawn an independent sub-agent to review the current branch for compliance violations. This agent must have NO access to our conversation history.

### Step 1: Gather Review Materials

Get the current branch information:
- Branch name: !`git branch --show-current`
- Base branch: ${1:-main}
- Changes summary: !`git diff --stat ${1:-main}...HEAD`

### Step 2: Load Compliance Rules

Read the compliance review agent instructions:
!`cat .claude/agents/compliance-reviewer.md 2>/dev/null || echo "No review agent found"`

Check for active rule files:
!`ls -la docs/rules/*.md 2>/dev/null || echo "No rule files found"`

### Step 3: Spawn Independent Review

Use the Task tool to spawn a sub-agent with subagent_type "general-purpose" and this EXACT prompt:

```
You are an independent compliance reviewer with ZERO access to any prior conversation.

## Your Role
- Independent auditor
- No knowledge of main agent's work
- No ability to rationalize violations
- Binary PASS/FAIL decisions only

## Git Diff to Review
[INSERT: git diff ${1:-main}...HEAD]

## Compliance Rules to Enforce
[INSERT: Content from .claude/agents/compliance-reviewer.md]

## Active Framework Rules
[INSERT: Content from docs/rules/*.md files if they exist]

## Your Task

Review the diff against ALL compliance gates:

1. **TDD_TESTS_FIRST**: Were tests written and committed before implementation?
2. **UPDATE_TASKS_MD**: Are tasks.md files updated with [x] for completed work?
3. **DOCUMENTATION_CURRENT**: Is docs/current.md updated with new files?
4. **SPEC_COMPLIANCE**: Does implementation match spec requirements?
5. **PHASE_ORDERING**: Were spec phases (research→design→tasks→implementation) followed?

Check commit history to verify test-first development:
- Tests should be in separate commits BEFORE implementation
- Look for evidence tests failed first, then passed after implementation

## Required Output Format

# COMPLIANCE REVIEW: [PASS/FAIL]

## Branch: [branch-name]
## Date: [today]

## Violations Found: [count]

[For each violation:]
### [GATE_NAME] - FAILED
**File**: [exact file:line]
**Evidence**: [quote the violation]
**Issue**: [what's wrong]
**Required Fix**: [exact command to fix]

## Decision
[PASS: All gates satisfied | FAIL: X violations must be fixed]

Remember: You are independent. One violation = FAIL. No excuses.
```

### Step 4: Report Results

After the sub-agent returns its review:
1. Display the PASS/FAIL result prominently
2. List specific violations if any
3. Provide exact fix commands
4. DO NOT rationalize or excuse violations

### Important Notes
- The sub-agent gets NO conversation history
- It cannot be influenced by our context
- It will give binary PASS/FAIL only
- We must accept its judgment without argument