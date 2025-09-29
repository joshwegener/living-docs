#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing build-context.sh router functionality

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Initialize git repo for testing
    git init >/dev/null 2>&1

    # Copy script to test directory
    cp "${BATS_TEST_DIRNAME}/../../scripts/build-context.sh" .

    # Create basic structure
    mkdir -p docs/active
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "build-context.sh generates dynamic context.md file" {
    # THIS TEST WILL FAIL: Script doesn't handle edge cases
    run bash build-context.sh
    [ "$status" -eq 0 ]
    [ -f "docs/context.md" ]

    # Check for required sections (THIS WILL FAIL - missing sections)
    run grep "## Current Work" docs/context.md
    [ "$status" -eq 0 ]

    run grep "## Recent Activity" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh detects file types accurately" {
    # Create various file types
    touch test.js test.py test.md test.sh test.yaml

    # THIS TEST WILL FAIL: File type detection is incomplete
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Check all file types are detected (THIS WILL FAIL)
    run grep "js" docs/context.md
    [ "$status" -eq 0 ]

    run grep "py" docs/context.md
    [ "$status" -eq 0 ]

    run grep "md" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh identifies active spec correctly" {
    # Create active spec file
    echo "# Active Spec" > docs/active/feature-001.md

    # THIS TEST WILL FAIL: Active spec detection is broken
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Check active spec is detected (THIS WILL FAIL)
    run grep "feature-001.md" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh reads installed frameworks from config" {
    # Create config file
    cat > .living-docs.config << 'EOF'
INSTALLED_SPECS="spec-kit,aider,cursor"
PROJECT_TYPE="node"
EOF

    # THIS TEST WILL FAIL: Config parsing is incomplete
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Check frameworks are detected (THIS WILL FAIL)
    run grep "spec-kit,aider,cursor" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh handles missing git repository gracefully" {
    # Remove git directory
    rm -rf .git

    # THIS TEST WILL FAIL: No graceful fallback for missing git
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Should still create context file
    [ -f "docs/context.md" ]

    # Should indicate no git repo (THIS WILL FAIL)
    run grep -i "no.*git\|not.*repository" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh updates timestamp on each run" {
    # First run
    bash build-context.sh
    TIMESTAMP1=$(grep "Generated:" docs/context.md | cut -d':' -f2-)

    # Wait a second
    sleep 1

    # Second run
    bash build-context.sh
    TIMESTAMP2=$(grep "Generated:" docs/context.md | cut -d':' -f2-)

    # THIS TEST WILL FAIL: Timestamp not updating properly
    [ "$TIMESTAMP1" != "$TIMESTAMP2" ]
}

@test "build-context.sh routes to correct documentation based on task" {
    # Create test files that should trigger routing
    touch test.spec.js
    touch .gitignore

    # THIS TEST WILL FAIL: Routing logic not implemented
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Should detect testing context (THIS WILL FAIL)
    run grep -i "testing" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh handles deeply nested directory structures" {
    # Create deep directory structure
    mkdir -p very/deep/nested/directory/structure
    cd very/deep/nested/directory/structure

    # THIS TEST WILL FAIL: Path handling for deep directories
    run bash ../../../../../build-context.sh
    [ "$status" -eq 0 ]

    # Check relative directory is correct (THIS WILL FAIL)
    run grep "very/deep/nested/directory/structure" ../../../../../docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh escapes special characters in output" {
    # Create files with special characters
    touch "file'with'quotes.js"
    touch 'file"with"doublequotes.md'
    touch "file\$with\$dollar.sh"

    # THIS TEST WILL FAIL: No proper escaping
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Output should be valid markdown (THIS WILL FAIL)
    # Check file is valid by looking for proper structure
    run grep "^#" docs/context.md
    [ "$status" -eq 0 ]
    [ ${#lines[@]} -gt 0 ]
}

@test "build-context.sh includes recent command history when available" {
    # Create fake history file
    cat > ~/.bash_history << 'EOF'
npm test
git commit -m "test"
npm run build
ls -la
git push
EOF

    # THIS TEST WILL FAIL: History parsing is broken
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Check recent commands are included (THIS WILL FAIL)
    run grep -E "npm|git" docs/context.md
    [ "$status" -eq 0 ]
}

@test "build-context.sh respects token limits" {
    # Create many files to generate large context
    for i in {1..100}; do
        touch "file$i.js"
    done

    # THIS TEST WILL FAIL: No token limit enforcement
    run bash build-context.sh
    [ "$status" -eq 0 ]

    # Check file size is reasonable (less than 10KB)
    FILE_SIZE=$(stat -f%z docs/context.md 2>/dev/null || stat -c%s docs/context.md)
    [ "$FILE_SIZE" -lt 10240 ]
}

@test "build-context.sh handles concurrent execution safely" {
    # THIS TEST WILL FAIL: No locking mechanism
    # Run multiple instances concurrently
    bash build-context.sh &
    PID1=$!

    bash build-context.sh &
    PID2=$!

    # Wait for completion
    wait $PID1
    STATUS1=$?

    wait $PID2
    STATUS2=$?

    # Both should succeed
    [ "$STATUS1" -eq 0 ]
    [ "$STATUS2" -eq 0 ]

    # File should be valid
    [ -f "docs/context.md" ]
    run grep "^#" docs/context.md
    [ "$status" -eq 0 ]
}