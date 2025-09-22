#!/usr/bin/env bats

# Test suite for lib/docs/mermaid.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/mermaid_test"
    mkdir -p "$TEST_DIR"

    # Source the library (will fail initially as expected)
    if [[ -f "$REPO_ROOT/lib/docs/mermaid.sh" ]]; then
        source "$REPO_ROOT/lib/docs/mermaid.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "mermaid_validate_syntax() validates Mermaid diagram syntax" {
    skip "Implementation pending - test written first"

    # Valid flowchart
    cat > "$TEST_DIR/valid.mmd" << 'EOF'
graph TD
    A[Start] --> B[Process]
    B --> C[End]
EOF

    run mermaid_validate_syntax "$TEST_DIR/valid.mmd"
    assert_success

    # Invalid syntax
    cat > "$TEST_DIR/invalid.mmd" << 'EOF'
graph TD
    A[Start --> Missing bracket
EOF

    run mermaid_validate_syntax "$TEST_DIR/invalid.mmd"
    assert_failure
}

@test "mermaid_extract_from_markdown() extracts Mermaid blocks" {
    skip "Implementation pending - test written first"

    cat > "$TEST_DIR/doc.md" << 'EOF'
# Document

Some text here.

```mermaid
graph TD
    A --> B
```

More text.

```mermaid
sequenceDiagram
    Alice->>Bob: Hello
```
EOF

    run mermaid_extract_from_markdown "$TEST_DIR/doc.md"
    assert_success
    assert_output --partial "graph TD"
    assert_output --partial "sequenceDiagram"
}

@test "mermaid_render_to_svg() renders diagram to SVG" {
    skip "Implementation pending - test written first"

    cat > "$TEST_DIR/diagram.mmd" << 'EOF'
graph LR
    A[Input] --> B[Process] --> C[Output]
EOF

    run mermaid_render_to_svg "$TEST_DIR/diagram.mmd" "$TEST_DIR/output.svg"
    assert_success
    [[ -f "$TEST_DIR/output.svg" ]]
}

@test "mermaid_generate_from_structure() creates diagram from project structure" {
    skip "Implementation pending - test written first"

    # Create test project structure
    mkdir -p "$TEST_DIR/src/lib"
    mkdir -p "$TEST_DIR/tests"
    touch "$TEST_DIR/src/main.sh"
    touch "$TEST_DIR/src/lib/helper.sh"
    touch "$TEST_DIR/tests/test.bats"

    run mermaid_generate_from_structure "$TEST_DIR"
    assert_success
    assert_output --partial "graph"
    assert_output --partial "src/main.sh"
}

@test "mermaid_update_diagrams() updates all Mermaid diagrams in docs" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/docs"

    # Create doc with outdated diagram
    cat > "$TEST_DIR/docs/architecture.md" << 'EOF'
# Architecture

<!-- mermaid-auto-generated -->
```mermaid
graph TD
    OLD[Outdated]
```
<!-- /mermaid-auto-generated -->
EOF

    run mermaid_update_diagrams "$TEST_DIR/docs"
    assert_success

    # Should have updated the diagram
    content=$(<"$TEST_DIR/docs/architecture.md")
    [[ ! "$content" =~ "OLD[Outdated]" ]]
}

@test "mermaid_check_consistency() verifies diagrams match reality" {
    skip "Implementation pending - test written first"

    # Create structure that doesn't match diagram
    mkdir -p "$TEST_DIR/src"

    cat > "$TEST_DIR/docs/flow.md" << 'EOF'
```mermaid
graph TD
    A[NonExistentFile.sh] --> B[AlsoMissing.sh]
```
EOF

    run mermaid_check_consistency "$TEST_DIR"
    assert_failure
    assert_output --partial "NonExistentFile.sh not found"
}

@test "mermaid_cli_interface() provides command-line tool" {
    skip "Implementation pending - test written first"

    # Test help
    run mermaid_cli --help
    assert_success
    assert_output --partial "Usage:"

    # Test validation
    echo "graph TD A-->B" | run mermaid_cli validate -
    assert_success

    # Test rendering
    echo "graph TD A-->B" | run mermaid_cli render - "$TEST_DIR/output.svg"
    assert_success
    [[ -f "$TEST_DIR/output.svg" ]]
}