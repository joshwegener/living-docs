# Adapter Versioning Guidelines

## Overview
Living-docs adapters use dual versioning to track both the adapter wrapper and upstream project versions.

## Version Fields in config.yml

Every adapter config.yml MUST include:
```yaml
name: adapter-name
version: 1.0.0  # Adapter wrapper version (our code)
upstream_version: unknown  # Set by install/update process
```

### Version Field
- Tracks the living-docs adapter wrapper version
- Semantic versioning (MAJOR.MINOR.PATCH)
- Increment when adapter logic changes

### Upstream Version Field
- Tracks the external project version we're wrapping
- **Set by install/update process, not pre-populated**
- Starts as "unknown" until adapter is installed
- Use exact format from upstream after install (e.g., "v1.2.3", "commit-abc123")
- Use "none" if no upstream repo exists (e.g., cursor, continue)
- Use "unknown" if adapter not yet installed

## Update Check Logic

The update checker compares `upstream_version` to detect available updates:
1. Fetches latest release/commit from GitHub API
2. Compares with local `upstream_version`
3. Shows update available if different

## When Versions Get Updated

### Increment `version` when:
- Changing adapter installation logic
- Modifying path handling
- Adding/removing features
- Fixing adapter bugs

### `upstream_version` gets set:
- **Automatically** by install.sh when adapter is first installed
- **Automatically** by update-all.sh when pulling new upstream content
- Should capture the exact version/commit being installed
- Never manually set before installation

## Examples

### Installed adapter with GitHub upstream:
```yaml
name: spec-kit
version: 2.0.0  # Our adapter at v2
upstream_version: v0.0.47  # GitHub spec-kit at v0.0.47 (set during install)
```

### Uninstalled adapter:
```yaml
name: bmad-method
version: 1.0.0
upstream_version: unknown  # Not yet installed
```

### Adapter without upstream:
```yaml
name: cursor
version: 1.0.0
upstream_version: none  # No official repo
```

### Adapter tracking commit:
```yaml
name: aider
version: 1.0.0
upstream_version: commit-5d3b240  # Tracking specific commit
```

## Testing Version Updates

1. Update `upstream_version` in config.yml
2. Run `./wizard.sh` and select "Check for updates"
3. Verify correct version comparison
4. Test update process with `./adapters/update-all.sh`

## Common Issues

- **Version mismatch after update**: Check that install script updates upstream_version
- **Always shows updates available**: Verify upstream_version format matches GitHub
- **Can't detect updates**: Ensure GitHub API URL is correct in check-updates.sh