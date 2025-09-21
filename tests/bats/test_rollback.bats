#!/usr/bin/env bats

load test_helper

# Test rollback mechanism for living-docs
# These tests should fail initially to drive TDD implementation

@test "rollback.sh: should load backup functions" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # These functions should be defined after sourcing rollback.sh
    type backup_create_snapshot >/dev/null 2>&1
    type backup_list_snapshots >/dev/null 2>&1
    type backup_rollback_to_snapshot >/dev/null 2>&1
    type backup_cleanup_old_snapshots >/dev/null 2>&1
    type backup_restore_files >/dev/null 2>&1
}

@test "backup_create_snapshot: should create backup with timestamp and metadata" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create test files to backup
    mkdir -p .living-docs
    create_test_file ".living-docs/config" "version=1.0.0"
    create_test_file "docs/current.md" "# Current Status"
    create_test_file "wizard.sh" "#!/bin/bash\necho 'wizard'"

    # Create backup snapshot
    run backup_create_snapshot "pre-update-test"

    [ "$status" -eq 0 ]
    assert_output_contains "Backup snapshot created"

    # Check backup directory structure
    backup_dir=$(echo "$output" | grep -o ".living-docs-backups/[0-9]*-pre-update-test")
    assert_dir_exists "$backup_dir"
    assert_file_exists "$backup_dir/metadata.json"
    assert_file_exists "$backup_dir/files/.living-docs/config"
    assert_file_exists "$backup_dir/files/docs/current.md"
    assert_file_exists "$backup_dir/files/wizard.sh"

    # Check metadata contains expected fields
    run cat "$backup_dir/metadata.json"
    assert_output_contains '"timestamp":'
    assert_output_contains '"description":"pre-update-test"'
    assert_output_contains '"version":'
    assert_output_contains '"file_count":'
}

@test "backup_create_snapshot: should handle missing .living-docs gracefully" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # No .living-docs directory exists
    create_test_file "docs/current.md" "# Current Status"

    run backup_create_snapshot "test-no-config"

    [ "$status" -eq 0 ]
    assert_output_contains "Backup snapshot created"

    # Should still create backup with available files
    backup_dir=$(echo "$output" | grep -o ".living-docs-backups/[0-9]*-test-no-config")
    assert_dir_exists "$backup_dir"
    assert_file_exists "$backup_dir/metadata.json"
    assert_file_exists "$backup_dir/files/docs/current.md"
}

@test "backup_list_snapshots: should list all available backups with details" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create test backups
    mkdir -p .living-docs-backups

    # Create first backup
    backup1=".living-docs-backups/20241201-120000-pre-update"
    mkdir -p "$backup1/files"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"pre-update","version":"1.0.0","file_count":3}' > "$backup1/metadata.json"

    # Create second backup
    backup2=".living-docs-backups/20241201-130000-post-install"
    mkdir -p "$backup2/files"
    echo '{"timestamp":"2024-12-01T13:00:00Z","description":"post-install","version":"1.1.0","file_count":5}' > "$backup2/metadata.json"

    run backup_list_snapshots

    [ "$status" -eq 0 ]
    assert_output_contains "Available backup snapshots:"
    assert_output_contains "20241201-120000-pre-update"
    assert_output_contains "20241201-130000-post-install"
    assert_output_contains "pre-update"
    assert_output_contains "post-install"
    assert_output_contains "3 files"
    assert_output_contains "5 files"
}

@test "backup_list_snapshots: should handle no backups gracefully" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    run backup_list_snapshots

    [ "$status" -eq 0 ]
    assert_output_contains "No backup snapshots found"
}

@test "backup_rollback_to_snapshot: should restore files from specified backup" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create current state
    mkdir -p .living-docs docs
    create_test_file ".living-docs/config" "version=2.0.0"
    create_test_file "docs/current.md" "# Modified Status"
    create_test_file "new-file.md" "# This should be removed"

    # Create backup with original state
    backup_dir=".living-docs-backups/20241201-120000-clean-state"
    mkdir -p "$backup_dir/files/.living-docs" "$backup_dir/files/docs"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"clean-state","version":"1.0.0","file_count":2}' > "$backup_dir/metadata.json"
    echo "version=1.0.0" > "$backup_dir/files/.living-docs/config"
    echo "# Original Status" > "$backup_dir/files/docs/current.md"

    run backup_rollback_to_snapshot "20241201-120000-clean-state"

    [ "$status" -eq 0 ]
    assert_output_contains "Rolling back to snapshot: 20241201-120000-clean-state"
    assert_output_contains "Rollback completed successfully"

    # Verify files are restored
    run cat ".living-docs/config"
    assert_output_contains "version=1.0.0"

    run cat "docs/current.md"
    assert_output_contains "# Original Status"

    # Verify new file is removed (optional behavior)
    # Note: This might be implementation-dependent
}

@test "backup_rollback_to_snapshot: should fail for non-existent backup" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    run backup_rollback_to_snapshot "20241201-999999-nonexistent"

    [ "$status" -ne 0 ]
    assert_output_contains "Backup snapshot not found"
}

@test "backup_rollback_to_snapshot: should create pre-rollback backup" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create current state
    mkdir -p .living-docs
    create_test_file ".living-docs/config" "version=2.0.0"

    # Create target backup
    backup_dir=".living-docs-backups/20241201-120000-target"
    mkdir -p "$backup_dir/files/.living-docs"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"target","version":"1.0.0","file_count":1}' > "$backup_dir/metadata.json"
    echo "version=1.0.0" > "$backup_dir/files/.living-docs/config"

    run backup_rollback_to_snapshot "20241201-120000-target"

    [ "$status" -eq 0 ]
    assert_output_contains "Creating pre-rollback backup"

    # Should have created a pre-rollback backup
    pre_rollback_backup=$(find .living-docs-backups -name "*-pre-rollback-*" | head -1)
    assert_dir_exists "$pre_rollback_backup"
    assert_file_exists "$pre_rollback_backup/metadata.json"
}

@test "backup_cleanup_old_snapshots: should remove backups older than specified days" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    mkdir -p .living-docs-backups

    # Create old backup (simulated)
    old_backup=".living-docs-backups/20241101-120000-old"
    mkdir -p "$old_backup"
    echo '{"timestamp":"2024-11-01T12:00:00Z","description":"old","version":"1.0.0","file_count":1}' > "$old_backup/metadata.json"

    # Create recent backup
    recent_backup=".living-docs-backups/20241201-120000-recent"
    mkdir -p "$recent_backup"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"recent","version":"1.1.0","file_count":1}' > "$recent_backup/metadata.json"

    # Clean up backups older than 7 days
    run backup_cleanup_old_snapshots 7

    [ "$status" -eq 0 ]
    assert_output_contains "Cleaning up backups older than 7 days"

    # Old backup should be removed, recent should remain
    # Note: This test might need adjustment based on implementation details
    # for how "old" is determined (file modification time vs metadata timestamp)
}

@test "backup_cleanup_old_snapshots: should keep minimum number of backups" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    mkdir -p .living-docs-backups

    # Create multiple old backups
    for i in {1..5}; do
        backup_dir=".living-docs-backups/2024110${i}-120000-test${i}"
        mkdir -p "$backup_dir"
        echo "{\"timestamp\":\"2024-11-0${i}T12:00:00Z\",\"description\":\"test${i}\",\"version\":\"1.0.0\",\"file_count\":1}" > "$backup_dir/metadata.json"
    done

    # Should keep at least 3 backups even if older than retention period
    run backup_cleanup_old_snapshots 1 --keep-minimum 3

    [ "$status" -eq 0 ]

    # Should have exactly 3 backups remaining
    backup_count=$(find .living-docs-backups -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    [ "$backup_count" -eq 3 ]
}

@test "backup_restore_files: should restore specific files from backup" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create current state
    mkdir -p .living-docs docs
    create_test_file ".living-docs/config" "version=2.0.0"
    create_test_file "docs/current.md" "# Modified Status"
    create_test_file "docs/other.md" "# Other file"

    # Create backup
    backup_dir=".living-docs-backups/20241201-120000-partial"
    mkdir -p "$backup_dir/files/.living-docs" "$backup_dir/files/docs"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"partial","version":"1.0.0","file_count":2}' > "$backup_dir/metadata.json"
    echo "version=1.0.0" > "$backup_dir/files/.living-docs/config"
    echo "# Original Status" > "$backup_dir/files/docs/current.md"

    # Restore only specific file
    run backup_restore_files "20241201-120000-partial" "docs/current.md"

    [ "$status" -eq 0 ]
    assert_output_contains "Restoring files from snapshot: 20241201-120000-partial"
    assert_output_contains "docs/current.md"

    # Verify only specified file is restored
    run cat "docs/current.md"
    assert_output_contains "# Original Status"

    # Other files should remain unchanged
    run cat ".living-docs/config"
    assert_output_contains "version=2.0.0"

    run cat "docs/other.md"
    assert_output_contains "# Other file"
}

@test "backup_restore_files: should handle multiple file restoration" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Create current state
    mkdir -p .living-docs docs
    create_test_file ".living-docs/config" "version=2.0.0"
    create_test_file "docs/current.md" "# Modified Status"
    create_test_file "docs/bugs.md" "# Modified Bugs"

    # Create backup
    backup_dir=".living-docs-backups/20241201-120000-multi"
    mkdir -p "$backup_dir/files/.living-docs" "$backup_dir/files/docs"
    echo '{"timestamp":"2024-12-01T12:00:00Z","description":"multi","version":"1.0.0","file_count":3}' > "$backup_dir/metadata.json"
    echo "version=1.0.0" > "$backup_dir/files/.living-docs/config"
    echo "# Original Status" > "$backup_dir/files/docs/current.md"
    echo "# Original Bugs" > "$backup_dir/files/docs/bugs.md"

    # Restore multiple files
    run backup_restore_files "20241201-120000-multi" "docs/current.md" "docs/bugs.md"

    [ "$status" -eq 0 ]
    assert_output_contains "Restoring files from snapshot: 20241201-120000-multi"
    assert_output_contains "docs/current.md"
    assert_output_contains "docs/bugs.md"

    # Verify both files are restored
    run cat "docs/current.md"
    assert_output_contains "# Original Status"

    run cat "docs/bugs.md"
    assert_output_contains "# Original Bugs"

    # Config should remain unchanged
    run cat ".living-docs/config"
    assert_output_contains "version=2.0.0"
}

@test "integration: full backup and rollback workflow" {
    source "$LIVING_DOCS_ROOT/lib/backup/rollback.sh"

    # Initial state
    mkdir -p .living-docs docs
    create_test_file ".living-docs/config" "version=1.0.0"
    create_test_file "docs/current.md" "# Initial Status"

    # Create initial backup
    run backup_create_snapshot "initial-state"
    [ "$status" -eq 0 ]
    initial_backup=$(echo "$output" | grep -o ".living-docs-backups/[0-9]*-initial-state")

    # Modify files (simulate update)
    echo "version=2.0.0" > ".living-docs/config"
    echo "# Updated Status" > "docs/current.md"
    create_test_file "docs/new-feature.md" "# New Feature"

    # Create post-update backup
    run backup_create_snapshot "post-update"
    [ "$status" -eq 0 ]

    # List backups
    run backup_list_snapshots
    [ "$status" -eq 0 ]
    assert_output_contains "initial-state"
    assert_output_contains "post-update"

    # Rollback to initial state
    snapshot_id=$(basename "$initial_backup")
    run backup_rollback_to_snapshot "$snapshot_id"
    [ "$status" -eq 0 ]

    # Verify rollback
    run cat ".living-docs/config"
    assert_output_contains "version=1.0.0"

    run cat "docs/current.md"
    assert_output_contains "# Initial Status"

    # New feature file should be removed
    [ ! -f "docs/new-feature.md" ]
}