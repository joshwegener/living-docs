# Wizard Enhancement Specification

## Goal
Enhance wizard.sh to properly detect and integrate with existing spec-kit installations while maintaining backward compatibility.

## Current State
- Wizard detects .github/ISSUE_TEMPLATE for spec-kit
- Doesn't recognize .claude/commands/ (actual spec-kit marker)
- No auto-update mechanism
- Adapter exists but not fully integrated

## Requirements

### Detection Enhancement
- Check .claude/commands/ first (strongest signal)
- Fall back to .github/ISSUE_TEMPLATE
- Provide clear feedback on what was detected

### Auto-Update Feature
- Check for living-docs updates on wizard run
- Optional auto-update flag in config
- Version tracking in .living-docs.version
- Backup before updates

### Integration Points
- If spec-kit detected, skip duplicate installation
- Offer to integrate living-docs into existing spec-kit workflow
- Preserve existing .claude/ customizations

## Implementation Plan

### Phase 1: Detection (COMPLETE)
- ✅ Update auto-detect to check .claude/commands/
- ✅ Add clearer detection messages

### Phase 2: Testing
- Test on clean branch without spec-kit
- Verify adapter integration
- Fix any installation issues

### Phase 3: Auto-Update
- Add version checking
- Implement update mechanism
- Add rollback capability

## Success Criteria
- Wizard correctly detects existing spec-kit
- No duplicate installations
- Seamless integration with existing setups
- Auto-updates work without breaking existing configs