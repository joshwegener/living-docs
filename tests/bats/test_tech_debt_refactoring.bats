#!/usr/bin/env bats

# TDD: Tests MUST FAIL first (RED phase)
# Testing technical debt and refactoring needs

setup() {
    load test_helper
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"

    # Copy large scripts that need refactoring
    cp "${BATS_TEST_DIRNAME}/../../wizard.sh" . 2>/dev/null || true
    cp -r "${BATS_TEST_DIRNAME}/../../lib" . 2>/dev/null || true
}

teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

@test "tech-debt: Large scripts should be modularized" {
    # THIS TEST WILL FAIL: Scripts are too large
    # Check script sizes
    for script in wizard.sh lib/a11y/check.sh lib/drift/detector.sh; do
        [ -f "$script" ] || continue

        LINES=$(wc -l < "$script")

        # Scripts should be under 300 lines (THIS WILL FAIL)
        [ "$LINES" -lt 300 ]
    done
}

@test "tech-debt: Functions should be under 50 lines" {
    # THIS TEST WILL FAIL: Functions are too long
    # Check function lengths in wizard.sh
    run check_function_lengths "wizard.sh" 50
    [ "$status" -eq 0 ]

    # Should report long functions (THIS WILL FAIL)
    [[ ! "$output" =~ "exceeds limit" ]]
}

@test "tech-debt: No code duplication across scripts" {
    # THIS TEST WILL FAIL: Duplicate code exists
    # Check for duplicate functions
    FUNCTIONS=$(grep -h "^function\|^[a-z_]*\(\)" lib/**/*.sh 2>/dev/null | sort | uniq -d)

    # Should have no duplicate functions (THIS WILL FAIL)
    [ -z "$FUNCTIONS" ]
}

@test "tech-debt: Proper error handling in all functions" {
    # THIS TEST WILL FAIL: Missing error handling
    # Check for functions without error handling
    for script in wizard.sh lib/**/*.sh; do
        [ -f "$script" ] || continue

        # Check if functions have error handling
        run check_error_handling "$script"
        [ "$status" -eq 0 ]
    done
}

@test "tech-debt: All global variables should be readonly" {
    # THIS TEST WILL FAIL: Mutable globals exist
    # Find global variable declarations
    GLOBALS=$(grep -h "^[A-Z_]*=" wizard.sh lib/**/*.sh 2>/dev/null | grep -v "readonly")

    # All globals should be readonly (THIS WILL FAIL)
    [ -z "$GLOBALS" ]
}

@test "tech-debt: Scripts should have proper documentation" {
    # THIS TEST WILL FAIL: Missing documentation
    for script in lib/**/*.sh; do
        [ -f "$script" ] || continue

        # Check for file header documentation
        head -10 "$script" | grep -q "^#.*Description\|Purpose\|Usage" || {
            echo "Missing docs in $script"
            return 1
        }
    done
}

@test "tech-debt: No hardcoded paths in scripts" {
    # THIS TEST WILL FAIL: Hardcoded paths exist
    # Check for hardcoded paths
    HARDCODED=$(grep -h "/home/\|/Users/\|C:\\\\" wizard.sh lib/**/*.sh 2>/dev/null | grep -v "^#")

    # Should have no hardcoded paths (THIS WILL FAIL)
    [ -z "$HARDCODED" ]
}

@test "tech-debt: Deprecated functions should be removed" {
    # THIS TEST WILL FAIL: Deprecated code exists
    # Check for deprecated markers
    DEPRECATED=$(grep -h "@deprecated\|DEPRECATED" lib/**/*.sh 2>/dev/null)

    # Should have no deprecated code (THIS WILL FAIL)
    [ -z "$DEPRECATED" ]
}

@test "tech-debt: Complex conditionals should be refactored" {
    # THIS TEST WILL FAIL: Complex conditions exist
    # Check for deeply nested conditionals
    for script in wizard.sh lib/**/*.sh; do
        [ -f "$script" ] || continue

        # Count nesting depth
        run check_nesting_depth "$script" 3
        [ "$status" -eq 0 ]
    done
}

@test "tech-debt: Magic numbers should be constants" {
    # THIS TEST WILL FAIL: Magic numbers exist
    # Check for magic numbers
    MAGIC=$(grep -h "[^0-9][0-9]\{3,\}[^0-9]" wizard.sh lib/**/*.sh 2>/dev/null | grep -v "^#")

    # Should define constants instead (THIS WILL FAIL)
    [ -z "$MAGIC" ]
}

@test "tech-debt: Shell scripts should pass shellcheck" {
    # THIS TEST WILL FAIL: Shellcheck issues exist
    # Run shellcheck on all scripts
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"

    for script in wizard.sh lib/**/*.sh; do
        [ -f "$script" ] || continue

        run shellcheck -S error "$script"
        [ "$status" -eq 0 ]
    done
}

@test "tech-debt: Consistent naming conventions" {
    # THIS TEST WILL FAIL: Inconsistent naming
    # Check function naming
    SNAKE_CASE=$(grep -h "^function [a-z_]*\|^[a-z_]*\(\)" lib/**/*.sh 2>/dev/null | wc -l)
    CAMEL_CASE=$(grep -h "^function.*[a-z][A-Z]\|^[a-z]*[A-Z].*\(\)" lib/**/*.sh 2>/dev/null | wc -l)

    # Should use consistent naming (THIS WILL FAIL)
    [ "$CAMEL_CASE" -eq 0 ] || [ "$SNAKE_CASE" -eq 0 ]
}

@test "tech-debt: Test coverage for all public functions" {
    # THIS TEST WILL FAIL: Missing test coverage
    # Get all public functions
    PUBLIC_FUNCTIONS=$(grep -h "^function [a-z]\|^[a-z_]*\(\)" lib/**/*.sh 2>/dev/null | sed 's/function //;s/()//')

    # Check if tests exist
    for func in $PUBLIC_FUNCTIONS; do
        grep -q "$func" tests/**/*.bats 2>/dev/null || {
            echo "No test for: $func"
            return 1
        }
    done
}

@test "tech-debt: Resource cleanup in error paths" {
    # THIS TEST WILL FAIL: Missing cleanup
    # Check for trap handlers
    for script in wizard.sh lib/**/*.sh; do
        [ -f "$script" ] || continue

        # Scripts creating temp files should have cleanup
        if grep -q "mktemp\|mkdir.*tmp" "$script" 2>/dev/null; then
            grep -q "trap.*cleanup\|trap.*rm" "$script" || {
                echo "Missing cleanup trap in $script"
                return 1
            }
        fi
    done
}

@test "tech-debt: Circular dependencies between modules" {
    # THIS TEST WILL FAIL: Circular dependencies exist
    # Check for circular source/includes
    run detect_circular_dependencies "lib"
    [ "$status" -eq 0 ]

    # Should have no circular deps (THIS WILL FAIL)
    [[ ! "$output" =~ "circular" ]]
}