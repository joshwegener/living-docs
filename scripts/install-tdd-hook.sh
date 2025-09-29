#!/bin/bash
set -euo pipefail
# install-tdd-hook.sh - Install git pre-commit hook for TDD enforcement

HOOK_FILE=".git/hooks/pre-commit"

# Check if we're in a git repo
if [ ! -d .git ]; then
    echo "ERROR: Not in a git repository root"
    exit 1
fi

# Backup existing hook if present
if [ -f "$HOOK_FILE" ]; then
    echo "Backing up existing pre-commit hook to ${HOOK_FILE}.backup"
    cp "$HOOK_FILE" "${HOOK_FILE}.backup"
fi

# Create the TDD enforcement hook
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# TDD Enforcement Pre-Commit Hook
# Prevents committing implementation without tests

set -e

# Get staged files
IMPL_FILES=$(git diff --cached --name-only | grep -E "^lib/.*\.sh$" || true)
TEST_FILES=$(git diff --cached --name-only | grep -E "^tests/.*\.(bats|sh)$" || true)

# If no implementation files, we're good
if [ -z "$IMPL_FILES" ]; then
    exit 0
fi

# Check if tests are being committed with implementation
if [ -z "$TEST_FILES" ]; then
    echo ""
    echo "❌ TDD VIOLATION: Implementation without tests"
    echo ""
    echo "Files being committed:"
    echo "$IMPL_FILES"
    echo ""
    echo "TDD REQUIREMENT: Tests MUST be written and committed BEFORE implementation"
    echo ""
    echo "To fix:"
    echo "1. Write failing tests for the implementation"
    echo "2. Commit the tests first: git add tests/... && git commit -m 'test: ...'"
    echo "3. Then commit implementation: git add lib/... && git commit -m 'feat: ...'"
    echo ""
    echo "To bypass (NOT RECOMMENDED):"
    echo "git commit --no-verify"
    echo ""
    exit 1
fi

# Check for skipped tests (indicates not following RED phase)
SKIPPED=$(grep -l "skip.*Implementation pending" $TEST_FILES 2>/dev/null || true)
if [ -n "$SKIPPED" ]; then
    echo ""
    echo "⚠️ WARNING: Skipped tests detected"
    echo ""
    echo "Files with skipped tests:"
    echo "$SKIPPED"
    echo ""
    echo "TDD requires tests to FAIL first (RED phase), not be skipped."
    echo "Replace 'skip' with actual failing assertions."
    echo ""
    echo "Continue anyway? (y/N)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        exit 1
    fi
fi

echo "✅ TDD check passed: Tests included with implementation"
EOF

# Make the hook executable
chmod +x "$HOOK_FILE"

echo "✅ TDD enforcement hook installed successfully"
echo ""
echo "The hook will:"
echo "- Block commits of lib/*.sh without corresponding tests"
echo "- Warn about skipped tests (should fail, not skip)"
echo "- Enforce test-first development"
echo ""
echo "To bypass in emergencies: git commit --no-verify"
echo "(But this creates technical debt and compliance violations)"