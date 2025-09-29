#!/bin/bash
set -euo pipefail
# Test: Configuration file validation
# MUST FAIL before implementation (TDD)

set -e

echo "Testing .living-docs.config..."

# Test 1: Config file exists
if [ ! -f ".living-docs.config" ]; then
    echo "❌ FAIL: .living-docs.config does not exist"
    exit 1
fi
echo "✓ Config file exists"

# Test 2: Required fields present
source .living-docs.config 2>/dev/null || {
    echo "❌ FAIL: Cannot source config file"
    exit 1
}

if [ -z "$docs_path" ]; then
    echo "❌ FAIL: docs_path not defined"
    exit 1
fi
echo "✓ docs_path defined: $docs_path"

if [ -z "$version" ]; then
    echo "❌ FAIL: version not defined"
    exit 1
fi
echo "✓ version defined: $version"

if [ -z "$created" ]; then
    echo "❌ FAIL: created date not defined"
    exit 1
fi
echo "✓ created date defined: $created"

# Test 3: Version format
if ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "❌ FAIL: version format invalid (expected X.Y.Z)"
    exit 1
fi
echo "✓ version format valid"

# Test 4: Date format
if ! echo "$created" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    echo "❌ FAIL: date format invalid (expected YYYY-MM-DD)"
    exit 1
fi
echo "✓ date format valid"

# Test 5: Installed specs tracked
if [ -n "$INSTALLED_SPECS" ]; then
    echo "✓ Installed specs tracked: $INSTALLED_SPECS"
    for spec in $INSTALLED_SPECS; do
        # Convert to uppercase and replace - with _ for Bash 3.2
        var_name=$(echo "$spec" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
        var_name="${var_name}_VERSION"
        eval "version_val=\$$var_name"
        if [ -z "$version_val" ]; then
            echo "❌ FAIL: Version not defined for $spec"
            exit 1
        fi
        echo "  ✓ $spec version: $version_val"
    done
fi

echo "✅ All configuration tests passed!"