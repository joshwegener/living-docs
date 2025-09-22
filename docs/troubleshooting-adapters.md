# Troubleshooting Guide: Adapter Installation & Management

## Common Installation Issues

### Issue: "declare: -A: invalid option"
**Symptom**: Error when running on macOS
```bash
lib/adapter/rewrite.sh: line 6: declare: -A: invalid option
```

**Cause**: macOS ships with bash 3.2 which doesn't support associative arrays

**Solution**: This has been fixed in v5.1.0. Update to the latest version:
```bash
git pull origin main
```

### Issue: Adapter not found
**Symptom**:
```bash
Error: Source directory not found: /path/to/tmp/adapter-name
Please clone or download the adapter first
```

**Cause**: The adapter hasn't been cloned to the tmp directory

**Solution**: The wizard should handle cloning automatically. If not:
```bash
# Manual clone
mkdir -p tmp
cd tmp
git clone https://github.com/user/adapter-name
cd ..
./wizard.sh
```

### Issue: Commands not found after installation
**Symptom**: Commands installed but not appearing in `.claude/commands/`

**Cause**: AI_PATH environment variable not set or commands were prefixed

**Solution**:
1. Check for prefixed commands:
```bash
ls .claude/commands/*_*.md
```

2. Set AI_PATH if using custom location:
```bash
export AI_PATH=".claude"
```

### Issue: Path validation fails
**Symptom**:
```bash
Error: Path validation failed
Run path validation report for details
```

**Cause**: Adapter contains absolute paths starting with `/`

**Solution**: This is intentional - adapters should only use relative paths. Contact the adapter maintainer to fix their adapter.

## Path Rewriting Issues

### Issue: Hardcoded paths not being rewritten
**Symptom**: Commands still contain `scripts/bash/` instead of custom paths

**Cause**: Path rewriting only happens with `--custom-paths` flag

**Solution**:
```bash
export SCRIPTS_PATH="my-scripts"
export SPECS_PATH="my-specs"
./wizard.sh  # Select option with custom paths
```

### Issue: Custom paths not working
**Symptom**: Variables like {{SCRIPTS_PATH}} appear in files

**Solution**: The variables should be replaced during installation. Check:
```bash
# Verify environment variables are set
echo $SCRIPTS_PATH
echo $SPECS_PATH
echo $MEMORY_PATH
```

## Removal Issues

### Issue: Adapter not fully removed
**Symptom**: Files remain after removal

**Cause**: Files were modified after installation and not tracked in manifest

**Solution**: Manual cleanup:
```bash
# Check manifest for original files
cat adapters/adapter-name/.living-docs-manifest.json

# Remove adapter directory
rm -rf adapters/adapter-name

# Remove prefixed commands
rm .claude/commands/adaptername_*.md
```

### Issue: "Adapter not found or not installed"
**Symptom**: Can't remove adapter that was installed

**Cause**: Manifest file missing or corrupted

**Solution**: Manual removal:
```bash
# Find all adapter files
find . -name "*adapter-name*" -type f

# Remove them manually
rm -rf adapters/adapter-name
```

## Conflict Issues

### Issue: Commands being unexpectedly prefixed
**Symptom**: `plan.md` becomes `adaptername_plan.md`

**Cause**: Conflict detection found existing commands

**Solution**: This is intentional to prevent conflicts. To avoid:
1. Remove conflicting files first
2. Or accept the prefixed names

### Issue: Multiple adapters overwriting each other
**Symptom**: Commands from one adapter disappear after installing another

**Solution**: The system now prevents this with automatic prefixing. Update to v5.1.0.

## Bash Compatibility Issues

### Issue: Scripts fail on Linux
**Symptom**: `sed: can't read : No such file or directory`

**Cause**: macOS and Linux sed have different syntax

**Solution**: The wizard now detects OS and uses appropriate sed syntax. Update to latest.

### Issue: Scripts fail on macOS
**Symptom**: Various errors with arrays and bash features

**Solution**: v5.1.0+ is fully bash 3.2 compatible. Update to latest.

## Emergency Recovery

If adapter installation has broken your project:

### Step 1: Check for backups
```bash
ls adapters/*/.living-docs-manifest.backup.json
```

### Step 2: Remove all adapter files
```bash
# Remove all installed adapters
rm -rf adapters/

# Remove all prefixed commands
rm .claude/commands/*_*.md
rm .cursor/commands/*_*.md
rm .aider/commands/*_*.md
```

### Step 3: Restore from git
```bash
# If using git, restore original state
git status
git checkout -- .
```

### Step 4: Reinstall carefully
```bash
# Use dry-run first
LIVING_DOCS_DRY_RUN=1 ./wizard.sh

# Then install without dry-run
./wizard.sh
```

## Debug Mode

Enable detailed logging to diagnose issues:

```bash
# Maximum verbosity
export LIVING_DOCS_DEBUG=1
export LIVING_DOCS_DEBUG_LEVEL=TRACE

# Run wizard
./wizard.sh

# Check debug log
cat /tmp/living-docs-debug.log
```

## Getting Help

If these solutions don't resolve your issue:

1. Check the [main troubleshooting guide](troubleshooting.md)
2. Search existing issues: https://github.com/joshwegener/living-docs/issues
3. Create a new issue with:
   - Your OS (uname -a)
   - Bash version (bash --version)
   - The complete error message
   - Debug log output

---
*Last updated: Sept 21, 2025 | v5.1.0*