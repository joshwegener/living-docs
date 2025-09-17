# Coding Conventions for Aider

This file defines coding conventions for use with [Aider AI](https://aider.chat).

## Code Style

### General Principles
- Write clear, self-documenting code
- Prefer readability over cleverness
- Follow existing patterns in the codebase
- Add comments for complex logic

### Naming Conventions
- Use descriptive variable names
- Follow language-specific conventions:
  - Python: snake_case for functions/variables, PascalCase for classes
  - JavaScript/TypeScript: camelCase for functions/variables, PascalCase for classes
  - Go: Follow Go naming conventions

### File Organization
- Group related functionality
- Keep files focused and single-purpose
- Maintain consistent directory structure

## Documentation

### Code Comments
- Explain "why" not "what"
- Document complex algorithms
- Add TODOs with ticket references

### Function Documentation
- Document public APIs
- Include parameter descriptions
- Specify return values and types
- Note any side effects

## Testing

### Test Coverage
- Write tests for new functionality
- Maintain existing test coverage
- Test edge cases and error conditions

### Test Organization
- Mirror source code structure
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

## Git Conventions

### Commit Messages
- Use present tense ("Add feature" not "Added feature")
- Keep first line under 50 characters
- Include ticket/issue reference when applicable

### Branch Naming
- feature/description-of-feature
- bugfix/description-of-bug
- hotfix/critical-issue

## Error Handling

### Error Messages
- Provide helpful, actionable error messages
- Include context about what went wrong
- Suggest potential fixes when possible

### Logging
- Use appropriate log levels
- Include relevant context
- Avoid logging sensitive information

## Security

### Best Practices
- Never commit secrets or credentials
- Validate all inputs
- Use parameterized queries for databases
- Keep dependencies up to date

## Performance

### Optimization Guidelines
- Profile before optimizing
- Prefer clarity over premature optimization
- Document performance-critical sections
- Consider memory usage in addition to speed

---

*Customize this file for your specific project needs. Aider will use these conventions when generating or modifying code.*