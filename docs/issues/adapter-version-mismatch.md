# Adapter Version Mismatch Issue

## Problem
The adapter update check shows version mismatches between local adapter configs and GitHub releases:
- Local spec-kit: `2.0.0`
- GitHub spec-kit: `v0.0.47`
- Similar mismatches for other adapters

## Root Cause
The version detection logic compares:
1. Local version from `adapters/*/config.yml` (e.g., "2.0.0")
2. Remote version from GitHub API release tags (e.g., "v0.0.47")

These versions are not synchronized because:
- Local adapter configs use semantic versioning for the adapter wrapper
- GitHub repos use their own release versioning
- The comparison should track adapter wrapper versions, not upstream project versions

## Current Impact
- Update check always shows updates available even after updating
- Confusing UX - users think updates failed
- Can't tell when real adapter updates are available

## Solution Options

### Option 1: Track Upstream Versions
- Store upstream version separately in config.yml
- Compare upstream versions for update checks
- Keep adapter wrapper version for internal use

### Option 2: Version Mapping File
- Maintain a versions.json mapping local to upstream
- Check against this mapping for updates
- Update mapping when pulling new adapter code

### Option 3: Use Git Commit Hash
- Track last synced commit hash instead of version
- Compare commits to detect updates
- More accurate but less user-friendly

## Recommendation
Option 1 - Add `upstream_version` field to config.yml:
```yaml
name: spec-kit
version: 2.0.0  # Adapter wrapper version
upstream_version: v0.0.47  # GitHub spec-kit version
```

## Implementation Notes
1. Update all adapter config.yml files with upstream_version
2. Modify check-updates.sh to compare upstream_version
3. Update adapter install/update scripts to track both versions
4. Test with all adapters to ensure consistency

## Testing Checklist
- [ ] Update check correctly identifies available updates
- [ ] No false positives after updating
- [ ] Version display is clear to users
- [ ] Works with all adapter types