# Constitution

This document defines the foundational guidelines and principles for this project.

## Core Principles

1. **Clarity**: Write specifications before implementation
2. **Consistency**: Follow established patterns and conventions
3. **Quality**: Maintain high standards for code and documentation
4. **Collaboration**: Work effectively with AI assistants and team members

## Development Process

### 1. Specification Phase
- Define clear requirements in `docs/specs/[feature-number]-[feature-name]/spec.md`
- Research and document findings
- Create data models and API contracts

### 2. Planning Phase
- Break down work into manageable tasks
- Identify dependencies and risks
- Create implementation timeline

### 3. Implementation Phase
- Follow the task breakdown
- Write tests alongside code
- Document as you go

### 4. Review Phase
- Code review with team or AI
- Update documentation
- Ensure tests pass

## File Structure

```
docs/
├── memory/
│   ├── constitution.md (this file)
│   └── constitution_update_checklist.md
├── specs/
│   └── [feature-number]-[feature-name]/
│       ├── spec.md
│       ├── plan.md
│       ├── tasks.md
│       └── research.md
└── scripts/
    ├── create-new-feature.sh
    └── check-task-prerequisites.sh
```

## Specification Standards

### File Naming
- Use kebab-case for directories and files
- Prefix feature directories with numbers (01-, 02-, etc.)
- Use descriptive names

### Documentation
- Write in Markdown
- Include examples
- Keep it concise but complete

### Code Standards
- Follow language-specific conventions
- Write self-documenting code
- Add comments for complex logic

## Working with AI Assistants

### Best Practices
1. Provide clear context through specifications
2. Reference this constitution for consistency
3. Use the spec-driven workflow
4. Review AI-generated code carefully

### Communication
- Be specific in requests
- Provide examples when possible
- Iterate on unclear outputs
- Document decisions

## Updating This Document

See `constitution_update_checklist.md` for the process to update this constitution.

---

*This constitution is a living document. Update it as the project evolves.*