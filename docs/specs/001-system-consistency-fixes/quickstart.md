# Quickstart: System Consistency Fixes

**Purpose**: Validate the system consistency improvements work correctly
**Duration**: ~5 minutes
**Prerequisites**: living-docs project with inconsistencies

## Test Scenario: Fresh Project Setup

### Step 1: Verify Current Inconsistent State
```bash
# Should show missing config
ls -la .living-docs.config
# → File not found

# Should show specs in root
ls -la specs/
# → Directory exists in wrong location

# Should show many old completed files
ls docs/completed/ | wc -l
# → 10+ files cluttering context

# Should show bootstrap doesn't mention spec-kit
grep -i "spec-kit\|specify" docs/bootstrap.md
# → No matches found
```

### Step 2: Apply System Consistency Fixes
```bash
# Run the wizard to create missing config
./wizard.sh
# → Should detect missing config and create it

# Verify config was created
cat .living-docs.config
# → Should show proper configuration

# Check specs moved to docs/specs/
ls -la docs/specs/
# → Should contain moved specifications

# Verify old work archived
ls docs/archived/ | wc -l
# → Should show archived files

ls docs/completed/ | wc -l
# → Should show fewer recent files
```

### Step 3: Validate Spec-Kit Integration
```bash
# Check bootstrap mentions spec-kit commands
grep -i "specify\|plan\|tasks" docs/bootstrap.md
# → Should find references to spec-kit workflow

# Test spec-kit workflow
./.specify/scripts/bash/create-new-feature.sh --json "test feature"
# → Should create new spec successfully

# Verify spec created in correct location
ls docs/specs/002-test-feature/
# → Should contain spec.md file
```

### Step 4: Validate Archive Functionality
```bash
# Check current.md only shows recent work
grep "docs/completed" docs/current.md | wc -l
# → Should show ~3-5 recent items, not 10+

# Verify archived work is preserved
ls docs/archived/ | head -5
# → Should show historical files with dates
```

## Expected Outcomes

### Configuration File
- ✅ `.living-docs.config` exists in project root
- ✅ Contains all required fields (docs_path, version, created)
- ✅ Lists installed frameworks correctly
- ✅ Includes framework versions

### Documentation Structure
- ✅ All specs moved from `specs/` to `docs/specs/`
- ✅ No broken links in current.md
- ✅ Recent work in `docs/completed/` (≤5 files)
- ✅ Historical work in `docs/archived/` (older files)

### Spec-Kit Integration
- ✅ Bootstrap references `.specify/` commands
- ✅ New specs create in `docs/specs/NNN-name/` format
- ✅ Workflow documented in bootstrap
- ✅ Commands discoverable by AI agents

### Archive System
- ✅ Automated 30-day archiving
- ✅ Current.md shows only recent work
- ✅ Agent context reduced significantly
- ✅ Historical work preserved but out of active view

## Success Criteria
1. No missing configuration errors
2. All documentation follows consistent structure
3. Spec-kit workflow is discoverable and functional
4. Agent context pollution reduced by 60%+
5. System practices what it preaches

## Rollback Plan
If issues occur:
1. Git checkout to restore previous state
2. Manually restore `.living-docs.config` backup
3. Move specs back to root if needed
4. Report bug in `docs/bugs.md`