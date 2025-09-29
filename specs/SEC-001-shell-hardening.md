# SEC-001: Shell Script Security Hardening

## Priority
**CRITICAL** - Security vulnerabilities in shell scripts

## Status
**ACTIVE** - Immediate action required

## Summary
Multiple shell script security issues detected via ShellCheck scan. Scripts lack proper hardening, quote expansions, and strict error handling.

## Findings

### Critical Issues
1. **Unquoted Parameter Expansions** (SC2295)
   - `scripts/build-context.sh:12` - Pattern matching vulnerability (PARTIALLY FIXED)
   - Risk: Path injection, unexpected globbing

2. **Missing Input Validation** (SC1091)
   - `scripts/archive-old-work.sh:10` - Sourcing unvalidated config (PARTIALLY FIXED)
   - Risk: Arbitrary code execution

3. **Path Injection in Adapter System** (NEW FROM 007)
   - `lib/adapter/rewrite.sh` - Unsanitized variable substitution
   - Risk: Directory traversal, file overwrite

4. **Cross-Platform sed Incompatibilities**
   - `wizard.sh` - macOS vs Linux sed -i usage
   - Risk: Silent failures, data corruption

### High Priority Issues
1. **Command Substitution in echo** (SC2005, SC2129)
   - Multiple instances of inefficient/unsafe patterns
   - `scripts/build-context.sh:59,64`

2. **Using ls for programmatic parsing** (SC2012)
   - `scripts/archive-old-work.sh:86,90`
   - `scripts/build-context.sh:21`
   - Risk: Breaks on special filenames

3. **Inefficient grep|wc patterns** (SC2126)
   - `scripts/build-context.sh:97`
   - Should use `grep -c`

## Requirements

### Must Have (P0)
1. Add `set -euo pipefail` to all scripts
2. Quote all variable expansions
3. Validate all sourced files exist
4. Replace `ls` with `find` for file operations

### Should Have (P1)
1. Add shellcheck pre-commit hook
2. Implement input sanitization library
3. Add error trap handlers

### Nice to Have (P2)
1. Convert complex scripts to Python
2. Add unit tests for shell functions

## Implementation Plan

### Phase 1: Immediate Fixes (2 hours)
```bash
# Add to all scripts
set -euo pipefail
IFS=$'\n\t'
```

### Phase 2: Quote All Expansions (1 hour)
- Fix all SC2295 warnings
- Add quotes to all variable uses

### Phase 3: Replace Dangerous Patterns (2 hours)
- Replace `ls` with `find`
- Fix command substitution patterns
- Add input validation

## Success Criteria
- [ ] Zero ShellCheck warnings at severity error/warning
- [ ] All scripts have `set -euo pipefail`
- [ ] All variables properly quoted
- [ ] Pre-commit hook prevents unsafe scripts

## Assigned To
**ENG-SECURITY** team

## Due Date
EOD Today - CRITICAL security fixes

## References
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Bash Strict Mode](http://redsymbol.net/articles/unofficial-bash-strict-mode/)
- OWASP Command Injection Prevention

## Testing
```bash
# Run comprehensive scan
shellcheck -S error scripts/*.sh lib/**/*.sh

# Test with malicious inputs
./test-harness.sh --security-fuzzing
```

## Notes
- Coordinate with ENG-INFRA for CI/CD integration
- Consider migrating critical scripts to compiled languages
- Add security scanning to GitHub Actions