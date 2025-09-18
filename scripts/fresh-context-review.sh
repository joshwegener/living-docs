#!/bin/bash
# Fresh Context Review - Generic AI compliance review script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==================================="
echo "   FRESH CONTEXT COMPLIANCE REVIEW"
echo "==================================="
echo ""

# Get the base branch (usually main or master)
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$BASE_BRANCH" ]; then
    # Fallback: try to find main or master
    if git rev-parse --verify main >/dev/null 2>&1; then
        BASE_BRANCH="main"
    elif git rev-parse --verify master >/dev/null 2>&1; then
        BASE_BRANCH="master"
    else
        BASE_BRANCH="HEAD~1"  # Fallback to parent commit
    fi
fi

CURRENT_BRANCH=$(git branch --show-current)

echo "Reviewing changes: $CURRENT_BRANCH vs $BASE_BRANCH"
echo ""

# Get all changes on current branch compared to base
DIFF=$(git diff $BASE_BRANCH...HEAD 2>/dev/null || git diff $BASE_BRANCH..HEAD 2>/dev/null)

# If no diff from base, check for uncommitted changes
if [ -z "$DIFF" ]; then
    echo "No branch changes found, checking working directory..."
    DIFF=$(git diff HEAD)
    if [ -z "$DIFF" ]; then
        DIFF=$(git diff --staged)
    fi
fi

if [ -z "$DIFF" ]; then
    echo -e "${GREEN}✓ No changes to review${NC}"
    exit 0
fi

echo "Gathering changes..."

# Source compliance functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/compliance/compliance-review.sh" ]; then
    source "$SCRIPT_DIR/compliance/compliance-review.sh"
else
    echo -e "${RED}ERROR: compliance-review.sh not found${NC}"
    exit 1
fi

# Run compliance check
echo "Running compliance checks..."
echo ""

RESULT=$(review_compliance "$DIFF")

# Parse result
if echo "$RESULT" | grep -q '"result".*"PASS"'; then
    echo -e "${GREEN}✓ COMPLIANCE CHECK PASSED${NC}"
    echo ""
    echo "All gates satisfied:"
    echo "  ✓ TDD compliance"
    echo "  ✓ Documentation current"
    echo "  ✓ Phase ordering maintained"
    exit 0
else
    echo -e "${RED}✗ COMPLIANCE CHECK FAILED${NC}"
    echo ""
    echo "Violations found:"

    # Extract violations (basic parsing)
    if echo "$RESULT" | grep -q "TDD_TESTS_FIRST"; then
        echo -e "  ${RED}✗${NC} TDD_TESTS_FIRST: Implementation without tests"
        echo "    Fix: Write failing tests first"
    fi

    if echo "$RESULT" | grep -q "UPDATE_TASKS_MD"; then
        echo -e "  ${YELLOW}⚠${NC} UPDATE_TASKS_MD: tasks.md not updated"
        echo "    Fix: Mark completed tasks with [x]"
    fi

    echo ""
    echo "To proceed:"
    echo "  1. Fix the violations listed above"
    echo "  2. Run this script again"
    echo "  3. Commit only after compliance passes"

    exit 1
fi