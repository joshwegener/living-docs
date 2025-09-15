# Real Spec-Kit Adapter Implementation

**Status**: 🔴 Not Started | **Priority**: HIGH | **Created**: Sept 14, 2025

## The Problem
We claim to support spec-kit but we don't. We confused GitHub templates with spec-kit.

## What Real Spec-Kit Is
Spec-kit is a Claude-specific system with:
- `.claude/` directory containing commands
- `/spec` command to create specifications
- `/create` command to generate files from specs
- `/task` command for task management
- Actual Claude workflow integration

## What We Have vs What We Need

### What We Have:
- ❌ No `.claude/` directory
- ❌ No commands
- ❌ No spec-kit integration
- ✅ Just GitHub templates (PR template, CONTRIBUTING.md)

### What We Need:
1. **Spec-Kit Detector in wizard.sh**
   ```bash
   if [ -d ".claude" ]; then
     echo "Detected spec-kit project"
     # Integrate with existing spec-kit
   fi
   ```

2. **Adapter Structure**
   ```
   specs/spec-kit/
   ├── detector.sh (detects spec-kit)
   ├── adapter.sh (integrates with it)
   └── templates/
       └── .claude/
           └── commands/
               ├── docs.md (living-docs commands)
               └── status.md (status reporting)
   ```

3. **Integration Points**
   - Spec-kit specs → living-docs active/
   - Spec-kit tasks → living-docs tasks
   - Keep both systems in sync

## Success Criteria
- [ ] Can detect existing spec-kit projects
- [ ] Adds living-docs without breaking spec-kit
- [ ] Commands work together seamlessly
- [ ] No duplication of effort

## Next Steps
1. Research real spec-kit projects
2. Build detector
3. Create adapter
4. Test integration

## Current Reality
**We don't support spec-kit at all yet. This needs to be built.**