# DEBT-001: Shell Scripts Technical Debt & Structure

## Priority
**HIGH** - Maintainability and performance impact

## Status
**ACTIVE** - Refactoring needed

## Summary
Shell script codebase has grown to 10,579 lines with significant structural issues. Multiple large files (900+ lines) indicate poor separation of concerns. Dead code and inefficient patterns throughout.

## Findings

### Size Analysis
1. **Oversized Scripts** (>800 lines)
   - `lib/a11y/check.sh` - 955 lines (LARGEST)
   - `lib/drift/detector.sh` - 810 lines
   - `lib/docs/mermaid.sh` - 806 lines
   - Clear violation of single responsibility principle

2. **Complex Adapter System** (2,620 lines total)
   - 7 separate files averaging 374 lines each
   - Significant overlap in functionality
   - Opportunity for consolidation

3. **Minimal TODO/FIXME Markers**
   - Only 1 file with debt markers
   - Suggests undocumented technical debt

### Structural Issues
1. **Code Duplication**
   - Path validation repeated across multiple files
   - Error handling patterns duplicated
   - Logging code copy-pasted

2. **Missing Abstractions**
   - No central error handling library
   - No shared validation utilities
   - No common logging framework

3. **Performance Issues**
   - Multiple file scans for same data
   - Inefficient grep/sed chains
   - Unnecessary subshell spawning

## Requirements

### Must Have (P0)
1. Break up files >500 lines
2. Create shared utility libraries
3. Remove dead code
4. Consolidate duplicate functions

### Should Have (P1)
1. Convert complex scripts to Python
2. Add performance benchmarks
3. Implement caching layer

### Nice to Have (P2)
1. Full rewrite in Go/Rust
2. Add comprehensive unit tests
3. Create script dependency graph

## Implementation Plan

### Phase 1: Extract Common Libraries (4 hours)
```bash
lib/
├── common/
│   ├── errors.sh      # Error handling
│   ├── logging.sh     # Unified logging
│   ├── paths.sh       # Path utilities
│   └── validation.sh  # Input validation
```

### Phase 2: Break Up Large Files (8 hours)
- Split `a11y/check.sh` into:
  - `a11y/scanner.sh` - Core scanning
  - `a11y/rules.sh` - Rule definitions
  - `a11y/reporter.sh` - Report generation

- Split `drift/detector.sh` into:
  - `drift/scanner.sh` - File scanning
  - `drift/analyzer.sh` - Change analysis
  - `drift/reporter.sh` - Report generation

### Phase 3: Consolidate Adapter System (6 hours)
```bash
lib/adapter/
├── core.sh        # Consolidated core (from 7 files)
├── operations.sh  # Install/remove/update
└── utilities.sh   # Prefix/rewrite/manifest
```

### Phase 4: Remove Dead Code (2 hours)
- Audit all functions for usage
- Remove unreferenced code
- Clean up commented blocks

## Success Criteria
- [ ] No file >500 lines
- [ ] Code duplication <5%
- [ ] Central error handling in place
- [ ] Performance improved by 30%
- [ ] All functions have single responsibility

## Metrics
```bash
# Before
Total lines: 10,579
Largest file: 955 lines
Files >500 lines: 6
Duplication: ~40%

# Target
Total lines: <7,000
Largest file: <500 lines
Files >500 lines: 0
Duplication: <5%
```

## Assigned To
**ENG-PLATFORM** team

## Due Date
End of Week - HIGH priority debt reduction

## Testing
```bash
# Performance benchmark
time ./scripts/full-test-suite.sh

# Complexity analysis
shellcheck --severity=style scripts/*.sh lib/**/*.sh

# Duplication check
./scripts/find-duplicates.sh
```

## Migration Strategy
1. Create new structure alongside old
2. Migrate one module at a time
3. Run parallel testing
4. Cutover with rollback plan
5. Remove old code after 1 week

## References
- [Shell Script Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Refactoring Shell Scripts](https://www.shellscript.sh/refactoring.html)
- Clean Code principles

## Notes
- Consider long-term migration to Python/Go
- Document all breaking changes
- Keep backward compatibility during transition
- Update wizard.sh to use new structure