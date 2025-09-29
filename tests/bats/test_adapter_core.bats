#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing core adapter management scripts

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy adapter libraries
    mkdir -p lib/adapter
    cp -r "${BATS_TEST_DIRNAME}/../../lib/adapter/"*.sh lib/adapter/
    cp "${BATS_TEST_DIRNAME}/../../lib/adapter/"*.json lib/adapter/ 2>/dev/null || true

    # Create test adapter structure
    mkdir -p adapters/test-adapter
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "install.sh validates adapter structure before installation" {
    # Create invalid adapter (missing required files)
    cat > adapters/test-adapter/adapter.yaml << 'EOF'
name: test-adapter
version: 1.0.0
EOF

    # THIS TEST WILL FAIL: No proper validation
    source lib/adapter/install.sh
    run validate_adapter_structure "adapters/test-adapter"
    [ "$status" -ne 0 ]

    # Should report missing required files (THIS WILL FAIL)
    [[ "$output" =~ "commands" ]]
}

@test "install.sh prevents conflicting command names" {
    # Create adapter with conflicting commands
    mkdir -p adapters/test-adapter/commands
    echo "#!/bin/bash" > adapters/test-adapter/commands/plan
    echo "#!/bin/bash" > adapters/test-adapter/commands/test

    # Simulate existing command
    mkdir -p docs/commands
    echo "existing" > docs/commands/plan

    # THIS TEST WILL FAIL: No conflict detection
    source lib/adapter/install.sh
    run check_command_conflicts "adapters/test-adapter"
    [ "$status" -ne 0 ]

    # Should report conflict (THIS WILL FAIL)
    [[ "$output" =~ "conflict" ]]
    [[ "$output" =~ "plan" ]]
}

@test "install.sh creates manifest file during installation" {
    # Create valid adapter
    mkdir -p adapters/test-adapter/commands
    echo "#!/bin/bash" > adapters/test-adapter/commands/build

    # THIS TEST WILL FAIL: Manifest creation not working
    source lib/adapter/install.sh
    run install_adapter "test-adapter" "adapters/test-adapter"
    [ "$status" -eq 0 ]

    # Should create manifest (THIS WILL FAIL)
    [ -f ".living-docs-manifest-test-adapter.json" ]

    # Manifest should contain file list (THIS WILL FAIL)
    run grep "commands/test-adapter_build" .living-docs-manifest-test-adapter.json
    [ "$status" -eq 0 ]
}

@test "manifest.sh validates manifest schema" {
    # Create invalid manifest
    cat > .living-docs-manifest-test.json << 'EOF'
{
  "invalid": "structure"
}
EOF

    # THIS TEST WILL FAIL: Schema validation not implemented
    source lib/adapter/manifest.sh
    run validate_manifest ".living-docs-manifest-test.json"
    [ "$status" -ne 0 ]

    # Should report schema errors (THIS WILL FAIL)
    [[ "$output" =~ "schema" ]]
}

@test "manifest.sh tracks all installed files correctly" {
    # THIS TEST WILL FAIL: File tracking incomplete
    source lib/adapter/manifest.sh

    # Add files to manifest
    init_manifest "test-adapter"
    add_to_manifest "test-adapter" "docs/commands/test_command.md"
    add_to_manifest "test-adapter" "docs/rules/test_rules.md"

    # Check manifest contains all files (THIS WILL FAIL)
    run get_manifest_files "test-adapter"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test_command.md" ]]
    [[ "$output" =~ "test_rules.md" ]]
}

@test "remove.sh completely removes adapter using manifest" {
    # Create installed adapter with manifest
    mkdir -p docs/commands docs/rules
    echo "command" > docs/commands/test_command
    echo "rule" > docs/rules/test_rule.md

    cat > .living-docs-manifest-test.json << 'EOF'
{
  "adapter": "test",
  "version": "1.0.0",
  "files": [
    "docs/commands/test_command",
    "docs/rules/test_rule.md"
  ]
}
EOF

    # THIS TEST WILL FAIL: Remove not using manifest properly
    source lib/adapter/remove.sh
    run remove_adapter "test"
    [ "$status" -eq 0 ]

    # All files should be removed (THIS WILL FAIL)
    [ ! -f "docs/commands/test_command" ]
    [ ! -f "docs/rules/test_rule.md" ]
    [ ! -f ".living-docs-manifest-test.json" ]
}

@test "remove.sh preserves user customizations" {
    # Create adapter file with user customizations
    cat > docs/commands/test_command << 'EOF'
#!/bin/bash
# ADAPTER: test-adapter
echo "Original"
# USER CUSTOMIZATION START
echo "User added this"
# USER CUSTOMIZATION END
EOF

    # THIS TEST WILL FAIL: Customization preservation not implemented
    source lib/adapter/remove.sh
    run remove_adapter "test" --preserve-customizations
    [ "$status" -eq 0 ]

    # Customizations should be saved (THIS WILL FAIL)
    [ -f "docs/customizations/test_command.custom" ]
    run grep "User added this" docs/customizations/test_command.custom
    [ "$status" -eq 0 ]
}

@test "prefix.sh correctly prefixes command names" {
    # THIS TEST WILL FAIL: Prefixing logic incomplete
    source lib/adapter/prefix.sh

    # Test various command names
    run prefix_command "test-adapter" "plan"
    [ "$status" -eq 0 ]
    [ "$output" = "test-adapter_plan" ]

    run prefix_command "spec-kit" "build"
    [ "$status" -eq 0 ]
    [ "$output" = "speckit_build" ]
}

@test "rewrite.sh replaces hardcoded paths with variables" {
    # Create file with hardcoded paths
    cat > test_file.sh << 'EOF'
#!/bin/bash
source /home/user/project/lib/helper.sh
cat /home/user/project/docs/current.md
EOF

    # THIS TEST WILL FAIL: Path rewriting not working
    source lib/adapter/rewrite.sh
    run rewrite_paths "test_file.sh" "/home/user/project"
    [ "$status" -eq 0 ]

    # Check paths are replaced (THIS WILL FAIL)
    run grep '$PROJECT_ROOT' test_file.sh
    [ "$status" -eq 0 ]
    run grep '/home/user/project' test_file.sh
    [ "$status" -ne 0 ]  # Should not find hardcoded paths
}

@test "update.sh preserves customizations during update" {
    # Create existing installation with customizations
    cat > docs/commands/adapter_command << 'EOF'
#!/bin/bash
# VERSION: 1.0.0
echo "Original"
# CUSTOM START
echo "User modification"
# CUSTOM END
EOF

    # Create new version
    mkdir -p adapters/adapter-v2/commands
    cat > adapters/adapter-v2/commands/command << 'EOF'
#!/bin/bash
# VERSION: 2.0.0
echo "Updated"
EOF

    # THIS TEST WILL FAIL: Update doesn't preserve customizations
    source lib/adapter/update.sh
    run update_adapter "adapter" "adapters/adapter-v2"
    [ "$status" -eq 0 ]

    # Check version updated but customization preserved (THIS WILL FAIL)
    run grep "VERSION: 2.0.0" docs/commands/adapter_command
    [ "$status" -eq 0 ]
    run grep "User modification" docs/commands/adapter_command
    [ "$status" -eq 0 ]
}

@test "install.sh handles circular dependencies" {
    # Create adapters with circular dependencies
    cat > adapters/adapter-a/adapter.yaml << 'EOF'
name: adapter-a
dependencies:
  - adapter-b
EOF

    cat > adapters/adapter-b/adapter.yaml << 'EOF'
name: adapter-b
dependencies:
  - adapter-a
EOF

    # THIS TEST WILL FAIL: No circular dependency detection
    source lib/adapter/install.sh
    run install_with_dependencies "adapter-a"
    [ "$status" -ne 0 ]

    # Should report circular dependency (THIS WILL FAIL)
    [[ "$output" =~ "circular" ]]
}

@test "manifest.sh supports rollback to previous version" {
    # Create version history
    cat > .living-docs-manifest-test.json << 'EOF'
{
  "adapter": "test",
  "version": "2.0.0",
  "previous_version": "1.0.0",
  "rollback_data": {
    "files": ["old_file.md"],
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
EOF

    # THIS TEST WILL FAIL: Rollback not implemented
    source lib/adapter/manifest.sh
    run rollback_adapter "test"
    [ "$status" -eq 0 ]

    # Should restore previous version (THIS WILL FAIL)
    run get_adapter_version "test"
    [ "$status" -eq 0 ]
    [ "$output" = "1.0.0" ]
}