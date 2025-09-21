#!/usr/bin/env bash
# Setup script for kcov coverage reporting
# This script is used in CI/CD and local development

set -euo pipefail

# Configuration
KCOV_VERSION="42"
COVERAGE_DIR="${COVERAGE_DIR:-coverage}"
MIN_COVERAGE="${MIN_COVERAGE:-80}"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unsupported"
    fi
}

# Install kcov based on OS
install_kcov() {
    local os
    os=$(detect_os)

    echo "Installing kcov for $os..."

    case "$os" in
        linux)
            # For GitHub Actions Ubuntu runners
            if command -v apt-get &>/dev/null; then
                sudo apt-get update
                sudo apt-get install -y \
                    cmake \
                    binutils-dev \
                    libcurl4-openssl-dev \
                    zlib1g-dev \
                    libdw-dev \
                    libiberty-dev

                # Build kcov from source
                git clone https://github.com/SimonKagstrom/kcov.git /tmp/kcov
                cd /tmp/kcov
                mkdir build
                cd build
                cmake ..
                make
                sudo make install
            fi
            ;;
        macos)
            # For macOS (local development)
            if command -v brew &>/dev/null; then
                brew install kcov || brew upgrade kcov
            else
                echo "Homebrew not found. Please install: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS: $OSTYPE"
            echo "Please install kcov manually: https://github.com/SimonKagstrom/kcov"
            exit 1
            ;;
    esac
}

# Check if kcov is installed
check_kcov() {
    if ! command -v kcov &>/dev/null; then
        echo "kcov not found. Installing..."
        install_kcov
    else
        echo "kcov is already installed: $(kcov --version)"
    fi
}

# Create coverage directory structure
setup_coverage_dir() {
    echo "Setting up coverage directory: $COVERAGE_DIR"

    # Create main coverage directory
    mkdir -p "$COVERAGE_DIR"

    # Create subdirectories for different test types
    mkdir -p "$COVERAGE_DIR"/{bats,integration,unit,merged}

    # Create .gitignore for coverage directory
    cat > "$COVERAGE_DIR/.gitignore" << 'EOF'
# kcov coverage output
*.json
*.xml
*.html
index.html
*.css
*.js
*.png
*.gif
cobertura.xml
coverage.json

# Keep directory structure
!.gitignore
!*/
EOF

    echo "Coverage directory structure created"
}

# Create coverage configuration
create_coverage_config() {
    echo "Creating coverage configuration..."

    cat > ".kcov.yml" << EOF
# kcov configuration for living-docs

# Minimum coverage threshold
min_coverage: $MIN_COVERAGE

# Include patterns
include_patterns:
  - "wizard.sh"
  - "lib/**/*.sh"
  - "scripts/**/*.sh"
  - "adapters/**/*.sh"

# Exclude patterns
exclude_patterns:
  - "tests/**"
  - ".living-docs.backup/**"
  - "coverage/**"
  - "*.md"
  - "*.txt"
  - "*.yml"
  - "*.yaml"
  - "*.json"

# Coverage output formats
output_formats:
  - html
  - cobertura
  - json

# Coverage merge settings
merge:
  enabled: true
  output: "$COVERAGE_DIR/merged"
EOF

    echo "Coverage configuration created: .kcov.yml"
}

# Create coverage runner script
create_coverage_runner() {
    echo "Creating coverage runner..."

    cat > "tests/run-coverage.sh" << 'EOF'
#!/usr/bin/env bash
# Run tests with coverage reporting

set -euo pipefail

# Configuration
COVERAGE_DIR="${COVERAGE_DIR:-coverage}"
KCOV_OPTS="--exclude-pattern=/usr --exclude-pattern=/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_msg() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

# Run Bats tests with coverage
run_bats_coverage() {
    print_msg "$YELLOW" "Running Bats tests with coverage..."

    if [[ -d "tests/bats" ]]; then
        for test_file in tests/bats/*.bats; do
            if [[ -f "$test_file" ]]; then
                local test_name
                test_name=$(basename "$test_file" .bats)

                print_msg "$GREEN" "  Running: $test_name"

                kcov $KCOV_OPTS \
                    "$COVERAGE_DIR/bats/$test_name" \
                    bats "$test_file" || true
            fi
        done
    fi
}

# Run integration tests with coverage
run_integration_coverage() {
    print_msg "$YELLOW" "Running integration tests with coverage..."

    if [[ -d "tests/integration" ]]; then
        for test_file in tests/integration/*.sh; do
            if [[ -f "$test_file" && -x "$test_file" ]]; then
                local test_name
                test_name=$(basename "$test_file" .sh)

                print_msg "$GREEN" "  Running: $test_name"

                kcov $KCOV_OPTS \
                    "$COVERAGE_DIR/integration/$test_name" \
                    "$test_file" || true
            fi
        done
    fi
}

# Merge coverage reports
merge_coverage() {
    print_msg "$YELLOW" "Merging coverage reports..."

    local merge_args=""

    # Add each coverage directory to merge
    for dir in "$COVERAGE_DIR"/{bats,integration,unit}/*/; do
        if [[ -d "$dir" ]]; then
            merge_args="$merge_args $dir"
        fi
    done

    if [[ -n "$merge_args" ]]; then
        kcov --merge "$COVERAGE_DIR/merged" $merge_args
        print_msg "$GREEN" "Coverage merged to: $COVERAGE_DIR/merged"
    else
        print_msg "$RED" "No coverage data to merge"
    fi
}

# Generate coverage report
generate_report() {
    print_msg "$YELLOW" "Generating coverage report..."

    local coverage_file="$COVERAGE_DIR/merged/coverage.json"

    if [[ -f "$coverage_file" ]]; then
        # Extract coverage percentage from JSON
        local coverage
        coverage=$(python3 -c "import json; print(json.load(open('$coverage_file'))['percent_covered'])" 2>/dev/null || echo "0")

        print_msg "$GREEN" "Overall coverage: ${coverage}%"

        # Check against minimum threshold
        local min_coverage="${MIN_COVERAGE:-80}"
        if (( $(echo "$coverage < $min_coverage" | bc -l) )); then
            print_msg "$RED" "Coverage ${coverage}% is below minimum threshold of ${min_coverage}%"
            exit 1
        fi
    else
        print_msg "$RED" "Coverage file not found: $coverage_file"
    fi

    # Print HTML report location
    if [[ -f "$COVERAGE_DIR/merged/index.html" ]]; then
        print_msg "$GREEN" "HTML report: file://$PWD/$COVERAGE_DIR/merged/index.html"
    fi
}

# Main execution
main() {
    print_msg "$GREEN" "=== Coverage Test Runner ==="

    # Clean previous coverage
    rm -rf "$COVERAGE_DIR"
    mkdir -p "$COVERAGE_DIR"

    # Run tests with coverage
    run_bats_coverage
    run_integration_coverage

    # Merge and report
    merge_coverage
    generate_report

    print_msg "$GREEN" "=== Coverage complete ==="
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF

    chmod +x tests/run-coverage.sh
    echo "Coverage runner created: tests/run-coverage.sh"
}

# Main execution
main() {
    echo "=== Setting up kcov coverage reporting ==="

    # Check and install kcov if needed
    check_kcov

    # Setup coverage directory
    setup_coverage_dir

    # Create configuration
    create_coverage_config

    # Create runner script
    create_coverage_runner

    echo ""
    echo "=== Coverage setup complete ==="
    echo "To run tests with coverage: ./tests/run-coverage.sh"
    echo "Minimum coverage threshold: ${MIN_COVERAGE}%"
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi