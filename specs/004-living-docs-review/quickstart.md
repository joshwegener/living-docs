# Quickstart: Security & Infrastructure Improvements

This quickstart validates the implementation of security and infrastructure improvements for living-docs v5.1.0.

## Prerequisites Validation

```bash
# 1. Verify environment
bash --version | grep -E "version [4-5]" || echo "ERROR: Bash 4.0+ required"
git --version || echo "ERROR: Git required"
curl --version || echo "ERROR: curl required"

# 2. Check permissions
touch test-write.tmp && rm test-write.tmp || echo "ERROR: Write permission required"
```

## Scenario 1: Secure Installation

```bash
# 1. Download with checksum verification
curl -LO https://github.com/joshwegener/living-docs/releases/download/v5.1.0/wizard.sh
curl -LO https://github.com/joshwegener/living-docs/releases/download/v5.1.0/wizard.sh.sha256

# 2. Verify checksum
sha256sum -c wizard.sh.sha256
# Expected: "wizard.sh: OK"

# 3. Optional: Verify GPG signature
curl -LO https://github.com/joshwegener/living-docs/releases/download/v5.1.0/wizard.sh.sig
gpg --verify wizard.sh.sig wizard.sh
# Expected: "Good signature from living-docs"

# 4. Run installation with progress indicators
chmod +x wizard.sh
./wizard.sh install --framework spec-kit
# Expected: Progress bar showing installation steps

# 5. Validate installation
[ -f .living-docs.config ] && echo "✓ Config created"
[ -d docs ] && echo "✓ Docs directory created"
```

## Scenario 2: Update with Rollback Safety

```bash
# 1. Check current version
./wizard.sh --version
# Expected: "living-docs wizard v5.0.0"

# 2. Create test file to verify backup
echo "test content" > docs/test.md

# 3. Run update with backup
./wizard.sh update --backup
# Expected:
# - "Creating backup at .living-docs.backup/v5.0.0/"
# - "Downloading v5.1.0..."
# - Progress indicators
# - "✓ Updated to version 5.1.0"

# 4. Verify backup was created
[ -d .living-docs.backup/v5.0.0 ] && echo "✓ Backup created"

# 5. Test rollback
./wizard.sh rollback --to v5.0.0
# Expected: "✓ Rolled back to version 5.0.0"

# 6. Verify test file still exists
[ -f docs/test.md ] && cat docs/test.md | grep "test content" && echo "✓ Content preserved"
```

## Scenario 3: Documentation Drift Detection

```bash
# 1. Create documentation
echo "# Test Doc" > docs/feature.md
./wizard.sh check-drift
# Expected: "✓ No documentation drift detected"

# 2. Modify file outside of tracking
echo "Modified content" >> docs/feature.md

# 3. Run drift detection
./wizard.sh check-drift --verbose
# Expected:
# - "⚠ Documentation drift detected in 1 files"
# - "docs/feature.md: content changed"

# 4. Auto-fix drift
./wizard.sh check-drift --fix
# Expected: "✓ Fixed drift in 1 files"
```

## Scenario 4: CI/CD Pipeline Execution

```bash
# 1. Create a test PR branch
git checkout -b test/security-improvements

# 2. Make a change that should trigger CI
echo "test" >> README.md
git add README.md
git commit -m "test: Trigger CI pipeline"

# 3. Push and observe GitHub Actions
git push origin test/security-improvements
# Expected in GitHub UI:
# - "Test Pipeline" running
# - Lint checks passing
# - Security scan passing
# - Tests running on matrix (Ubuntu, macOS)

# 4. Check test results locally
./wizard.sh test --coverage
# Expected:
# - "Running test suite..."
# - Progress indicators for each test
# - "✓ All tests passed (X tests)"
# - "Coverage: 85%"
```

## Scenario 5: Error Handling & Troubleshooting

```bash
# 1. Test network failure handling
# Simulate network failure
export LIVING_DOCS_OFFLINE=1
./wizard.sh update
# Expected: "✗ Update failed: Network error - unable to reach GitHub"

# 2. Test insufficient permissions
chmod 444 wizard.sh
./wizard.sh update
# Expected: "✗ Update failed: Permission denied - cannot modify wizard.sh"
chmod 755 wizard.sh

# 3. Test debug mode
LIVING_DOCS_DEBUG=1 ./wizard.sh check-drift
# Expected: Verbose output with timestamps and operation details

# 4. Test dry-run mode
./wizard.sh update --dry-run
# Expected:
# - "DRY RUN - No changes will be made"
# - List of actions that would be performed
```

## Validation Checklist

Run this validation script to verify all improvements:

```bash
#!/bin/bash
# save as validate-improvements.sh

echo "Validating Security & Infrastructure Improvements..."

# Security Validations
echo -n "1. Checksum verification: "
[ -f wizard.sh.sha256 ] && echo "✓" || echo "✗"

echo -n "2. GPG signatures: "
[ -f wizard.sh.sig ] && echo "✓" || echo "✗"

echo -n "3. Input sanitization: "
./wizard.sh install --framework "../etc/passwd" 2>&1 | grep -q "Invalid" && echo "✓" || echo "✗"

# Infrastructure Validations
echo -n "4. CI/CD workflows: "
[ -f .github/workflows/test.yml ] && echo "✓" || echo "✗"

echo -n "5. Test runner: "
[ -f tests/run-tests.sh ] && echo "✓" || echo "✗"

echo -n "6. Coverage reporting: "
./wizard.sh test --coverage 2>&1 | grep -q "Coverage:" && echo "✓" || echo "✗"

# Developer Experience Validations
echo -n "7. Progress indicators: "
./wizard.sh update 2>&1 | grep -q "Progress" && echo "✓" || echo "✗"

echo -n "8. Rollback mechanism: "
[ -d .living-docs.backup ] && echo "✓" || echo "✗"

echo -n "9. Debug mode: "
LIVING_DOCS_DEBUG=1 ./wizard.sh --version 2>&1 | grep -q "DEBUG" && echo "✓" || echo "✗"

echo -n "10. Dry-run option: "
./wizard.sh update --dry-run 2>&1 | grep -q "DRY RUN" && echo "✓" || echo "✗"

# Documentation Validations
echo -n "11. Drift detection: "
./wizard.sh check-drift &>/dev/null && echo "✓" || echo "✗"

echo -n "12. Troubleshooting guide: "
[ -f docs/troubleshooting.md ] && echo "✓" || echo "✗"

echo ""
echo "Validation complete!"
```

## Success Criteria

All scenarios must complete successfully with:
- ✅ No security warnings from shellcheck
- ✅ All checksums verified
- ✅ Progress indicators visible for long operations
- ✅ Rollback successfully restores previous state
- ✅ CI/CD pipeline runs on every PR
- ✅ Test coverage > 80%
- ✅ Documentation drift detected and fixed
- ✅ Debug mode provides useful troubleshooting info
- ✅ All validations pass in the checklist

## Troubleshooting

If any scenario fails:

1. Check prerequisites: `bash --version`, `git --version`
2. Enable debug mode: `LIVING_DOCS_DEBUG=1 ./wizard.sh [command]`
3. Check logs: `cat .living-docs/logs/operations.log`
4. Consult: `docs/troubleshooting.md`
5. Rollback if needed: `./wizard.sh rollback --list`