#!/usr/bin/env bash
set -euo pipefail
# Basic Tests for Debug Logging Library (Retrospective TDD)
# These tests verify core functionality of lib/debug/logger.sh

set -eo pipefail

# Setup
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$PROJECT_ROOT/lib/debug/logger.sh"

echo "=== Debug Logger Basic Tests ==="

# Test 1: Debug disabled by default
unset LIVING_DOCS_DEBUG
output=$(debug_log "test" 2>&1)
if [[ -z "$output" ]]; then
    echo "✓ Test 1: Debug disabled by default"
else
    echo "✗ Test 1 failed: Got output when debug disabled"
    exit 1
fi

# Test 2: Debug can be enabled
export LIVING_DOCS_DEBUG=1
output=$(debug_log "enabled test" 2>&1)
if [[ "$output" == *"enabled test"* ]]; then
    echo "✓ Test 2: Debug can be enabled"
else
    echo "✗ Test 2 failed: No output when debug enabled"
    exit 1
fi

# Test 3: Log levels work
export LIVING_DOCS_DEBUG_LEVEL="ERROR"
error_output=$(debug_error "error msg" 2>&1)
info_output=$(debug_info "info msg" 2>&1)

if [[ "$error_output" == *"ERROR"* ]] && [[ -z "$info_output" ]]; then
    echo "✓ Test 3: Log levels filter correctly"
else
    echo "✗ Test 3 failed: Log level filtering not working"
    exit 1
fi

# Test 4: All log functions exist
functions=(debug_log debug_info debug_warn debug_error debug_trace debug_context debug_vars)
all_exist=true
for func in "${functions[@]}"; do
    if ! declare -f "$func" > /dev/null; then
        echo "✗ Function $func not found"
        all_exist=false
    fi
done

if $all_exist; then
    echo "✓ Test 4: All debug functions exist"
else
    exit 1
fi

# Test 5: File logging works
TEST_LOG="/tmp/test-debug-$$.log"
export LIVING_DOCS_DEBUG_FILE="$TEST_LOG"
export LIVING_DOCS_DEBUG=1
# Re-source to pick up file setting
source "$PROJECT_ROOT/lib/debug/logger.sh"
debug_log "file test"

if [[ -f "$TEST_LOG" ]] && grep -q "file test" "$TEST_LOG"; then
    echo "✓ Test 5: File logging works"
    rm -f "$TEST_LOG"
else
    echo "✗ Test 5 failed: File logging not working"
    rm -f "$TEST_LOG"
    exit 1
fi

echo ""
echo "=== All basic tests passed ==="
echo "Note: These are retrospective tests to satisfy TDD compliance."
echo "Future implementations should write tests FIRST."