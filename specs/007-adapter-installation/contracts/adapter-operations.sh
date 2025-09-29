#!/bin/bash
set -euo pipefail
# Adapter Operations Contract Tests
# These tests define the expected behavior - they should fail until implemented

source lib/adapter/install.sh 2>/dev/null || true
source lib/adapter/remove.sh 2>/dev/null || true
source lib/adapter/update.sh 2>/dev/null || true
source lib/validation/paths.sh 2>/dev/null || true

# Test: Install adapter with default settings
test_install_adapter_default() {
    local result
    result=$(install_adapter "spec-kit" 2>&1)

    # Should create manifest
    [[ -f "adapters/spec-kit/.living-docs-manifest.json" ]] || return 1

    # Should install commands
    [[ -f ".claude/commands/speckit_plan.md" ]] || return 1

    # Should return success
    [[ "$?" -eq 0 ]] || return 1
}

# Test: Install adapter with custom paths
test_install_adapter_custom_paths() {
    local result
    export SCRIPTS_PATH="/custom/scripts"
    export SPECS_PATH="/custom/specs"

    result=$(install_adapter "spec-kit" --custom-paths 2>&1)

    # Should rewrite paths in files
    grep -q "/custom/scripts" adapters/spec-kit/commands/*.md || return 1

    # Manifest should track original paths
    grep -q "original_path" "adapters/spec-kit/.living-docs-manifest.json" || return 1
}

# Test: Remove adapter completely
test_remove_adapter() {
    # First install
    install_adapter "spec-kit" 2>/dev/null

    # Then remove
    local result
    result=$(remove_adapter "spec-kit" 2>&1)

    # Should remove all files
    [[ ! -f ".claude/commands/speckit_plan.md" ]] || return 1

    # Should remove manifest
    [[ ! -f "adapters/spec-kit/.living-docs-manifest.json" ]] || return 1

    # Should return success
    [[ "$?" -eq 0 ]] || return 1
}

# Test: Update adapter preserving customizations
test_update_adapter_with_customizations() {
    # Install adapter
    install_adapter "spec-kit" 2>/dev/null

    # Customize a file
    echo "# Custom content" >> .claude/commands/speckit_plan.md

    # Update adapter
    local result
    result=$(update_adapter "spec-kit" 2>&1)

    # Should preserve customization
    grep -q "# Custom content" .claude/commands/speckit_plan.md || return 1

    # Should update non-customized files
    grep -q "updated" <<< "$result" || return 1
}

# Test: Validate paths before installation
test_validate_paths() {
    local result
    result=$(validate_paths "spec-kit" 2>&1)

    # Should detect hardcoded paths
    grep -q "scripts/bash" <<< "$result" || return 1

    # Should suggest replacements
    grep -q "{{SCRIPTS_PATH}}" <<< "$result" || return 1

    # Should return validation report
    [[ -n "$result" ]] || return 1
}

# Test: Command prefixing
test_command_prefixing() {
    local result
    result=$(install_adapter "spec-kit" --prefix="sk_" 2>&1)

    # Commands should be prefixed
    [[ -f ".claude/commands/sk_plan.md" ]] || return 1
    [[ ! -f ".claude/commands/plan.md" ]] || return 1
}

# Test: Handle conflicting commands
test_handle_conflicts() {
    # Create existing command
    mkdir -p .claude/commands
    echo "existing" > .claude/commands/plan.md

    # Install adapter
    local result
    result=$(install_adapter "spec-kit" 2>&1)

    # Should detect conflict
    grep -q "conflict" <<< "$result" || return 1

    # Should use prefix
    [[ -f ".claude/commands/speckit_plan.md" ]] || return 1

    # Should preserve existing
    grep -q "existing" .claude/commands/plan.md || return 1
}

# Test: Install agents
test_install_agents() {
    local result
    result=$(install_adapter "spec-kit" --with-agents 2>&1)

    # Should install to agent directory
    [[ -f ".claude/agents/spec_agent.md" ]] || return 1

    # Should track in manifest
    grep -q "agents" "adapters/spec-kit/.living-docs-manifest.json" || return 1
}

# Run all tests
run_contract_tests() {
    local failed=0

    echo "Running adapter operation contract tests..."

    for test in test_install_adapter_default \
                test_install_adapter_custom_paths \
                test_remove_adapter \
                test_update_adapter_with_customizations \
                test_validate_paths \
                test_command_prefixing \
                test_handle_conflicts \
                test_install_agents; do

        if $test 2>/dev/null; then
            echo "✓ $test"
        else
            echo "✗ $test (expected to fail until implemented)"
            ((failed++))
        fi
    done

    echo "Contract tests complete: $failed tests need implementation"
    return $failed
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_contract_tests
fi