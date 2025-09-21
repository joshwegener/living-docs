# Spec 006: Troubleshooting Guide (Retrospective)

**Status**: Implemented
**Created**: 2025-09-20 (retrospectively)
**Type**: Documentation Enhancement

## Problem Statement
Users encountering issues with living-docs installation, updates, or runtime had no comprehensive resource for self-service troubleshooting. This led to increased support burden and user frustration.

## Solution Overview
Created a comprehensive troubleshooting guide (`docs/troubleshooting.md`) covering:
- Common installation issues
- Update problems
- Adapter-specific issues
- Permission errors
- Network/connectivity problems
- Cross-platform compatibility
- Debug mode usage
- Rollback procedures
- Performance optimization

## Implementation Details

### Document Structure (634 lines)
1. **Quick Diagnosis** - Initial diagnostic commands
2. **Installation Issues** - Permission, template, detection problems
3. **Update Problems** - Version mismatches, config breaks
4. **Adapter Issues** - Spec-kit, BMAD, Agent-OS specific
5. **Permission Errors** - System directories, read-only filesystems
6. **Network Problems** - GitHub API limits, firewalls, SSL
7. **Cross-Platform** - macOS vs Linux differences
8. **Debug Mode** - Comprehensive debug usage
9. **Rollback Procedures** - Emergency recovery
10. **Drift Detection** - Documentation consistency
11. **Performance** - Large project optimization
12. **Emergency Recovery** - Complete system recovery

### Key Features
- **Problem-Solution Format**: Each issue has clear symptoms and solutions
- **Code Examples**: Executable commands for each solution
- **Multiple Solutions**: Various approaches for different scenarios
- **Platform-Specific**: Addresses both macOS and Linux quirks
- **Integration**: Links to debug logging system

## Success Metrics
- Users can self-diagnose 90% of common issues
- Reduced support tickets
- Clear emergency recovery path
- Works for both beginners and advanced users

## Testing Requirements (Retrospective)
**Note**: Documentation testing should verify:
- [ ] All commands are syntactically correct
- [ ] Solutions actually resolve the stated problems
- [ ] Cross-references to other docs are valid
- [ ] Emergency procedures don't cause data loss

## Phase Status
- Phase 0 (Research): ✅ Complete (user feedback analysis)
- Phase 1 (Design): ✅ Complete (retrospectively documented)
- Phase 2 (Tasks): ✅ Complete (retrospectively)
- Phase 3 (Implementation): ✅ Complete
- Phase 4 (Validation): 🔴 Needs verification

## Related Files
- Implementation: `/docs/troubleshooting.md`
- Debug System: `/lib/debug/logger.sh`
- Referenced in: `/docs/current.md`