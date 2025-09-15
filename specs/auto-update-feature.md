# Auto-Update Feature Specification

## Overview
Implement automatic update checking and application for living-docs installations.

## Requirements

### Version Management
- Store current version in `.living-docs.version`
- Check against GitHub releases API
- Semantic versioning support

### Update Mechanism
```bash
# Check for updates
curl -s https://api.github.com/repos/joshwegener/living-docs/releases/latest

# Compare versions
current_version=$(cat .living-docs.version)
latest_version=$(curl -s ... | jq -r .tag_name)

# Download if newer
if [ "$latest_version" > "$current_version" ]; then
    # Backup current installation
    # Download new wizard.sh
    # Run update process
fi
```

### Update Frequency
- Configured in `.living-docs.config`
- Options: daily, weekly, monthly
- Check on wizard.sh run
- Respect user's auto-update preference

### Safety Features
- Backup before update
- Rollback on failure
- Preserve local customizations
- Skip if uncommitted changes

### Integration Points
- Hook into wizard.sh startup
- Separate update command
- GitHub Actions for releases

## Implementation Plan

### Phase 1: Version Tracking
- Add version to wizard.sh
- Create .living-docs.version on install
- Update version on releases

### Phase 2: Update Check
- Add update check function
- Compare versions
- Notify user of updates

### Phase 3: Auto-Update
- Implement backup mechanism
- Download and apply updates
- Test rollback functionality

### Phase 4: GitHub Integration
- Set up GitHub releases
- Automate version bumping
- Create changelog generation

## Success Criteria
- Updates apply without breaking existing setups
- User customizations preserved
- Clear update notifications
- Reliable rollback mechanism