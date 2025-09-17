# cursor Framework Rules

## Gate: CURSOR_RULES_CURRENT
**Phase**: PLANNING
**Enforcement**: MANDATORY
**Condition**: .cursorrules must be current and comprehensive

Requirements:
- Generate rules with `.cursor/scripts/generate-rules.sh`
- Update when project structure changes
- Include project-specific patterns
- Document architectural decisions

Failure message: "VIOLATION: .cursorrules out of date. Run generate-rules.sh"

## Gate: COMPOSER_WORKFLOW
**Phase**: IMPLEMENTATION
**Enforcement**: RECOMMENDED

When using Cursor Composer:
1. Start with clear, complete prompts
2. Review generated code before accepting
3. Test immediately after generation
4. Refactor for consistency

## Gate: AI_CONTEXT
**Phase**: ALL
**Enforcement**: MANDATORY

Cursor context management:
- Keep .cursorrules updated
- Use @-mentions for specific files
- Leverage codebase indexing
- Clear context when switching features

## Workflow: Cursor Development

```bash
# 1. Update rules before starting
./.cursor/scripts/generate-rules.sh

# 2. Create tracker
echo "# Feature" > docs/active/feature-tracker.md

# 3. Use Composer for scaffolding
# @file1 @file2 "Create a service that..."

# 4. Use Chat for refinement
# "Refactor this to follow our patterns"

# 5. Test and iterate
npm test

# 6. Update documentation
echo "Completed feature" >> docs/log.md
```

## Best Practices
- Use Composer for large changes
- Use Chat for focused edits
- Keep .cursorrules as source of truth
- Review all AI-generated code
- Test continuously

## Cursor-Specific Features
- **Codebase Search**: Use for finding patterns
- **Terminal Integration**: Run tests without leaving editor
- **Multi-file Edits**: Let Composer handle related changes
- **AI Review**: Use Chat to review your own code

## Integration with living-docs
- Document in docs/active/ while coding
- Update .cursorrules through living-docs
- Track AI-assisted work in trackers
- Note Cursor usage in commit messages