#!/bin/bash
set -euo pipefail
# build-context.sh - Dynamically builds CONTEXT.md based on current work

# Output file
CONTEXT_FILE="docs/context.md"

# Get current directory relative to project root
CURRENT_DIR=$(pwd)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REL_DIR=${CURRENT_DIR#$PROJECT_ROOT}
REL_DIR=${REL_DIR#/}

# Detect file types in current directory
FILE_TYPES=$(find . -maxdepth 2 -type f -name "*.*" | sed 's/.*\.//' | sort -u | head -5 | tr '\n' ',' | sed 's/,$//')

# Check for active spec
ACTIVE_SPEC=""
if [ -d "docs/active" ]; then
    ACTIVE_SPEC=$(ls docs/active/*.md 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "")
fi

# Check installed frameworks
INSTALLED_SPECS=""
if [ -f ".living-docs.config" ]; then
    INSTALLED_SPECS=$(grep "^INSTALLED_SPECS=" .living-docs.config | cut -d'=' -f2 | tr -d '"')
fi

# Get recent git operations
RECENT_GIT=$(git log --oneline -3 2>/dev/null | head -1 || echo "No recent commits")

# Get recent commands from history (if available)
RECENT_COMMANDS=""
if [ -f ~/.bash_history ]; then
    RECENT_COMMANDS=$(tail -10 ~/.bash_history | grep -E "npm|git|test|build" | tail -3 | tr '\n' ',' | sed 's/,$//' || echo "")
fi

# Build CONTEXT.md
cat > "$CONTEXT_FILE" << EOF
# Dynamic Context
<!-- Generated: $(date '+%Y-%m-%d %H:%M:%S') -->

## Current Work
- **Directory**: ${REL_DIR:-project root}
- **File Types**: ${FILE_TYPES:-none detected}
- **Active Spec**: ${ACTIVE_SPEC:-none}
- **Frameworks**: ${INSTALLED_SPECS:-none}

## Recent Activity
- **Last Commit**: ${RECENT_GIT}
- **Recent Commands**: ${RECENT_COMMANDS:-none tracked}

## Current Tasks
EOF

# Add active work from current.md
if [ -f "docs/current.md" ]; then
    echo "$(grep -A 3 '## 🔥 Active Development' docs/current.md | tail -n +2 | head -3)" >> "$CONTEXT_FILE"
else
    echo "- No active tasks found" >> "$CONTEXT_FILE"
fi

cat >> "$CONTEXT_FILE" << EOF

## Relevant Documentation
EOF

# Add conditional documentation based on context
{
    # Testing context
    if echo "$FILE_TYPES" | grep -qE "test|spec"; then
        echo "- @procedures/testing.md - Test procedures"
    fi

    # Git context
    if echo "$RECENT_COMMANDS" | grep -q "git"; then
        echo "- @procedures/git.md - Git workflows"
    fi

    # Framework-specific rules
    if [ -n "$INSTALLED_SPECS" ]; then
        for spec in $INSTALLED_SPECS; do
            if [ -f "docs/rules/${spec}-rules.md" ]; then
                echo "- @rules/${spec}-rules.md - ${spec} framework rules"
            fi
        done
    fi

    # Shell script context
    if echo "$FILE_TYPES" | grep -qE "sh|bash"; then
        echo "- @knowledge/macos-linux.md - Platform differences"
    fi

    # Bug context
    if [ -f "docs/bugs.md" ] && grep -q "\[ \]" docs/bugs.md 2>/dev/null; then
        BUG_COUNT=$(grep "^- \[ \]" docs/bugs.md | wc -l | tr -d ' ')
        echo "- @bugs.md - ${BUG_COUNT} open bugs"
    fi
} >> "$CONTEXT_FILE"

echo "" >> "$CONTEXT_FILE"
echo "---" >> "$CONTEXT_FILE"
echo "*Context built from: ${REL_DIR:-project root}*" >> "$CONTEXT_FILE"

echo "✅ Context built: $CONTEXT_FILE"

# Show token estimate
TOKEN_ESTIMATE=$(wc -w "$CONTEXT_FILE" | awk '{printf "%.0f", $1 * 1.3}')
echo "📊 Estimated tokens: $TOKEN_ESTIMATE"