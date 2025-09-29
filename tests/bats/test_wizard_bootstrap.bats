#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing wizard.sh bootstrap functionality

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy wizard.sh to test directory
    cp "${BATS_TEST_DIRNAME}/../../wizard.sh" .

    # Create minimal templates directory
    mkdir -p templates/docs
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "wizard.sh creates bootstrap.md from template when it exists" {
    # Create a template file
    cat > templates/docs/bootstrap.md.template << 'EOF'
# Bootstrap Template
Version: TEST_VERSION
EOF

    # THIS TEST WILL FAIL: wizard.sh doesn't properly substitute template variables
    run bash wizard.sh init
    [ "$status" -eq 0 ]
    [ -f "docs/bootstrap.md" ]

    # Check that template variables are substituted (THIS WILL FAIL)
    run grep "Version: TEST_VERSION" docs/bootstrap.md
    [ "$status" -ne 0 ]  # Should NOT find raw template text

    # Check that actual version is inserted (THIS WILL FAIL)
    run grep "Version: [0-9]" docs/bootstrap.md
    [ "$status" -eq 0 ]
}

@test "wizard.sh creates minimal bootstrap.md when template is missing" {
    # No template created
    rm -rf templates/docs

    # THIS TEST WILL FAIL: wizard.sh doesn't handle missing template gracefully
    run bash wizard.sh init
    [ "$status" -eq 0 ]
    [ -f "docs/bootstrap.md" ]

    # Check minimal content (THIS WILL FAIL - content check)
    run grep "Bootstrap Router" docs/bootstrap.md
    [ "$status" -eq 0 ]
}

@test "wizard.sh includes framework rules in bootstrap" {
    # Set up framework rules
    mkdir -p docs/rules
    echo "# Spec Kit Rules" > docs/rules/spec-kit-rules.md
    echo "# Aider Rules" > docs/rules/aider-rules.md

    # Create config with installed specs
    cat > .living-docs.config << 'EOF'
INSTALLED_SPECS="spec-kit,aider"
EOF

    # THIS TEST WILL FAIL: include_rules_in_bootstrap function not properly tested
    run bash wizard.sh init
    [ "$status" -eq 0 ]

    # Check rules are included (THIS WILL FAIL)
    run grep "@rules/spec-kit-rules.md" docs/bootstrap.md
    [ "$status" -eq 0 ]

    run grep "@rules/aider-rules.md" docs/bootstrap.md
    [ "$status" -eq 0 ]
}

@test "wizard.sh bootstrap handles invalid template syntax" {
    # Create template with invalid syntax
    mkdir -p templates/docs
    cat > templates/docs/bootstrap.md.template << 'EOF'
# Invalid Template
{{UNDEFINED_VAR}}
$((MATH_EXPRESSION_THAT_FAILS))
EOF

    # THIS TEST WILL FAIL: No error handling for invalid templates
    run bash wizard.sh init
    [ "$status" -eq 0 ]  # Should still succeed with fallback
    [ -f "docs/bootstrap.md" ]

    # Should not contain error messages in output
    run grep "UNDEFINED_VAR" docs/bootstrap.md
    [ "$status" -ne 0 ]
}

@test "wizard.sh preserves existing bootstrap.md customizations on update" {
    # Create existing bootstrap with customizations
    mkdir -p docs
    cat > docs/bootstrap.md << 'EOF'
# Bootstrap Router
<!-- Custom Section Start -->
My important customization
<!-- Custom Section End -->
EOF

    # THIS TEST WILL FAIL: wizard.sh overwrites without preserving customizations
    run bash wizard.sh update
    [ "$status" -eq 0 ]

    # Check customization is preserved (THIS WILL FAIL)
    run grep "My important customization" docs/bootstrap.md
    [ "$status" -eq 0 ]
}

@test "wizard.sh bootstrap validates required directories exist" {
    # Remove required directories
    rm -rf templates

    # THIS TEST WILL FAIL: No validation of required directories
    run bash wizard.sh init

    # Should report missing templates directory
    [[ "$output" =~ "templates" ]]

    # Should still create bootstrap with fallback
    [ -f "docs/bootstrap.md" ]
}

@test "wizard.sh bootstrap handles concurrent updates safely" {
    mkdir -p docs

    # THIS TEST WILL FAIL: No locking mechanism for concurrent updates
    # Start two wizard processes in background
    bash wizard.sh init &
    PID1=$!

    bash wizard.sh init &
    PID2=$!

    # Wait for both to complete
    wait $PID1
    STATUS1=$?

    wait $PID2
    STATUS2=$?

    # Both should succeed
    [ "$STATUS1" -eq 0 ]
    [ "$STATUS2" -eq 0 ]

    # Bootstrap should be valid (not corrupted)
    [ -f "docs/bootstrap.md" ]
    run grep "^#" docs/bootstrap.md
    [ "$status" -eq 0 ]
}

@test "wizard.sh bootstrap correctly sets up token optimization" {
    # THIS TEST WILL FAIL: Token metrics not properly integrated in bootstrap
    run bash wizard.sh init
    [ "$status" -eq 0 ]

    # Check for token optimization references
    run grep -i "token" docs/bootstrap.md
    [ "$status" -eq 0 ]

    # Check for dynamic loading configuration
    run grep "Conditional Documentation Loading" docs/bootstrap.md
    [ "$status" -eq 0 ]
}