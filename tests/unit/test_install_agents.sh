#!/bin/bash
# Test: Installation of agent templates (T011)
# Should install agent-specific configuration files and templates

set -e

# Setup test environment
export TEST_MODE=true
TEST_DIR=$(mktemp -d)
export PROJECT_ROOT="$TEST_DIR"

# Source the libraries (will be implemented)
source "$(dirname "$0")/../../lib/adapter/install.sh" 2>/dev/null || true
source "$(dirname "$0")/../../lib/adapter/manifest.sh" 2>/dev/null || true

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test function
test_install_agents() {
    echo "Testing: Installation of agent templates"

    # Setup mock agent adapter with various agent types
    mkdir -p "$TEST_DIR/tmp/agent-os/agents"
    mkdir -p "$TEST_DIR/tmp/agent-os/templates"
    mkdir -p "$TEST_DIR/tmp/agent-os/config"

    # Create agent templates for different roles
    cat > "$TEST_DIR/tmp/agent-os/agents/developer.md" <<'EOF'
# Developer Agent
Role: Senior Software Developer
Specialization: Full-stack development
Context: \$SPECS_PATH/current/
Scripts: \$SCRIPTS_PATH/development/
Memory: \$MEMORY_PATH/development/
EOF

    cat > "$TEST_DIR/tmp/agent-os/agents/reviewer.md" <<'EOF'
# Code Reviewer Agent
Role: Technical Lead / Code Reviewer
Specialization: Code quality and architecture review
Context: \$SPECS_PATH/review/
Scripts: \$SCRIPTS_PATH/review/
Memory: \$MEMORY_PATH/review/
EOF

    cat > "$TEST_DIR/tmp/agent-os/agents/tester.md" <<'EOF'
# Testing Agent
Role: QA Engineer
Specialization: Test automation and quality assurance
Context: \$SPECS_PATH/testing/
Scripts: \$SCRIPTS_PATH/testing/
Memory: \$MEMORY_PATH/testing/
EOF

    # Create configuration templates
    cat > "$TEST_DIR/tmp/agent-os/config/agent-config.yml" <<'EOF'
agents:
  developer:
    model: claude-3-sonnet
    temperature: 0.2
    max_tokens: 4000
  reviewer:
    model: claude-3-opus
    temperature: 0.1
    max_tokens: 8000
  tester:
    model: claude-3-haiku
    temperature: 0.3
    max_tokens: 2000

paths:
  specs: \$SPECS_PATH
  scripts: \$SCRIPTS_PATH
  memory: \$MEMORY_PATH
EOF

    # Create workflow templates
    cat > "$TEST_DIR/tmp/agent-os/templates/workflow.md" <<'EOF'
# Agent Workflow Template
1. Developer creates feature
2. Reviewer validates code
3. Tester creates test suite
4. All agents collaborate on documentation

Agents Directory: \$AGENTS_PATH/
EOF

    # Test installation of agent adapter
    local result
    if result=$(install_adapter "agent-os" --type=agents 2>&1); then
        echo "✓ Agent adapter installation completed"
    else
        echo "✗ Agent installation failed: $result"
        return 1
    fi

    # Check that agent files are installed in correct location
    if [[ -f "$PROJECT_ROOT/.claude/agents/developer.md" ]]; then
        echo "✓ Developer agent installed"
    else
        echo "✗ Developer agent not found"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/.claude/agents/reviewer.md" ]]; then
        echo "✓ Reviewer agent installed"
    else
        echo "✗ Reviewer agent not found"
        return 1
    fi

    if [[ -f "$PROJECT_ROOT/.claude/agents/tester.md" ]]; then
        echo "✓ Tester agent installed"
    else
        echo "✗ Tester agent not found"
        return 1
    fi

    # Check configuration file installation
    if [[ -f "$PROJECT_ROOT/.claude/config/agent-config.yml" ]]; then
        echo "✓ Agent configuration installed"
    else
        echo "✗ Agent configuration not found"
        return 1
    fi

    # Check template installation
    if [[ -f "$PROJECT_ROOT/templates/workflow.md" ]]; then
        echo "✓ Workflow template installed"
    else
        echo "✗ Workflow template not found"
        return 1
    fi

    # Verify path rewriting in agent files
    if grep -q "\$SPECS_PATH" "$PROJECT_ROOT/.claude/agents/developer.md"; then
        echo "✓ Path variables preserved in agent files"
    else
        echo "✗ Path variables not found in agent files"
        return 1
    fi

    # Test custom agent paths
    export AGENTS_PATH="/custom/agents"
    export AGENT_CONFIG_PATH="/custom/config"

    mkdir -p "$TEST_DIR/tmp/custom-agents/agents"
    echo "# Custom agent" > "$TEST_DIR/tmp/custom-agents/agents/custom.md"

    if result=$(install_adapter "custom-agents" --custom-paths 2>&1); then
        echo "✓ Custom agent paths installation completed"
    else
        echo "✗ Custom paths installation failed: $result"
        return 1
    fi

    # Check custom path installation
    if [[ -f "/custom/agents/custom.md" ]] || [[ -f "$PROJECT_ROOT/custom/agents/custom.md" ]]; then
        echo "✓ Agent installed with custom path"
    else
        echo "✗ Custom path not used for agent installation"
        return 1
    fi

    # Test agent-specific manifest tracking
    if [[ -f "$PROJECT_ROOT/adapters/agent-os/.living-docs-manifest.json" ]]; then
        local manifest_content
        manifest_content=$(cat "$PROJECT_ROOT/adapters/agent-os/.living-docs-manifest.json")

        if echo "$manifest_content" | grep -q "agents/developer.md"; then
            echo "✓ Agent files tracked in manifest"
        else
            echo "✗ Agent files not tracked in manifest"
            return 1
        fi

        if echo "$manifest_content" | grep -q '"type": "agents"'; then
            echo "✓ Adapter type marked as agents in manifest"
        else
            echo "✗ Adapter type not specified in manifest"
            return 1
        fi
    else
        echo "✗ Agent adapter manifest not created"
        return 1
    fi

    # Test agent activation/deactivation
    if result=$(activate_agent "developer" 2>&1); then
        echo "✓ Agent activation functionality present"
    else
        echo "? Agent activation not implemented yet (expected)"
    fi

    # Test multi-agent workflow setup
    if [[ -f "$PROJECT_ROOT/templates/workflow.md" ]]; then
        if grep -q "All agents collaborate" "$PROJECT_ROOT/templates/workflow.md"; then
            echo "✓ Multi-agent workflow template properly installed"
        else
            echo "✗ Workflow template content missing"
            return 1
        fi
    fi

    echo "✓ Test passed: Agent template installation"
    return 0
}

# Run the test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_install_agents
    exit $?
fi