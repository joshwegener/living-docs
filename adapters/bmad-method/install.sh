#!/bin/bash
set -euo pipefail

# BMAD-Method Adapter Installation Script
# Installs BMAD multi-agent system with Node.js detection

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

# Source path rewriting functions
source "$ADAPTER_DIR/../common/path-rewrite.sh"

echo "🚀 Installing BMAD-Method..."

# Check for Node.js
check_nodejs() {
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        echo "  ✓ Node.js detected: $NODE_VERSION"

        # Check if version is 20+
        MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/v//')
        if [ "$MAJOR_VERSION" -lt 20 ]; then
            echo "  ⚠️  BMAD requires Node.js 20+. Current: $NODE_VERSION"
            return 1
        fi
        return 0
    else
        echo "  ❌ Node.js not found"
        return 1
    fi
}

# Offer to install Node.js
install_nodejs() {
    echo ""
    echo "BMAD-Method requires Node.js 20+ for multi-agent functionality."
    echo ""
    echo "Options:"
    echo "1) Install Node.js via nvm (recommended)"
    echo "2) Install Node.js via brew (macOS)"
    echo "3) Skip Node.js (BMAD will have limited functionality)"
    echo "4) Cancel installation"
    echo ""
    read -p "Choose an option [1-4]: " choice

    case $choice in
        1)
            echo "Installing Node.js via nvm..."
            if ! command -v nvm >/dev/null 2>&1; then
                echo "Installing nvm first..."
                curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
                export NVM_DIR="$HOME/.nvm"
                [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            fi
            nvm install 20
            nvm use 20
            ;;
        2)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "Installing Node.js via Homebrew..."
                if ! command -v brew >/dev/null 2>&1; then
                    echo "Homebrew not found. Please install Homebrew first."
                    exit 1
                fi
                brew install node@20
            else
                echo "Homebrew is only available on macOS."
                exit 1
            fi
            ;;
        3)
            echo "⚠️  Continuing without Node.js. Some BMAD features will be unavailable."
            SKIP_NODE=true
            ;;
        4)
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            echo "Invalid option."
            exit 1
            ;;
    esac
}

# Check Node.js
if ! check_nodejs; then
    install_nodejs
fi

# Load configuration if it exists
if [ -f "$PROJECT_ROOT/.living-docs.config" ]; then
    source "$PROJECT_ROOT/.living-docs.config"
fi

# Set default paths if not configured
LIVING_DOCS_PATH="${LIVING_DOCS_PATH:-docs}"
AI_PATH="${AI_PATH:-$LIVING_DOCS_PATH}"
SPECS_PATH="${SPECS_PATH:-$LIVING_DOCS_PATH/specs}"
BMAD_PATH="$AI_PATH/bmad"

echo "  Installing to: $BMAD_PATH"

# Create temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy templates to temp directory
cp -r "$ADAPTER_DIR/templates/"* "$TEMP_DIR/"

# Rewrite paths in all files
echo "  Configuring for your environment..."
rewrite_directory "$TEMP_DIR" "$LIVING_DOCS_PATH" "$AI_PATH" "$SPECS_PATH" "$BMAD_PATH/memory" "$BMAD_PATH/scripts"

# Create target directories
mkdir -p "$PROJECT_ROOT/$BMAD_PATH"
mkdir -p "$PROJECT_ROOT/$SPECS_PATH"

# Copy templates
echo "  Installing BMAD templates..."
cp "$TEMP_DIR/spec.md" "$PROJECT_ROOT/$SPECS_PATH/bmad-spec.md.template" 2>/dev/null || true
cp "$TEMP_DIR/tasks.md" "$PROJECT_ROOT/$SPECS_PATH/bmad-tasks.md.template" 2>/dev/null || true

# Create package.json for BMAD if Node.js is available
if [ "$SKIP_NODE" != "true" ] && command -v node >/dev/null 2>&1; then
    cat > "$PROJECT_ROOT/$BMAD_PATH/package.json" << EOF
{
  "name": "bmad-project",
  "version": "1.0.0",
  "description": "BMAD-Method multi-agent development",
  "scripts": {
    "install:bmad": "npx bmad-method install",
    "update:bmad": "npx bmad-method update",
    "analyst": "npx bmad-method analyst",
    "pm": "npx bmad-method pm",
    "architect": "npx bmad-method architect",
    "developer": "npx bmad-method developer",
    "qa": "npx bmad-method qa"
  },
  "keywords": ["bmad", "ai", "agents"],
  "license": "MIT"
}
EOF

    echo "  Creating BMAD command shortcuts..."
    cat > "$PROJECT_ROOT/$BMAD_PATH/bmad.sh" << 'EOF'
#!/bin/bash
# BMAD-Method command wrapper

COMMAND="$1"
shift

case "$COMMAND" in
    analyst|pm|architect|developer|qa)
        npx bmad-method "$COMMAND" "$@"
        ;;
    install)
        npm run install:bmad
        ;;
    update)
        npm run update:bmad
        ;;
    *)
        echo "Usage: $0 {analyst|pm|architect|developer|qa|install|update}"
        echo ""
        echo "Agent commands:"
        echo "  analyst   - Run analyst agent"
        echo "  pm        - Run PM agent"
        echo "  architect - Run architect agent"
        echo "  developer - Run developer agent"
        echo "  qa        - Run QA agent"
        echo ""
        echo "Maintenance:"
        echo "  install   - Install/update BMAD"
        echo "  update    - Update BMAD to latest"
        exit 1
        ;;
esac
EOF
    chmod +x "$PROJECT_ROOT/$BMAD_PATH/bmad.sh"
fi

# Create BMAD configuration
cat > "$PROJECT_ROOT/$BMAD_PATH/.bmadrc" << EOF
{
  "project": {
    "name": "$(basename "$PROJECT_ROOT")",
    "type": "multi-agent",
    "specs_path": "$SPECS_PATH",
    "memory_path": "$BMAD_PATH/memory"
  },
  "agents": {
    "analyst": {
      "enabled": true,
      "model": "gpt-4"
    },
    "pm": {
      "enabled": true,
      "model": "gpt-4"
    },
    "architect": {
      "enabled": true,
      "model": "gpt-4"
    },
    "developer": {
      "enabled": true,
      "model": "gpt-4"
    },
    "qa": {
      "enabled": true,
      "model": "gpt-4"
    }
  }
}
EOF

# Update .living-docs.config
if ! grep -q "bmad-method" "$PROJECT_ROOT/.living-docs.config" 2>/dev/null; then
    echo "INSTALLED_SPECS=\"${INSTALLED_SPECS} bmad-method\"" >> "$PROJECT_ROOT/.living-docs.config"
    echo "BMAD_VERSION=\"1.0.0\"" >> "$PROJECT_ROOT/.living-docs.config"
    echo "BMAD_PATH=\"$BMAD_PATH\"" >> "$PROJECT_ROOT/.living-docs.config"
fi

echo "✅ BMAD-Method installed successfully!"
echo ""
echo "Structure created:"
echo "  $BMAD_PATH/            - BMAD configuration"
echo "  $SPECS_PATH/           - Specification templates"

if [ "$SKIP_NODE" != "true" ] && command -v node >/dev/null 2>&1; then
    echo ""
    echo "BMAD Commands available:"
    echo "  $BMAD_PATH/bmad.sh analyst   - Run analyst agent"
    echo "  $BMAD_PATH/bmad.sh pm        - Run PM agent"
    echo "  $BMAD_PATH/bmad.sh developer - Run developer agent"
    echo ""
    echo "To install BMAD packages:"
    echo "  cd $BMAD_PATH && npm run install:bmad"
else
    echo ""
    echo "⚠️  Node.js not available. BMAD templates installed but agents won't run."
    echo "  Install Node.js 20+ to enable multi-agent functionality."
fi