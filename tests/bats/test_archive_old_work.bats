#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing archive-old-work.sh functionality

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy script
    cp "${BATS_TEST_DIRNAME}/../../scripts/archive-old-work.sh" .

    # Create test structure
    mkdir -p docs/completed docs/active docs/archive
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "archive-old-work.sh identifies old completed work correctly" {
    # Create old completed work (>30 days)
    touch -t 202301010000 docs/completed/old-feature.md
    touch -t 202301010000 docs/completed/old-bug.md

    # Create recent completed work (<30 days)
    touch docs/completed/recent-feature.md

    # THIS TEST WILL FAIL: Age detection not working
    run bash archive-old-work.sh --dry-run
    [ "$status" -eq 0 ]

    # Should identify old files (THIS WILL FAIL)
    [[ "$output" =~ "old-feature.md" ]]
    [[ "$output" =~ "old-bug.md" ]]

    # Should not identify recent files
    [[ ! "$output" =~ "recent-feature.md" ]]
}

@test "archive-old-work.sh creates dated archive structure" {
    # Create files to archive
    echo "# Old Work" > docs/completed/old.md
    touch -t 202301010000 docs/completed/old.md

    # THIS TEST WILL FAIL: Archive structure not created properly
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Should create dated archive directory (THIS WILL FAIL)
    YEAR=$(date +%Y)
    [ -d "docs/archive/$YEAR" ]

    # File should be moved to archive (THIS WILL FAIL)
    [ -f "docs/archive/$YEAR/old.md" ]
    [ ! -f "docs/completed/old.md" ]
}

@test "archive-old-work.sh preserves file metadata during archive" {
    # Create file with specific metadata
    echo "# Feature" > docs/completed/feature.md
    touch -t 202301011234 docs/completed/feature.md

    # THIS TEST WILL FAIL: Metadata not preserved
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Check metadata preserved (THIS WILL FAIL)
    ARCHIVED=$(find docs/archive -name "feature.md")
    [ -n "$ARCHIVED" ]

    # Timestamp should be preserved
    TIMESTAMP=$(stat -f "%Sm" "$ARCHIVED" 2>/dev/null || stat -c "%y" "$ARCHIVED")
    [[ "$TIMESTAMP" =~ "2023" ]]
}

@test "archive-old-work.sh updates index after archiving" {
    # Create index
    cat > docs/completed/index.md << 'EOF'
# Completed Work
- old-work.md
- recent-work.md
EOF

    # Create old work
    touch -t 202301010000 docs/completed/old-work.md

    # THIS TEST WILL FAIL: Index not updated
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Index should be updated (THIS WILL FAIL)
    run grep "old-work.md" docs/completed/index.md
    [ "$status" -ne 0 ]  # Should be removed

    # Should have archive reference (THIS WILL FAIL)
    run grep "archived" docs/completed/index.md
    [ "$status" -eq 0 ]
}

@test "archive-old-work.sh handles custom age threshold" {
    # Create files of various ages
    touch -t 202312010000 docs/completed/7-days-old.md  # 7 days old from a recent date
    touch docs/completed/new.md

    # THIS TEST WILL FAIL: Custom threshold not supported
    run bash archive-old-work.sh --days 5
    [ "$status" -eq 0 ]

    # Should archive 7-day-old file with 5-day threshold (THIS WILL FAIL)
    [[ "$output" =~ "7-days-old.md" ]]
}

@test "archive-old-work.sh creates archive summary" {
    # Create multiple files to archive
    touch -t 202301010000 docs/completed/feat1.md
    touch -t 202301010000 docs/completed/feat2.md

    # THIS TEST WILL FAIL: Summary not generated
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Should create summary file (THIS WILL FAIL)
    [ -f "docs/archive/archive-summary.md" ]

    # Summary should contain archived files (THIS WILL FAIL)
    run grep "feat1.md" docs/archive/archive-summary.md
    [ "$status" -eq 0 ]
}

@test "archive-old-work.sh supports dry-run mode" {
    # Create file to archive
    touch -t 202301010000 docs/completed/test.md

    # THIS TEST WILL FAIL: Dry-run not properly implemented
    run bash archive-old-work.sh --dry-run
    [ "$status" -eq 0 ]

    # File should NOT be moved in dry-run (THIS WILL FAIL)
    [ -f "docs/completed/test.md" ]

    # Should show what would be done (THIS WILL FAIL)
    [[ "$output" =~ "Would archive" ]]
    [[ "$output" =~ "test.md" ]]
}

@test "archive-old-work.sh handles symlinks correctly" {
    # Create symlink to completed work
    echo "# Real" > docs/completed/real.md
    ln -s real.md docs/completed/link.md
    touch -t 202301010000 docs/completed/link.md

    # THIS TEST WILL FAIL: Symlink handling broken
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Should handle symlink appropriately (THIS WILL FAIL)
    # Either archive both or skip symlinks
    [ -L "docs/completed/link.md" ] || [ -L "docs/archive/*/link.md" ]
}

@test "archive-old-work.sh respects .archiveignore patterns" {
    # Create .archiveignore
    cat > .archiveignore << 'EOF'
*-draft.md
*-wip.md
private/*
EOF

    # Create files
    touch -t 202301010000 docs/completed/old-draft.md
    touch -t 202301010000 docs/completed/old-final.md

    # THIS TEST WILL FAIL: .archiveignore not respected
    run bash archive-old-work.sh
    [ "$status" -eq 0 ]

    # Draft should not be archived (THIS WILL FAIL)
    [ -f "docs/completed/old-draft.md" ]

    # Final should be archived (THIS WILL FAIL)
    [ ! -f "docs/completed/old-final.md" ]
}

@test "archive-old-work.sh creates compressed archives for old years" {
    # Create very old files
    mkdir -p docs/archive/2020
    echo "# Old" > docs/archive/2020/old.md

    # THIS TEST WILL FAIL: Compression not implemented
    run bash archive-old-work.sh --compress-old
    [ "$status" -eq 0 ]

    # Should create compressed archive (THIS WILL FAIL)
    [ -f "docs/archive/2020.tar.gz" ]
    [ ! -d "docs/archive/2020" ]
}