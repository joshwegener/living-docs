# Coding Standards

This document defines how we build software in this codebase.

## Code Style

### General Principles
- **Clarity over cleverness**: Write code that is easy to understand
- **Consistency**: Follow existing patterns in the codebase
- **Simplicity**: Avoid over-engineering solutions
- **Documentation**: Code should be self-documenting with clear naming

### Language-Specific Standards

#### JavaScript/TypeScript
- Use ES6+ features
- Prefer `const` over `let`, avoid `var`
- Use async/await over callbacks
- Follow Airbnb style guide

#### Python
- Follow PEP 8
- Use type hints for function signatures
- Prefer f-strings for formatting
- Use virtual environments

#### Other Languages
Document specific standards as needed.

## File Organization

### Directory Structure
```
{{AI_PATH}}/agent-os/
├── standards/       # How we build (this file)
├── product/         # What we're building
└── specs/          # What to build next
    └── YYYY-MM-DD-feature-name/
```

### File Naming
- Use kebab-case for files and directories
- Be descriptive but concise
- Date prefix for specs: YYYY-MM-DD

## Version Control

### Commit Messages
- Use present tense
- Start with a verb (Add, Fix, Update, Remove)
- Reference issue numbers when applicable
- Keep under 72 characters

### Branching
- `main` or `master` for production
- `feature/description` for new features
- `fix/description` for bug fixes
- `hotfix/description` for urgent fixes

## Testing

### Test Requirements
- Write tests for new features
- Maintain or improve coverage
- Test edge cases
- Include integration tests where needed

### Test Organization
- Mirror source structure
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

## Code Review

### Review Checklist
- [ ] Follows coding standards
- [ ] Has appropriate tests
- [ ] Documentation updated
- [ ] No security vulnerabilities
- [ ] Performance considerations addressed

## Security

### Best Practices
- Never commit secrets
- Validate all inputs
- Use parameterized queries
- Keep dependencies updated
- Follow OWASP guidelines

---

*Update this document as standards evolve.*