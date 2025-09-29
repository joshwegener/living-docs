# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the living-docs project.

## test.yml

Comprehensive test pipeline that runs on push and pull requests.

### Features

- **Multi-OS Testing**: Tests on both Ubuntu and macOS
- **Matrix Strategy**: Parallel testing across different configurations
- **Security Focus**: Dedicated security scanning and vulnerability checks
- **Performance Testing**: Validates performance with large projects
- **Comprehensive Coverage**:
  - ShellCheck linting
  - Bashate style checking
  - Bats unit tests
  - Integration tests
  - Security audits
  - Performance benchmarks

### Workflow Triggers

- Push to main, develop, and feature branches
- Pull requests to main and develop
- Manual dispatch with debug options

### Test Suites

1. **Lint & Static Analysis**
   - ShellCheck for shell script analysis
   - Bashate for shell script style
   - Custom security pattern detection

2. **Unit Tests**
   - Bats test framework
   - Test coverage reporting

3. **Integration Tests**
   - End-to-end wizard.sh testing
   - Cross-platform compatibility
   - Template processing validation

4. **Security Tests**
   - Vulnerability scanning with Trivy
   - Secret detection with Gitleaks
   - Custom shell security analysis
   - Permission and pattern checks

5. **Performance Tests**
   - Large project scaling
   - Drift detection performance
   - Memory usage validation

### Artifacts

- Test results (JUnit format)
- Security scan reports
- Performance metrics
- Comprehensive test report

### Usage

The workflow runs automatically on pushes and PRs. For manual execution:

```yaml
# Manual dispatch with options
workflow_dispatch:
  inputs:
    debug: true
    test_level: 'security-only'
```

### Configuration

Environment variables:
- `DEBUG`: Enable verbose logging
- `TEST_SUITE`: Specify which test suite to run
- Performance thresholds defined in workflow

### Reporting

- Test results posted as PR comments
- Artifacts retained for 7-30 days
- Security results uploaded for analysis
- Failed tests block merging

This workflow ensures code quality, security, and performance across all supported platforms.