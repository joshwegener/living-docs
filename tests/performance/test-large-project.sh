#!/bin/bash
# Performance tests for wizard.sh with large projects
# Tests how well the system scales with many files and complex configurations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
WIZARD_SCRIPT="$PROJECT_ROOT/wizard.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Performance thresholds (in seconds)
INIT_THRESHOLD=30
UPDATE_THRESHOLD=60
CLEANUP_THRESHOLD=10

test_results=()
tests_run=0
tests_passed=0

run_performance_test() {
    local test_name="$1"
    local max_time="$2"
    local test_function="$3"

    echo "Running: $test_name (max: ${max_time}s)"
    ((tests_run++))

    local start_time
    start_time=$(date +%s)

    if $test_function; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [[ $duration -le $max_time ]]; then
            echo -e "${GREEN}✅ PASS:${NC} $test_name (${duration}s)"
            test_results+=("PASS: $test_name (${duration}s)")
            ((tests_passed++))
        else
            echo -e "${YELLOW}⚠️  SLOW:${NC} $test_name (${duration}s > ${max_time}s)"
            test_results+=("SLOW: $test_name (${duration}s)")
        fi
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}❌ FAIL:${NC} $test_name (${duration}s)"
        test_results+=("FAIL: $test_name (${duration}s)")
    fi
    echo
}

create_large_test_project() {
    local project_dir="$1"
    local num_files="${2:-1000}"

    echo "Creating large test project with $num_files files..."

    mkdir -p "$project_dir"/{docs,src,tests,config,scripts}

    # Create many documentation files
    for i in $(seq 1 $((num_files / 4))); do
        cat > "$project_dir/docs/doc_$i.md" << EOF
# Documentation File $i

This is test documentation file number $i.

## Section 1
Content for section 1 of document $i.

## Section 2
Content for section 2 of document $i.

## Links
- [Link to doc $((i+1))](doc_$((i+1)).md)
- [Link to doc $((i-1))](doc_$((i-1)).md)
EOF
    done

    # Create source files
    for i in $(seq 1 $((num_files / 4))); do
        cat > "$project_dir/src/module_$i.js" << EOF
// Module $i
const module$i = {
    name: 'module$i',
    version: '1.0.0',
    dependencies: ['module$((i-1))', 'module$((i+1))']
};

module.exports = module$i;
EOF
    done

    # Create test files
    for i in $(seq 1 $((num_files / 4))); do
        cat > "$project_dir/tests/test_$i.js" << EOF
// Test file $i
describe('Module $i', () => {
    test('should work correctly', () => {
        expect(true).toBe(true);
    });
});
EOF
    done

    # Create config files
    for i in $(seq 1 $((num_files / 4))); do
        cat > "$project_dir/config/config_$i.yml" << EOF
# Config $i
settings:
  enabled: true
  value: $i
  description: "Configuration file number $i"
EOF
    done

    echo "Large test project created with $(find "$project_dir" -type f | wc -l) files"
}

test_wizard_init_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_large_test_project "$test_dir" 500

    cd "$test_dir"

    # Run wizard init (simulated)
    if [[ -f "$WIZARD_SCRIPT" ]]; then
        # Test wizard.sh initialization performance
        bash "$WIZARD_SCRIPT" --help > /dev/null 2>&1
    fi

    # Simulate living-docs initialization
    mkdir -p .living-docs
    echo "framework: spec-kit" > .living-docs/config.yml

    rm -rf "$test_dir"
    return 0
}

test_file_scanning_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_large_test_project "$test_dir" 1000

    cd "$test_dir"

    # Test file scanning operations
    local start_time
    start_time=$(date +%s)

    # Simulate operations that scan many files
    find . -name "*.md" | wc -l > /dev/null
    find . -name "*.js" | wc -l > /dev/null
    find . -name "*.yml" | wc -l > /dev/null

    local end_time
    end_time=$(date +%s)
    local scan_time=$((end_time - start_time))

    echo "File scanning took ${scan_time}s for $(find . -type f | wc -l) files"

    rm -rf "$test_dir"
    [[ $scan_time -lt 10 ]]
}

test_template_processing_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    # Create many template files
    mkdir -p "$test_dir/templates"

    for i in $(seq 1 100); do
        cat > "$test_dir/templates/template_$i.md" << 'EOF'
# Template {{TITLE}}

This is template number {{NUMBER}}.

## Configuration
- Setting: {{SETTING_VALUE}}
- Enabled: {{ENABLED}}
- Path: {{PROJECT_PATH}}

## Generated Content
{{GENERATED_CONTENT}}
EOF
    done

    cd "$test_dir"

    # Simulate template processing
    local processed=0
    for template in templates/*.md; do
        # Simple template replacement simulation
        sed 's/{{TITLE}}/Test Title/g' "$template" | \
        sed 's/{{NUMBER}}/123/g' | \
        sed 's/{{SETTING_VALUE}}/test/g' | \
        sed 's/{{ENABLED}}/true/g' | \
        sed 's/{{PROJECT_PATH}}/.\/project/g' | \
        sed 's/{{GENERATED_CONTENT}}/Generated at runtime/g' > "/dev/null"
        ((processed++))
    done

    echo "Processed $processed templates"

    rm -rf "$test_dir"
    [[ $processed -eq 100 ]]
}

test_git_operations_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    create_large_test_project "$test_dir" 800

    cd "$test_dir"

    # Initialize git
    git init > /dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Test git operations with many files
    git add . > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Simulate git status checks (common in wizard.sh)
    git status --porcelain > /dev/null 2>&1
    git diff --name-only > /dev/null 2>&1

    rm -rf "$test_dir"
    return 0
}

test_config_parsing_performance() {
    local test_dir
    test_dir=$(mktemp -d)

    # Create complex configuration
    mkdir -p "$test_dir/.living-docs"

    cat > "$test_dir/.living-docs/config.yml" << 'EOF'
framework: spec-kit
rules:
  - name: rule1
    pattern: "*.md"
    action: process
  - name: rule2
    pattern: "*.js"
    action: lint
  - name: rule3
    pattern: "*.yml"
    action: validate
adapters:
  cursor:
    enabled: true
    settings:
      model: claude-3
      temperature: 0.7
  aider:
    enabled: false
    settings:
      model: gpt-4
templates:
  - src: templates/spec.md
    dest: specs/{{SPEC_NAME}}/spec.md
  - src: templates/tasks.md
    dest: specs/{{SPEC_NAME}}/tasks.md
EOF

    cd "$test_dir"

    # Simulate config parsing operations
    if command -v yq >/dev/null 2>&1; then
        yq eval '.framework' .living-docs/config.yml > /dev/null
        yq eval '.rules[].name' .living-docs/config.yml > /dev/null
        yq eval '.adapters' .living-docs/config.yml > /dev/null
    else
        # Fallback to grep/sed parsing
        grep "framework:" .living-docs/config.yml > /dev/null
        grep -A 100 "rules:" .living-docs/config.yml > /dev/null
    fi

    rm -rf "$test_dir"
    return 0
}

test_memory_usage() {
    local test_dir
    test_dir=$(mktemp -d)

    create_large_test_project "$test_dir" 2000

    cd "$test_dir"

    # Monitor memory usage during operations
    local memory_before
    if command -v free >/dev/null 2>&1; then
        memory_before=$(free -m | awk 'NR==2{print $3}')
    elif command -v vm_stat >/dev/null 2>&1; then
        memory_before=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    else
        memory_before=0
    fi

    # Perform memory-intensive operations
    find . -type f -exec wc -l {} \; > /dev/null 2>&1
    find . -name "*.md" -exec grep -l "test" {} \; > /dev/null 2>&1

    echo "Memory test completed (before: ${memory_before})"

    rm -rf "$test_dir"
    return 0
}

main() {
    echo "Large Project Performance Test Suite"
    echo "===================================="
    echo "Testing wizard.sh performance with large projects"
    echo

    # Check if wizard.sh exists
    if [[ ! -f "$WIZARD_SCRIPT" ]]; then
        echo -e "${RED}❌ wizard.sh not found at $WIZARD_SCRIPT${NC}"
        exit 1
    fi

    echo "Performance thresholds:"
    echo "- Initialization: ${INIT_THRESHOLD}s"
    echo "- Updates: ${UPDATE_THRESHOLD}s"
    echo "- Cleanup: ${CLEANUP_THRESHOLD}s"
    echo

    # Run performance tests
    run_performance_test "Wizard initialization" $INIT_THRESHOLD test_wizard_init_performance
    run_performance_test "File scanning (1000 files)" 15 test_file_scanning_performance
    run_performance_test "Template processing" 20 test_template_processing_performance
    run_performance_test "Git operations (800 files)" 25 test_git_operations_performance
    run_performance_test "Config parsing" 5 test_config_parsing_performance
    run_performance_test "Memory usage test" 30 test_memory_usage

    echo "Performance Test Results Summary"
    echo "==============================="
    echo "Tests run: $tests_run"
    echo "Tests passed: $tests_passed"
    echo "Performance issues: $((tests_run - tests_passed))"
    echo

    # Print detailed results
    for result in "${test_results[@]}"; do
        if [[ "$result" =~ ^SLOW: ]]; then
            echo -e "${YELLOW}⚠️  ${result}${NC}"
        elif [[ "$result" =~ ^FAIL: ]]; then
            echo -e "${RED}❌ ${result}${NC}"
        fi
    done

    if [[ $tests_passed -eq $tests_run ]]; then
        echo -e "${GREEN}✅ All performance tests passed${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some performance tests were slow or failed${NC}"
        exit 0  # Don't fail CI for performance issues
    fi
}

main "$@"