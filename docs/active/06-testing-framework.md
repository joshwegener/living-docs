# Testing Framework for living-docs

**Status**: 🔴 Not Started | **Priority**: HIGH | **Created**: Sept 14, 2025

## Objective
Add comprehensive testing to ensure wizard.sh and templates work correctly across different environments.

## Requirements
1. Test wizard.sh on macOS and Linux
2. Verify all template variables get replaced correctly
3. Test all user paths through the wizard
4. Ensure documentation repair doesn't break existing files
5. Validate generated configurations

## Test Cases

### Environment Tests
- [ ] macOS compatibility (sed -i '')
- [ ] Linux compatibility (sed -i)
- [ ] Bash version compatibility (3.2+)

### Wizard Flow Tests
- [ ] New project setup
- [ ] Existing project repair
- [ ] Reconfiguration of existing living-docs
- [ ] All methodology selections
- [ ] All documentation path options
- [ ] All AI assistant choices

### Template Tests
- [ ] Variable substitution accuracy
- [ ] File creation permissions
- [ ] Directory structure creation

### Edge Cases
- [ ] Projects with spaces in names
- [ ] Projects with special characters
- [ ] Nested documentation paths
- [ ] Existing conflicting files

## Implementation Plan
1. Create test harness script
2. Mock file system operations
3. Test each wizard decision path
4. Add CI/CD integration

## Success Criteria
- All tests pass on macOS and Linux
- No breaking changes to existing functionality
- Clear error messages for failures
- Documentation of test coverage