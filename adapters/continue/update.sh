#!/bin/bash

# continue Adapter Update Script

set -e

PROJECT_ROOT="${1:-.}"
ADAPTER_DIR="$(dirname "$0")"

# Source common update functions
source "$ADAPTER_DIR/../common/update.sh"

# Update this adapter
update_adapter "continue" "$PROJECT_ROOT"