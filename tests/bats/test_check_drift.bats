#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing check-drift.sh documentation drift detection

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy script to test directory
    cp "${BATS_TEST_DIRNAME}/../../scripts/check-drift.sh" .

    # Create basic documentation structure
    mkdir -p docs/active docs/completed docs/issues
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "check-drift.sh detects orphaned documentation files" {
    # Create orphaned files
    echo "# Orphaned Doc" > docs/orphaned.md
    echo "# Random Issue" > docs/issues/random-issue.md

    # THIS TEST WILL FAIL: Orphan detection incomplete
    run bash check-drift.sh
    [ "$status" -ne 0 ]  # Should exit with error when drift found

    # Should report orphaned files (THIS WILL FAIL)
    [[ "$output" =~ "orphaned.md" ]]
    [[ "$output" =~ "random-issue.md" ]]
}

@test "check-drift.sh validates all files are linked somewhere" {
    # Create unlinked files
    echo "# Unlinked Doc" > docs/unlinked.md

    # Create current.md without linking the file
    cat > docs/current.md << 'EOF'
# Current Status
No references to unlinked.md
EOF

    # THIS TEST WILL FAIL: Link validation not working
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report unlinked files (THIS WILL FAIL)
    [[ "$output" =~ "unlinked.md" ]]
}

@test "check-drift.sh checks for broken links in documentation" {
    # Create doc with broken link
    cat > docs/current.md << 'EOF'
# Current Status
See [broken link](docs/nonexistent.md)
See @docs/also-missing.md
EOF

    # THIS TEST WILL FAIL: Broken link detection not implemented
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report broken links (THIS WILL FAIL)
    [[ "$output" =~ "nonexistent.md" ]]
    [[ "$output" =~ "also-missing.md" ]]
}

@test "check-drift.sh validates active work items have corresponding tasks" {
    # Create active work without task entry
    echo "# Feature" > docs/active/feature-001.md

    # Create tasks.md without this feature
    cat > docs/tasks.md << 'EOF'
# Tasks
- [ ] Different task
EOF

    # THIS TEST WILL FAIL: Active/task sync not checked
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report mismatch (THIS WILL FAIL)
    [[ "$output" =~ "feature-001" ]]
}

@test "check-drift.sh ensures completed work is moved properly" {
    # Create work item still in active but marked complete
    echo "# Completed Feature" > docs/active/done-feature.md

    # Add to log as completed
    cat > docs/log.md << 'EOF'
2024-01-01: Completed done-feature.md
EOF

    # THIS TEST WILL FAIL: Completed work location not validated
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report misplaced completed work (THIS WILL FAIL)
    [[ "$output" =~ "done-feature.md" ]]
    [[ "$output" =~ "should be in completed" ]]
}

@test "check-drift.sh validates bugs.md references exist" {
    # Create bugs.md with invalid references
    cat > docs/bugs.md << 'EOF'
# Bugs
- [ ] Bug 1 - See docs/issues/bug-001.md
- [ ] Bug 2 - See docs/issues/bug-002.md
EOF

    # Only create one issue file
    echo "# Bug 1" > docs/issues/bug-001.md

    # THIS TEST WILL FAIL: Reference validation not complete
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report missing issue file (THIS WILL FAIL)
    [[ "$output" =~ "bug-002.md" ]]
}

@test "check-drift.sh detects duplicate entries across indexes" {
    # Create duplicate entries
    cat > docs/current.md << 'EOF'
# Current
- feature-x
EOF

    cat > docs/ideas.md << 'EOF'
# Ideas
- feature-x (duplicate!)
EOF

    # THIS TEST WILL FAIL: Duplicate detection not implemented
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report duplicates (THIS WILL FAIL)
    [[ "$output" =~ "feature-x" ]]
    [[ "$output" =~ "duplicate" ]]
}

@test "check-drift.sh validates template consistency" {
    # Create inconsistent templates
    mkdir -p templates/docs
    echo "VERSION=1.0" > templates/docs/template1.md
    echo "VERSION=2.0" > templates/docs/template2.md

    # THIS TEST WILL FAIL: Template consistency not checked
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report version mismatch (THIS WILL FAIL)
    [[ "$output" =~ "VERSION" ]]
    [[ "$output" =~ "inconsistent" ]]
}

@test "check-drift.sh generates drift report" {
    # Create various drift issues
    echo "# Orphan" > docs/orphan.md
    echo "# Unlinked" > docs/issues/unlinked.md

    # THIS TEST WILL FAIL: Report generation not implemented
    run bash check-drift.sh --report
    [ "$status" -ne 0 ]

    # Should create drift report file (THIS WILL FAIL)
    [ -f "docs/drift-report.md" ]

    # Report should contain summary (THIS WILL FAIL)
    run grep "Drift Summary" docs/drift-report.md
    [ "$status" -eq 0 ]
}

@test "check-drift.sh has auto-fix mode for simple issues" {
    # Create fixable issue - orphaned file that should be indexed
    echo "# Feature" > docs/new-feature.md

    # THIS TEST WILL FAIL: Auto-fix not implemented
    run bash check-drift.sh --fix
    [ "$status" -eq 0 ]

    # Should add to current.md (THIS WILL FAIL)
    run grep "new-feature.md" docs/current.md
    [ "$status" -eq 0 ]
}

@test "check-drift.sh respects .driftignore patterns" {
    # Create .driftignore
    cat > .driftignore << 'EOF'
docs/tmp/
*.backup
*-draft.md
EOF

    # Create files that should be ignored
    mkdir -p docs/tmp
    echo "# Tmp" > docs/tmp/ignored.md
    echo "# Backup" > docs/old.backup
    echo "# Draft" > docs/feature-draft.md

    # THIS TEST WILL FAIL: .driftignore not respected
    run bash check-drift.sh
    [ "$status" -eq 0 ]

    # Should not report ignored files (THIS WILL FAIL)
    [[ ! "$output" =~ "ignored.md" ]]
    [[ ! "$output" =~ "old.backup" ]]
    [[ ! "$output" =~ "feature-draft.md" ]]
}

@test "check-drift.sh validates cross-references between specs" {
    # Create specs with cross-references
    mkdir -p specs/001 specs/002

    cat > specs/001/spec.md << 'EOF'
# Spec 001
Depends on: specs/002/spec.md
EOF

    cat > specs/002/spec.md << 'EOF'
# Spec 002
References: specs/003/spec.md (missing!)
EOF

    # THIS TEST WILL FAIL: Cross-reference validation not implemented
    run bash check-drift.sh
    [ "$status" -ne 0 ]

    # Should report missing cross-reference (THIS WILL FAIL)
    [[ "$output" =~ "specs/003/spec.md" ]]
}