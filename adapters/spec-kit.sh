#!/bin/bash
set -euo pipefail

# GitHub Spec-Kit Adapter for living-docs
# Creates and maintains GitHub community standards structure

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER_DIR="$SCRIPT_DIR/spec-kit"
TEMPLATES_DIR="$ADAPTER_DIR/templates"
# Allow custom location via environment variable
TARGET_DIR="${SPEC_LOCATION:-.github}"
VERSION_FILE="$ADAPTER_DIR/version.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function: Show usage
show_usage() {
    cat << EOF
GitHub Spec-Kit Adapter for living-docs

Usage: $0 <command>

Commands:
    install     Install GitHub community standards structure
    update      Check for and apply updates to templates
    validate    Validate current installation
    test        Run adapter tests
    help        Show this help message

Examples:
    $0 install          # Install .github/ structure
    $0 validate         # Check installation integrity
    $0 update           # Update templates to latest versions

EOF
}

# Function: Initialize adapter directory structure
init_adapter() {
    if [[ ! -d "$ADAPTER_DIR" ]]; then
        log_info "Creating adapter directory structure..."
        mkdir -p "$ADAPTER_DIR"
        mkdir -p "$TEMPLATES_DIR/ISSUE_TEMPLATE"
    fi
}

# Function: Create version tracking file
create_version_file() {
    cat > "$VERSION_FILE" << EOF
{
  "version": "1.0.0",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "living-docs/spec-kit",
  "templates": {
    "bug_report": "1.0.0",
    "feature_request": "1.0.0",
    "pull_request": "1.0.0",
    "contributing": "1.0.0",
    "code_of_conduct": "1.0.0",
    "security": "1.0.0"
  }
}
EOF
}

# Function: Create template files
create_templates() {
    log_info "Creating template files..."

    # Create ISSUE_TEMPLATE directory
    mkdir -p "$TEMPLATES_DIR/ISSUE_TEMPLATE"

    # Bug report template
    cat > "$TEMPLATES_DIR/ISSUE_TEMPLATE/bug_report.md" << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
- OS: [e.g. macOS, Linux, Windows]
- Version: [e.g. 0.2.0]
- Node.js version: [if applicable]

**Additional context**
Add any other context about the problem here.
EOF

    # Feature request template
    cat > "$TEMPLATES_DIR/ISSUE_TEMPLATE/feature_request.md" << 'EOF'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF

    # Issue template config
    cat > "$TEMPLATES_DIR/ISSUE_TEMPLATE/config.yml" << 'EOF'
blank_issues_enabled: false
contact_links:
  - name: Community Discussion
    url: https://github.com/discussions
    about: Please ask and answer questions here.
EOF

    # Pull request template
    cat > "$TEMPLATES_DIR/pull_request_template.md" << 'EOF'
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] I have tested these changes locally
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Checklist
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
EOF

    # Contributing guide
    cat > "$TEMPLATES_DIR/CONTRIBUTING.md" << 'EOF'
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

## Code Review Process

1. All submissions require review
2. We may suggest changes or improvements
3. Once approved, your PR will be merged

Thank you for contributing!
EOF

    # Code of Conduct
    cat > "$TEMPLATES_DIR/CODE_OF_CONDUCT.md" << 'EOF'
# Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

## Our Standards

Examples of behavior that contributes to a positive environment include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior include:

* The use of sexualized language or imagery and unwelcome sexual attention or advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information without explicit permission
* Other conduct which could reasonably be considered inappropriate in a professional setting

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported by contacting the project team. All complaints will be reviewed and
investigated promptly and fairly.

Project maintainers are responsible for clarifying the standards of acceptable
behavior and are expected to take appropriate and fair corrective action in
response to any instances of unacceptable behavior.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org),
version 2.0, available at https://www.contributor-covenant.org/version/2/0/code_of_conduct.html.
EOF

    # Security policy
    cat > "$TEMPLATES_DIR/SECURITY.md" << 'EOF'
# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible
for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

Please report security vulnerabilities by emailing [security contact].

Do not report security vulnerabilities through public GitHub issues.

You should receive a response within 48 hours. If for some reason you do not,
please follow up via email to ensure we received your original message.

Please include the requested information listed below (as much as you can provide)
to help us better understand the nature and scope of the possible issue:

* Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
* Full paths of source file(s) related to the manifestation of the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.
EOF

    log_success "Template files created in $TEMPLATES_DIR"
}

# Function: Install spec-kit structure
install_spec_kit() {
    log_info "Installing GitHub Spec-Kit community standards..."

    # Initialize adapter if needed
    init_adapter

    # Always create/update templates to ensure they exist
    create_templates

    # Create version file
    create_version_file

    # Create target .github directory
    if [[ ! -d "$TARGET_DIR" ]]; then
        mkdir -p "$TARGET_DIR/ISSUE_TEMPLATE"
        log_info "Created $TARGET_DIR directory"
    else
        log_warning "$TARGET_DIR directory already exists"
    fi

    # Copy templates to target directory
    log_info "Copying templates to $TARGET_DIR..."

    # Copy issue templates
    cp -r "$TEMPLATES_DIR/ISSUE_TEMPLATE/"* "$TARGET_DIR/ISSUE_TEMPLATE/"

    # Copy other templates
    cp "$TEMPLATES_DIR/pull_request_template.md" "$TARGET_DIR/"
    cp "$TEMPLATES_DIR/CONTRIBUTING.md" "$TARGET_DIR/"
    cp "$TEMPLATES_DIR/CODE_OF_CONDUCT.md" "$TARGET_DIR/"
    cp "$TEMPLATES_DIR/SECURITY.md" "$TARGET_DIR/"

    # Update .living-docs.config if it exists
    if [[ -f ".living-docs.config" ]]; then
        if ! grep -q "spec_system:" ".living-docs.config"; then
            echo "spec_system: github-spec-kit" >> ".living-docs.config"
        fi
        if ! grep -q "auto_update:" ".living-docs.config"; then
            echo "auto_update: true" >> ".living-docs.config"
        fi
        log_info "Updated .living-docs.config"
    fi

    log_success "GitHub Spec-Kit installation complete!"
    log_info "Files created in $TARGET_DIR:"
    find "$TARGET_DIR" -type f | sort
}

# Function: Validate installation
validate_spec_kit() {
    log_info "Validating GitHub Spec-Kit installation..."

    local errors=0
    local required_files=(
        "$TARGET_DIR/ISSUE_TEMPLATE/bug_report.md"
        "$TARGET_DIR/ISSUE_TEMPLATE/feature_request.md"
        "$TARGET_DIR/ISSUE_TEMPLATE/config.yml"
        "$TARGET_DIR/pull_request_template.md"
        "$TARGET_DIR/CONTRIBUTING.md"
        "$TARGET_DIR/CODE_OF_CONDUCT.md"
        "$TARGET_DIR/SECURITY.md"
    )

    # Check if target directory exists
    if [[ ! -d "$TARGET_DIR" ]]; then
        log_error "$TARGET_DIR directory not found"
        ((errors++))
    fi

    # Check each required file
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "✓ $file exists"
        else
            log_error "✗ $file missing"
            ((errors++))
        fi
    done

    # Check version file
    if [[ -f "$VERSION_FILE" ]]; then
        log_success "✓ Version file exists"
    else
        log_error "✗ Version file missing"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "Validation failed with $errors errors"
        return 1
    fi
}

# Function: Check for updates (basic implementation)
check_updates() {
    log_info "Checking for updates..."

    if [[ ! -f "$VERSION_FILE" ]]; then
        log_warning "No version file found - installation may be incomplete"
        return 1
    fi

    # For now, just check if templates directory is newer than target
    if [[ "$TEMPLATES_DIR" -nt "$TARGET_DIR" ]]; then
        log_info "Updates available"
        return 0
    else
        log_info "Already up to date"
        return 1
    fi
}

# Function: Apply updates (basic implementation)
apply_updates() {
    log_info "Applying updates..."

    # Backup existing files
    if [[ -d "$TARGET_DIR" ]]; then
        backup_dir="${TARGET_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing files to $backup_dir"
        cp -r "$TARGET_DIR" "$backup_dir"
    fi

    # Re-run installation to update files
    install_spec_kit

    log_success "Updates applied successfully"
}

# Function: Run tests
run_tests() {
    log_info "Running adapter tests..."

    # Test 1: Installation test
    log_info "Test 1: Installation"
    if install_spec_kit > /dev/null 2>&1; then
        log_success "✓ Installation test passed"
    else
        log_error "✗ Installation test failed"
        return 1
    fi

    # Test 2: Validation test
    log_info "Test 2: Validation"
    if validate_spec_kit > /dev/null 2>&1; then
        log_success "✓ Validation test passed"
    else
        log_error "✗ Validation test failed"
        return 1
    fi

    # Test 3: File content test
    log_info "Test 3: File content"
    if grep -q "Bug report" "$TARGET_DIR/ISSUE_TEMPLATE/bug_report.md" 2>/dev/null; then
        log_success "✓ Template content test passed"
    else
        log_error "✗ Template content test failed"
        return 1
    fi

    log_success "All tests passed!"
}

# Main CLI interface
main() {
    case "${1:-}" in
        install)
            install_spec_kit
            ;;
        update)
            if check_updates; then
                apply_updates
            else
                log_info "No updates needed"
            fi
            ;;
        validate)
            validate_spec_kit
            ;;
        test)
            run_tests
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: ${1:-}"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"