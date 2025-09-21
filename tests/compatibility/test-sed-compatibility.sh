#!/bin/bash
# Test sed compatibility between macOS and Linux
# Critical for wizard.sh which uses sed extensively

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

tests_run=0
tests_passed=0

run_test() {
    local test_name="$1"
    local test_function="$2"

    echo "Testing: $test_name"
    ((tests_run++))

    if $test_function; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((tests_passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
    echo
}

test_sed_in_place_flag() {
    local temp_file
    temp_file=$(mktemp)
    echo "test content" > "$temp_file"

    # Test the sed -i syntax used in wizard.sh
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS requires empty string after -i
        sed -i '' 's/test/modified/' "$temp_file"
    else
        # Linux uses -i directly
        sed -i 's/test/modified/' "$temp_file"
    fi

    local result
    result=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ "$result" == "modified content" ]]
}

test_sed_extended_regex() {
    local input="test123abc"
    local result

    # Test extended regex support
    if command -v gsed >/dev/null 2>&1; then
        # Use GNU sed if available (macOS with homebrew)
        result=$(echo "$input" | gsed -E 's/([0-9]+)/[\1]/')
    else
        # Try with regular sed
        result=$(echo "$input" | sed -E 's/([0-9]+)/[\1]/' 2>/dev/null || echo "$input" | sed 's/\([0-9]\+\)/[\1]/')
    fi

    [[ "$result" == "test[123]abc" ]]
}

test_wizard_sed_patterns() {
    # Test actual sed patterns from wizard.sh
    local temp_file
    temp_file=$(mktemp)

    cat > "$temp_file" << 'EOF'
PLACEHOLDER_VALUE=placeholder
CONFIG_SETTING=old_value
# Comment line
ANOTHER_SETTING=test
EOF

    # Simulate wizard.sh sed operations
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's/PLACEHOLDER_VALUE=.*/PLACEHOLDER_VALUE=new_value/' "$temp_file"
        sed -i '' '/^#/d' "$temp_file"
    else
        sed -i 's/PLACEHOLDER_VALUE=.*/PLACEHOLDER_VALUE=new_value/' "$temp_file"
        sed -i '/^#/d' "$temp_file"
    fi

    local result
    result=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ "$result" == *"PLACEHOLDER_VALUE=new_value"* ]] && [[ "$result" != *"# Comment"* ]]
}

test_sed_multiline_handling() {
    local temp_file
    temp_file=$(mktemp)

    cat > "$temp_file" << 'EOF'
line1
line2
line3
EOF

    # Test multiline operations
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '2d' "$temp_file"  # Delete second line
    else
        sed -i '2d' "$temp_file"
    fi

    local result
    result=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ "$result" == "line1"$'\n'"line3" ]]
}

test_sed_special_characters() {
    local temp_file
    temp_file=$(mktemp)
    echo "path/to/file.txt" > "$temp_file"

    # Test escaping special characters
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' 's|/|_|g' "$temp_file"
    else
        sed -i 's|/|_|g' "$temp_file"
    fi

    local result
    result=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ "$result" == "path_to_file.txt" ]]
}

test_address_range_operations() {
    local temp_file
    temp_file=$(mktemp)

    cat > "$temp_file" << 'EOF'
start
middle1
middle2
end
EOF

    # Test range operations
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' '2,3s/middle/MIDDLE/' "$temp_file"
    else
        sed -i '2,3s/middle/MIDDLE/' "$temp_file"
    fi

    local result
    result=$(cat "$temp_file")
    rm -f "$temp_file"

    [[ "$result" == *"MIDDLE1"* ]] && [[ "$result" == *"MIDDLE2"* ]]
}

check_sed_version() {
    echo "Checking sed version and availability..."
    echo "OS: $(uname)"

    if command -v sed >/dev/null 2>&1; then
        echo "sed found: $(which sed)"
        sed --version 2>/dev/null || echo "sed version not available (BSD sed?)"
    else
        echo "sed not found!"
        return 1
    fi

    if command -v gsed >/dev/null 2>&1; then
        echo "GNU sed found: $(which gsed)"
        gsed --version 2>/dev/null || true
    fi

    echo
}

detect_platform_requirements() {
    echo "Platform-specific requirements:"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "- macOS detected"
        echo "- sed -i requires empty string: sed -i '' ..."
        echo "- Consider installing GNU sed: brew install gnu-sed"
    else
        echo "- Linux detected"
        echo "- sed -i works directly: sed -i ..."
        echo "- GNU sed typically available by default"
    fi
    echo
}

main() {
    echo "Sed Compatibility Test Suite"
    echo "============================"
    echo

    check_sed_version
    detect_platform_requirements

    # Run compatibility tests
    run_test "sed -i flag compatibility" test_sed_in_place_flag
    run_test "Extended regex support" test_sed_extended_regex
    run_test "Wizard.sh sed patterns" test_wizard_sed_patterns
    run_test "Multiline handling" test_sed_multiline_handling
    run_test "Special character handling" test_sed_special_characters
    run_test "Address range operations" test_address_range_operations

    echo "Test Results Summary"
    echo "==================="
    echo "Tests run: $tests_run"
    echo "Tests passed: $tests_passed"
    echo "Tests failed: $((tests_run - tests_passed))"

    if [[ $tests_passed -eq $tests_run ]]; then
        echo -e "${GREEN}✅ All sed compatibility tests passed${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some sed compatibility tests failed${NC}"
        echo
        echo "This may indicate platform compatibility issues in wizard.sh"
        exit 1
    fi
}

main "$@"