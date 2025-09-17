# Maintenance Procedures

## Daily Maintenance

### 1. Check for Documentation Drift
```bash
./scripts/check-drift.sh
```
- Runs automatically on file changes if hooks installed
- Fixes orphaned files and broken links
- Updates current.md with missing items

### 2. Update Task Tracking
- If working from tasks.md: Update checkboxes immediately after completing each task
- Move active work to completed when done
- Update log.md with major completions

## Weekly Maintenance

### 1. Archive Old Work
```bash
./scripts/archive-old-work.sh
```
- Moves completed work >30 days old to docs/archived/
- Reduces cognitive load and agent context
- Preserves historical reference

### 2. Review Active Work
```bash
ls docs/active/
```
- Ensure all active work is actually in progress
- Move stalled items to ideas.md or bugs.md
- Create trackers for specs being implemented

### 3. Update Dependencies
```bash
./wizard.sh --update
```
- Checks for wizard updates
- Checks for adapter updates
- Maintains version tracking in .living-docs.config

## Monthly Maintenance

### 1. Specification Review
- Review docs/specs/ for completed implementations
- Ensure spec trackers properly moved to completed/
- Archive old specs if needed

### 2. Configuration Audit
```bash
cat .living-docs.config
```
- Verify all installed frameworks listed
- Check version numbers are current
- Ensure docs_path is correct

### 3. Bootstrap Validation
- Review bootstrap.md for accuracy
- Ensure all installed frameworks have rules referenced
- Update gates if new patterns emerge

## Troubleshooting

### Missing Configuration
```bash
# Recreate config
cat > .living-docs.config << EOF
docs_path="docs"
version="3.1.0"
created="$(date +%Y-%m-%d)"
INSTALLED_SPECS="spec-kit aider cursor"
SPEC_KIT_VERSION="1.0.0"
AIDER_VERSION="1.0.0"
CURSOR_VERSION="1.0.0"
EOF
```

### Specs in Wrong Location
```bash
# Move specs to correct location
mv specs/ docs/specs/
# Update references
sed -i '' 's|specs/|docs/specs/|g' docs/current.md
```

### Broken Tests
```bash
# Run test suite
for test in tests/*.sh; do
    echo "Testing: $(basename $test)"
    ./$test
done
```

### Archive Not Working
```bash
# Manual archive
mkdir -p docs/archived
find docs/completed -name "*.md" -mtime +30 -exec mv {} docs/archived/ \;
```

## Best Practices

1. **Commit Frequently**: Every 30 minutes or after major changes
2. **Update Documentation Immediately**: Not "later", not "after", but NOW
3. **Use Spec Workflow**: For features >1 file, use /specify → /plan → /tasks
4. **Follow TDD**: Tests must fail before implementation
5. **Track Everything**: Use TodoWrite, update tasks.md, maintain trackers

## Gate Enforcement

### When Starting Work
- Check for active tasks.md - follow phases strictly
- Create tracker in docs/active/ for spec implementations
- Update TodoWrite with task numbers

### When Completing Work
- Update tasks.md checkboxes immediately
- Move trackers from active/ to completed/
- Run drift check to ensure no orphans

### When Making Claims
- Verify with actual tests
- Check file exists and works
- Document in appropriate location

---
*Maintained by: living-docs system*
*Last Updated: 2025-09-16*