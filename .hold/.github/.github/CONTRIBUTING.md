# Contributing Guidelines

Thank you for your interest in contributing to this project! We welcome contributions from everyone.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/repository-name.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit your changes: `git commit -m "Add your feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

1. Install dependencies (if applicable)
2. Run tests to ensure everything works
3. Make your changes
4. Run tests again to ensure nothing is broken

## Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing code patterns
- Keep functions small and focused

## Reporting Bugs

Please use the bug report template when reporting issues.

## Suggesting Features

Please use the feature request template when suggesting new features.

## Code Review Process (CRITICAL - MANDATORY)

⚠️ **Every PR must follow this exact protocol. No exceptions.**

### 1. PR Ready → Spawn Ephemeral Reviewer
- Tell orchestrator to spawn fresh Claude Code reviewer window
- Reviewer must have completely fresh context (no development history)

### 2. Fresh Reviewer Runs Compliance Check
```bash
/review-branch
```
- Reviewer checks TDD compliance, security, architecture
- No bias from development context

### 3. Fix ALL Findings Before Merge
- Address every single finding from reviewer
- Re-run `/review-branch` until clean approval
- No partial fixes allowed

### 4. Post-Merge Version Bump (Manual)
```bash
# Update README.md version (example: v5.1.0 -> v5.1.1)
sed -i '' 's/v5\.1\.0/v5.1.1/g' README.md
```
- Patch: Bug fixes, docs
- Minor: New features, adapters
- Major: Breaking changes

### 5. Tag Release
```bash
git tag v5.1.1
git push origin v5.1.1
```

### 6. Destroy Reviewer Window
- Close ephemeral reviewer to prevent context pollution
- Critical step - do not skip

### Enforcement
- Pre-commit TDD hooks installed via `./scripts/install-tdd-hook.sh`
- GitHub Actions `tdd-enforcement.yml` blocks non-compliant PRs
- Manual checklist required in PR description

Thank you for contributing!
