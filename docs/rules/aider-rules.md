# aider Framework Rules

## Gate: CONVENTIONS_CURRENT
**Phase**: IMPLEMENTATION
**Enforcement**: MANDATORY
**Condition**: CONVENTIONS.md must reflect current code patterns

Requirements:
- Update CONVENTIONS.md when introducing new patterns
- Document library choices in CONVENTIONS.md
- Keep framework decisions documented
- Update immediately, not after the fact

Failure message: "VIOLATION: New pattern not documented in CONVENTIONS.md"

## Gate: AIDER_CONTEXT
**Phase**: PLANNING
**Enforcement**: MANDATORY

When using aider:
1. Add relevant files with `.aider/commands/add.sh {files}`
2. Keep context focused - remove unneeded files
3. Use `/architect` for design discussions
4. Use `/code` for implementation

## Gate: COMMIT_DISCIPLINE
**Phase**: IMPLEMENTATION
**Enforcement**: RECOMMENDED

aider commit practices:
- Let aider make atomic commits
- Don't override aider's commit messages
- Review each commit before accepting
- Use `/undo` if changes are wrong

## Workflow: aider Session

```bash
# 1. Start aider with relevant files
aider src/feature.py tests/test_feature.py

# 2. Architect first
/architect Design a caching system for API responses

# 3. Write tests
/code Write tests for the cache system in tests/test_cache.py

# 4. Implement
/code Implement the cache system to make tests pass

# 5. Update conventions
/code Update CONVENTIONS.md with caching patterns used
```

## Best Practices
- Keep sessions focused on single features
- Use `/ask` for clarification without changes
- Use `/help` to see all commands
- Save chat logs for important design decisions
- Use `--model` flag to select appropriate model for task

## Integration with living-docs
- Document design decisions in docs/active/
- Update CONVENTIONS.md through aider
- Link aider chat logs in completed tasks
- Use aider for code, living-docs for project management