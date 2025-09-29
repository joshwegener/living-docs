# SEC-002: Secrets & Credential Exposure Scan

## Priority
**HIGH** - Potential credential exposure risk

## Status
**ACTIVE** - Requires immediate audit

## Summary
Comprehensive scan for hardcoded secrets, API keys, and credentials in codebase. Initial grep scan shows minimal exposure, but deeper audit needed.

## Findings

### Current State
1. **No hardcoded secrets detected** in initial scan
2. **GitHub vulnerability alerts disabled** - needs activation
3. Pattern matches found only in legitimate contexts:
   - `lib/security/gpg.sh` - GPG key ID handling (safe)
   - `lib/a11y/check.sh` - Keyword matching for accessibility (safe)

### Risk Areas Requiring Audit
1. **Configuration Files**
   - `.living-docs.config` - Check for API keys
   - Any `.env` files (currently gitignored)
   - Template files that might contain placeholders

2. **Manifest Tampering** (NEW FROM 007)
   - `.living-docs-manifest.json` - No integrity checks
   - Risk: Malicious file injection during updates
   - No signature verification on manifests

3. **Adapter Namespace Collisions** (NEW FROM 007)
   - Prefix system could have collisions
   - Risk: Command hijacking between adapters
   - No validation of prefix uniqueness

4. **Documentation**
   - Example configs in docs
   - README examples
   - Test fixtures

5. **Git History**
   - Previous commits may contain secrets
   - Deleted files still in history

## Requirements

### Must Have (P0)
1. Enable GitHub vulnerability alerts
2. Install and configure gitleaks
3. Scan entire git history
4. Add pre-commit secret scanning

### Should Have (P1)
1. Rotate any discovered credentials
2. Document secret management process
3. Add `.gitleaks.toml` configuration

### Nice to Have (P2)
1. Implement HashiCorp Vault integration
2. Add secret scanning to CI/CD
3. Regular automated audits

## Implementation Plan

### Phase 1: Enable GitHub Security (30 min)
```bash
# Enable vulnerability alerts
gh api -X PUT repos/joshwegener/living-docs/vulnerability-alerts

# Enable secret scanning
gh api -X PUT repos/joshwegener/living-docs/secret-scanning
```

### Phase 2: Install Gitleaks (1 hour)
```bash
# Install gitleaks
brew install gitleaks

# Initial scan
gitleaks detect --source . -v

# Scan git history
gitleaks detect --source . --log-opts="--all" -v
```

### Phase 3: Add Pre-commit Hook (30 min)
```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
gitleaks protect --staged -v
EOF
chmod +x .git/hooks/pre-commit
```

### Phase 4: Configure Gitleaks (1 hour)
```toml
# .gitleaks.toml
[allowlist]
paths = [
  "specs/SEC-002-secrets-scan.md",
  "**/test/**",
  "**/*_test.go"
]

[[rules]]
id = "living-docs-api-key"
description = "Living Docs API Key"
regex = '''(?i)(living[_-]?docs[_-]?api[_-]?key)(.{0,20})?['\"]([0-9a-zA-Z]{32,45})['\"]'''
```

## Success Criteria
- [ ] Zero secrets in codebase
- [ ] Zero secrets in git history
- [ ] GitHub security alerts enabled
- [ ] Pre-commit hook blocking secrets
- [ ] CI/CD secret scanning active

## Assigned To
**ENG-SECURITY** team

## Due Date
EOD Today - HIGH priority security audit

## Testing
```bash
# Test pre-commit hook
echo 'API_KEY="sk-1234567890abcdef"' > test.sh
git add test.sh
git commit -m "Test" # Should fail

# Run full audit
./scripts/security-audit.sh --full
```

## References
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- OWASP Secret Management Cheat Sheet

## Notes
- Coordinate with DevOps for production secrets
- Document in CLAUDE.md after implementation
- Consider adding to wizard.sh setup