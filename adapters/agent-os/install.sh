#!/bin/bash
set -euo pipefail

# Agent OS Adapter Installation Script
# Installs Agent OS with dated specification folders

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

# Source path rewriting functions
source "$ADAPTER_DIR/../common/path-rewrite.sh"

echo "🤖 Installing Agent OS..."

# Load configuration if it exists
if [ -f "$PROJECT_ROOT/.living-docs.config" ]; then
    source "$PROJECT_ROOT/.living-docs.config"
fi

# Set default paths if not configured
LIVING_DOCS_PATH="${LIVING_DOCS_PATH:-docs}"
AI_PATH="${AI_PATH:-$LIVING_DOCS_PATH}"
AGENT_OS_PATH="$AI_PATH/agent-os"

echo "  Installing to: $AGENT_OS_PATH"

# Create temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy templates to temp directory
cp -r "$ADAPTER_DIR/templates/.agent-os" "$TEMP_DIR/"

# Rewrite paths in all files
echo "  Configuring for your environment..."
rewrite_directory "$TEMP_DIR" "$LIVING_DOCS_PATH" "$AI_PATH" "$AGENT_OS_PATH/specs" "$AGENT_OS_PATH/memory" "$AGENT_OS_PATH/scripts"

# Create target directories
mkdir -p "$PROJECT_ROOT/$AGENT_OS_PATH/standards"
mkdir -p "$PROJECT_ROOT/$AGENT_OS_PATH/product"
mkdir -p "$PROJECT_ROOT/$AGENT_OS_PATH/specs"

# Copy files
echo "  Installing Agent OS structure..."
cp -r "$TEMP_DIR/.agent-os/"* "$PROJECT_ROOT/$AGENT_OS_PATH/"

# Create first dated spec as example
TODAY=$(date +%Y-%m-%d)
EXAMPLE_SPEC="$PROJECT_ROOT/$AGENT_OS_PATH/specs/${TODAY}-example-feature"
if [ ! -d "$EXAMPLE_SPEC" ]; then
    echo "  Creating example specification..."
    mkdir -p "$EXAMPLE_SPEC"

    cat > "$EXAMPLE_SPEC/spec.md" << 'EOF'
# Specification: Example Feature

## Overview
This is an example specification using Agent OS's dated folder structure.

## Context
Explain why this feature is needed and what problem it solves.

## Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## Implementation Notes
Describe how to implement this feature.

## Success Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

## References
Link to relevant documentation or discussions.
EOF
fi

# Create helper script for new specs
cat > "$PROJECT_ROOT/$AGENT_OS_PATH/new-spec.sh" << 'EOF'
#!/bin/bash

# Create a new dated specification
# Usage: ./new-spec.sh feature-name

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 feature-name"
    echo "Example: $0 user-authentication"
    exit 1
fi

FEATURE_NAME="$1"
DATE=$(date +%Y-%m-%d)
SPEC_DIR="$(dirname "$0")/specs/${DATE}-${FEATURE_NAME}"

if [ -d "$SPEC_DIR" ]; then
    echo "Spec already exists: $SPEC_DIR"
    exit 1
fi

mkdir -p "$SPEC_DIR"

cat > "$SPEC_DIR/spec.md" << 'SPEC_EOF'
# Specification: ${FEATURE_NAME}

## Overview
[Brief description]

## Context
[Why this is needed]

## Requirements
- Requirement 1
- Requirement 2

## Implementation Notes
[How to build this]

## Success Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## References
[Links and resources]
SPEC_EOF

echo "Created: $SPEC_DIR/spec.md"
echo "Edit the specification to define your feature."
EOF

chmod +x "$PROJECT_ROOT/$AGENT_OS_PATH/new-spec.sh"

# Update .living-docs.config
if ! grep -q "agent-os" "$PROJECT_ROOT/.living-docs.config" 2>/dev/null; then
    echo "INSTALLED_SPECS=\"${INSTALLED_SPECS} agent-os\"" >> "$PROJECT_ROOT/.living-docs.config"
    echo "AGENT_OS_VERSION=\"1.0.0\"" >> "$PROJECT_ROOT/.living-docs.config"
    echo "AGENT_OS_PATH=\"$AGENT_OS_PATH\"" >> "$PROJECT_ROOT/.living-docs.config"
fi

echo "✅ Agent OS installed successfully!"
echo ""
echo "Structure created:"
echo "  $AGENT_OS_PATH/standards/ - How you build"
echo "  $AGENT_OS_PATH/product/   - What you're building"
echo "  $AGENT_OS_PATH/specs/     - What to build next (dated folders)"
echo ""
echo "Next steps:"
echo "1. Edit $AGENT_OS_PATH/product/product-overview.md"
echo "2. Review $AGENT_OS_PATH/standards/coding-standards.md"
echo "3. Create new specs: $AGENT_OS_PATH/new-spec.sh feature-name"