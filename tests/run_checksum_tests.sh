#!/usr/bin/env bash
# Quick test runner for checksum tests

BATS_PATH="/opt/homebrew/Cellar/bats-core/1.12.0/bin/bats"
TEST_FILE="/Users/joshwegener/Projects/living-docs/tests/bats/test_checksum.bats"

if [[ ! -x "$BATS_PATH" ]]; then
    echo "Error: bats not found at $BATS_PATH"
    echo "Install with: brew install bats-core"
    exit 1
fi

echo "Running checksum tests..."
echo "========================"
"$BATS_PATH" "$TEST_FILE"