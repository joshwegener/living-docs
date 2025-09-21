#!/usr/bin/env bats
# Security tests for living-docs project

load '../bats/test_helper'

@test "wizard.sh exists and is executable" {
    [[ -f "$LIVING_DOCS_ROOT/wizard.sh" ]]
    [[ -x "$LIVING_DOCS_ROOT/wizard.sh" ]]
}

@test "wizard.sh has safe file permissions" {
    local perms
    perms=$(stat -c "%a" "$LIVING_DOCS_ROOT/wizard.sh" 2>/dev/null || stat -f "%A" "$LIVING_DOCS_ROOT/wizard.sh" 2>/dev/null)

    # Should not be world-writable
    [[ ! "$perms" =~ [0-9][0-9][2-7]$ ]]
}

@test "no hardcoded secrets in shell scripts" {
    # Check for obvious secret patterns
    ! find "$LIVING_DOCS_ROOT" -name "*.sh" -not -path "*/.git/*" \
        -exec grep -l "password=\|secret=\|token=\|key=" {} \; | grep -v test
}

@test "no HTTP URLs in wizard.sh" {
    ! grep -E "http://[^[:space:]]+" "$LIVING_DOCS_ROOT/wizard.sh" || {
        echo "Found HTTP URLs in wizard.sh - should use HTTPS"
        return 1
    }
}

@test "wizard.sh uses proper error handling" {
    grep -q "set -e" "$LIVING_DOCS_ROOT/wizard.sh" || \
    grep -q "trap" "$LIVING_DOCS_ROOT/wizard.sh"
}

@test "no dangerous eval usage in scripts" {
    ! find "$LIVING_DOCS_ROOT" -name "*.sh" -not -path "*/.git/*" \
        -exec grep -l "eval.*\$" {} \; | grep -v test
}

@test "temp files use mktemp" {
    if find "$LIVING_DOCS_ROOT" -name "*.sh" -not -path "*/.git/*" -exec grep -l "/tmp/" {} \; | grep -v test; then
        # If scripts use /tmp, they should use mktemp
        find "$LIVING_DOCS_ROOT" -name "*.sh" -not -path "*/.git/*" -exec grep -l "/tmp/" {} \; | \
            xargs grep -l "mktemp" || {
            echo "Scripts use /tmp without mktemp"
            return 1
        }
    fi
}

@test "no overly permissive file operations" {
    ! find "$LIVING_DOCS_ROOT" -name "*.sh" -not -path "*/.git/*" \
        -exec grep -l "chmod.*777\|chmod.*666" {} \;
}