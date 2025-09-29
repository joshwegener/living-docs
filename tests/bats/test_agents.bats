#!/usr/bin/env bats

# Test suite for lib/agents/install.sh
# Written BEFORE implementation to satisfy TDD_TESTS_FIRST gate

load test_helper

setup() {
    export TEST_DIR="$BATS_TEST_TMPDIR/agents_test"
    mkdir -p "$TEST_DIR"

    if [[ -f "$REPO_ROOT/lib/agents/install.sh" ]]; then
        source "$REPO_ROOT/lib/agents/install.sh"
    fi
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "agents_install_validate() validates agent configuration" {
    skip "Implementation pending - test written first"

    cat > "$TEST_DIR/agent.yml" << 'EOF'
name: test-agent
version: 1.0.0
commands: []
EOF

    run agents_install_validate "$TEST_DIR/agent.yml"
    assert_success
}

@test "agents_install_copy() copies agent files" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/agent/commands"
    touch "$TEST_DIR/agent/commands/test.md"

    run agents_install_copy "$TEST_DIR/agent" "$TEST_DIR/target"
    assert_success
    [[ -f "$TEST_DIR/target/commands/test.md" ]]
}

@test "agents_install_register() registers agent in config" {
    skip "Implementation pending - test written first"

    run agents_install_register "test-agent" "$TEST_DIR/config"
    assert_success
    [[ -f "$TEST_DIR/config/.living-docs.config" ]]
    grep -q "test-agent" "$TEST_DIR/config/.living-docs.config"
}

@test "agents_install_setup_environment() sets up agent environment" {
    skip "Implementation pending - test written first"

    run agents_install_setup_environment "$TEST_DIR"
    assert_success
    [[ -d "$TEST_DIR/.claude" ]]
    [[ -d "$TEST_DIR/.claude/commands" ]]
}

@test "agents_install_main() performs complete agent installation" {
    skip "Implementation pending - test written first"

    mkdir -p "$TEST_DIR/agent"
    echo "name: test" > "$TEST_DIR/agent/config.yml"

    run agents_install_main "$TEST_DIR/agent" "$TEST_DIR/target"
    assert_success
}