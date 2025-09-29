#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing token-metrics.sh token counting functionality

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy script
    cp "${BATS_TEST_DIRNAME}/../../scripts/token-metrics.sh" .

    # Create test documentation
    mkdir -p docs
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "token-metrics.sh counts tokens accurately using tiktoken method" {
    # Create test file with known token count
    cat > docs/test.md << 'EOF'
# Test Document
This is a simple test document with a known number of tokens.
We can use this to verify token counting accuracy.
EOF

    # THIS TEST WILL FAIL: Token counting not accurate
    run bash token-metrics.sh docs/test.md
    [ "$status" -eq 0 ]

    # Should report token count (THIS WILL FAIL)
    [[ "$output" =~ "tokens" ]]

    # Rough estimate: ~20-30 tokens
    TOKEN_COUNT=$(echo "$output" | grep -o '[0-9]\+ tokens' | grep -o '[0-9]\+')
    [ "$TOKEN_COUNT" -gt 15 ]
    [ "$TOKEN_COUNT" -lt 35 ]
}

@test "token-metrics.sh calculates total tokens for directory" {
    # Create multiple files
    echo "File 1 content" > docs/file1.md
    echo "File 2 content" > docs/file2.md
    echo "File 3 content" > docs/file3.md

    # THIS TEST WILL FAIL: Directory totaling not working
    run bash token-metrics.sh docs/
    [ "$status" -eq 0 ]

    # Should show total for all files (THIS WILL FAIL)
    [[ "$output" =~ "Total" ]]
    [[ "$output" =~ "file1.md" ]]
    [[ "$output" =~ "file2.md" ]]
    [[ "$output" =~ "file3.md" ]]
}

@test "token-metrics.sh identifies token-heavy files" {
    # Create small file
    echo "Small" > docs/small.md

    # Create large file (>1000 tokens)
    for i in {1..200}; do
        echo "This is line $i with some content to increase token count significantly." >> docs/large.md
    done

    # THIS TEST WILL FAIL: Heavy file detection not implemented
    run bash token-metrics.sh --threshold 100
    [ "$status" -eq 0 ]

    # Should flag large file (THIS WILL FAIL)
    [[ "$output" =~ "large.md" ]]
    [[ "$output" =~ "exceeds threshold" ]]

    # Should not flag small file
    [[ ! "$output" =~ "small.md.*exceeds" ]]
}

@test "token-metrics.sh supports different token models" {
    # Create test file
    echo "Test content for token counting" > docs/test.md

    # THIS TEST WILL FAIL: Model selection not supported
    run bash token-metrics.sh --model gpt-4 docs/test.md
    [ "$status" -eq 0 ]
    GPT4_COUNT=$(echo "$output" | grep -o '[0-9]\+ tokens' | grep -o '[0-9]\+')

    run bash token-metrics.sh --model claude docs/test.md
    [ "$status" -eq 0 ]
    CLAUDE_COUNT=$(echo "$output" | grep -o '[0-9]\+ tokens' | grep -o '[0-9]\+')

    # Counts might differ slightly between models (THIS WILL FAIL)
    [ -n "$GPT4_COUNT" ]
    [ -n "$CLAUDE_COUNT" ]
}

@test "token-metrics.sh generates optimization suggestions" {
    # Create file with repetitive content
    cat > docs/repetitive.md << 'EOF'
# Documentation
This is documentation.
This is documentation.
This is documentation.
This is documentation.
EOF

    # THIS TEST WILL FAIL: Optimization suggestions not implemented
    run bash token-metrics.sh --analyze docs/repetitive.md
    [ "$status" -eq 0 ]

    # Should suggest optimization (THIS WILL FAIL)
    [[ "$output" =~ "repetitive" ]] || [[ "$output" =~ "optimize" ]]
}

@test "token-metrics.sh tracks token usage over time" {
    # First measurement
    echo "Initial content" > docs/tracked.md
    bash token-metrics.sh --track docs/tracked.md

    # Add more content
    echo "Additional content" >> docs/tracked.md

    # THIS TEST WILL FAIL: Tracking not implemented
    run bash token-metrics.sh --track docs/tracked.md
    [ "$status" -eq 0 ]

    # Should show change (THIS WILL FAIL)
    [[ "$output" =~ "increased" ]] || [[ "$output" =~ "changed" ]]

    # Should have history file (THIS WILL FAIL)
    [ -f ".token-history.json" ]
}

@test "token-metrics.sh exports metrics in different formats" {
    # Create test files
    echo "Content" > docs/test1.md
    echo "More content" > docs/test2.md

    # THIS TEST WILL FAIL: Export formats not supported
    # Test JSON export
    run bash token-metrics.sh --format json docs/
    [ "$status" -eq 0 ]
    [[ "$output" =~ "{" ]]

    # Test CSV export
    run bash token-metrics.sh --format csv docs/
    [ "$status" -eq 0 ]
    [[ "$output" =~ "," ]]

    # Test markdown table
    run bash token-metrics.sh --format markdown docs/
    [ "$status" -eq 0 ]
    [[ "$output" =~ "|" ]]
}

@test "token-metrics.sh calculates cost estimates" {
    # Create file with known size
    for i in {1..100}; do
        echo "Line $i content" >> docs/costly.md
    done

    # THIS TEST WILL FAIL: Cost calculation not implemented
    run bash token-metrics.sh --cost docs/costly.md
    [ "$status" -eq 0 ]

    # Should show cost estimate (THIS WILL FAIL)
    [[ "$output" =~ "$" ]] || [[ "$output" =~ "cost" ]]
}

@test "token-metrics.sh respects ignore patterns" {
    # Create .tokenignore
    cat > .tokenignore << 'EOF'
*.tmp
*-draft.md
node_modules/
EOF

    # Create files
    echo "Count this" > docs/important.md
    echo "Ignore this" > docs/draft-draft.md
    echo "Ignore this too" > docs/temp.tmp

    # THIS TEST WILL FAIL: Ignore patterns not respected
    run bash token-metrics.sh docs/
    [ "$status" -eq 0 ]

    # Should count important.md (THIS WILL FAIL)
    [[ "$output" =~ "important.md" ]]

    # Should not count ignored files
    [[ ! "$output" =~ "draft-draft.md" ]]
    [[ ! "$output" =~ "temp.tmp" ]]
}

@test "token-metrics.sh provides comparative analysis" {
    # Create two directories
    mkdir -p docs/v1 docs/v2
    echo "Version 1 content" > docs/v1/file.md
    echo "Version 2 content with more text" > docs/v2/file.md

    # THIS TEST WILL FAIL: Comparison not implemented
    run bash token-metrics.sh --compare docs/v1 docs/v2
    [ "$status" -eq 0 ]

    # Should show comparison (THIS WILL FAIL)
    [[ "$output" =~ "v1" ]]
    [[ "$output" =~ "v2" ]]
    [[ "$output" =~ "difference" ]] || [[ "$output" =~ "comparison" ]]
}