#!/bin/bash
# Test runner for path security tests
# Usage: ./scripts/test-paths.sh [test-pattern]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure bats is installed
if ! command -v bats >/dev/null 2>&1; then
    echo "Error: bats is not installed. Install with: brew install bats-core"
    exit 1
fi

# Run specific test pattern or all path tests
if [[ $# -gt 0 ]]; then
    echo "Running path security tests matching: $1"
    bats "$PROJECT_ROOT/tests/bats/test_paths.bats" --filter "$1"
else
    echo "Running all path security tests..."
    bats "$PROJECT_ROOT/tests/bats/test_paths.bats"
fi