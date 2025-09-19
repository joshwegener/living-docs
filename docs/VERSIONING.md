# Versioning Strategy

## Semantic Versioning
We follow [Semantic Versioning](https://semver.org/): MAJOR.MINOR.PATCH

### Version Increments
- **MAJOR**: Breaking changes or architectural shifts
  - Examples: v5.0.0 (token optimization), v4.0.0 (modular rules)
- **MINOR**: New features, backward compatible
  - Examples: v5.1.0 (testing), v5.2.0 (examples)
- **PATCH**: Bug fixes and small improvements
  - Examples: v5.0.1, v5.0.2

## Current Version
See [VERSION](../VERSION) file

## Version History
- **v5.0.0**: Documentation optimization (82% token reduction)
- **v4.0.0**: Modular spec-specific rules
- **v3.0.0**: Multi-framework support (6 adapters)
- **v2.0.0**: Intelligent auto-detection
- **v1.0.0**: Initial core framework

## Guidelines
1. Every merge to main gets a version
2. Features in development use branch names, not versions
3. Major versions for breaking changes only
4. Use minor versions for features
5. Use patch versions for fixes

## Git Tags
```bash
# For releases
git tag -a v5.1.0 -m "Release v5.1.0: Testing framework"

# For pre-releases
git tag -a v5.1.0-rc.1 -m "Release candidate 1 for v5.1.0"
```