# Enhanced Update System

**Status**: ✅ Complete
**Date**: 2025-09-16
**Version**: 2.0.0

## Summary
Enhanced update system to check both core living-docs and all installed spec adapter repositories for updates.

## Key Features
- Core wizard update checking against GitHub main branch
- Individual adapter version tracking
- Per-adapter update checking
- Version comparison and notification
- Self-updating update.sh script
- Preserves user customizations during updates

## Update Sources
- **Core**: github.com/joshwegener/living-docs
- **Adapters**: Each adapter's upstream repository
  - spec-kit: github/spec-kit
  - bmad-method: bmad-code-org/BMAD-METHOD
  - agent-os: buildermethods/agent-os
  - aider/cursor/continue: Individual rule repositories

## Implementation
- Version tracking in `.living-docs.config`
- Format: `ADAPTER_VERSION="x.y.z"`
- Update checker at `/adapters/check-updates.sh`
- Integration with wizard.sh menu option

## Usage
```bash
# Check for updates (wizard menu option 2)
./wizard.sh
# Select option 2: Check for updates

# Or directly
./adapters/check-updates.sh
```

## Files Created/Modified
- `/adapters/check-updates.sh` - Main update checking logic
- `/update.sh` - Enhanced with adapter awareness
- Configuration tracking in `.living-docs.config`