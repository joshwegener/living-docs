#!/bin/bash
# Security checker for shell scripts in living-docs project
# Tests for common security issues and best practices

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
issues_found=0
warnings_found=0
files_checked=0

log_error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    ((issues_found++))
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1" >&2
    ((warnings_found++))
}

log_info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

check_file_permissions() {
    local file="$1"
    local perms
    perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null || echo "unknown")

    if [[ "$perms" == "777" ]]; then
        log_error "File $file has overly permissive permissions (777)"
    elif [[ "$perms" =~ ^.*[0-9][0-9][2-9]$ ]]; then
        log_warning "File $file is world-writable ($perms)"
    fi
}

check_script_content() {
    local file="$1"
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Check for dangerous commands
        if [[ "$line" =~ eval.*\$ ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            log_error "$file:$line_num: Dangerous use of eval with variable expansion"
        fi

        if [[ "$line" =~ \$\(.*\$.*\) ]] && [[ "$line" =~ (curl|wget|bash|sh) ]]; then
            log_warning "$file:$line_num: Potential command injection via command substitution"
        fi

        # Check for unquoted variables in dangerous contexts
        if [[ "$line" =~ (rm|mv|cp|chmod|chown)[[:space:]]+.*\$[A-Za-z_] ]] && [[ ! "$line" =~ \"\$ ]]; then
            log_warning "$file:$line_num: Unquoted variable in file operation command"
        fi

        # Check for hardcoded credentials patterns
        if [[ "$line" =~ (password|passwd|secret|key|token)[[:space:]]*=[[:space:]]*[\"\']*[^[:space:]\"\'][^[:space:]\"\']+[\"\']*$ ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            log_error "$file:$line_num: Potential hardcoded credential"
        fi

        # Check for insecure temp file usage
        if [[ "$line" =~ /tmp/[^/\$] ]] && [[ ! "$line" =~ mktemp ]]; then
            log_warning "$file:$line_num: Hardcoded temp file path (use mktemp instead)"
        fi

        # Check for wget/curl without proper error handling
        if [[ "$line" =~ (wget|curl) ]] && [[ ! "$line" =~ (-f|--fail) ]] && [[ ! "$line" =~ \|\| ]]; then
            log_info "$file:$line_num: Consider adding error handling for network requests"
        fi

        # Check for missing set -euo pipefail or equivalent
        if [[ "$line_num" -eq 1 ]] && [[ "$line" =~ ^#!/bin/bash ]]; then
            if ! head -10 "$file" | grep -q "set -.*e"; then
                log_warning "$file: Script doesn't use 'set -e' for error handling"
            fi
        fi

    done < "$file"
}

check_shebang() {
    local file="$1"
    local shebang
    shebang=$(head -1 "$file")

    if [[ ! "$shebang" =~ ^#!/ ]]; then
        log_warning "$file: Missing or invalid shebang line"
    elif [[ "$shebang" =~ ^#!/bin/sh$ ]]; then
        log_info "$file: Uses /bin/sh (consider /bin/bash for better features)"
    elif [[ "$shebang" =~ ^#!/usr/bin/env[[:space:]]+bash$ ]]; then
        log_info "$file: Uses portable shebang (good practice)"
    fi
}

check_function_security() {
    local file="$1"

    # Check for functions that might be security-sensitive
    if grep -q "function.*download\|function.*install\|function.*update" "$file"; then
        log_info "$file: Contains download/install/update functions - review for security"
    fi

    # Check for sudo usage
    if grep -q "sudo" "$file" && ! grep -q "# SECURITY:" "$file"; then
        log_warning "$file: Uses sudo without security comment"
    fi
}

main() {
    echo "Starting security analysis of shell scripts..."
    echo "Project root: $PROJECT_ROOT"
    echo

    # Find all shell scripts
    while IFS= read -r -d '' file; do
        ((files_checked++))
        echo "Checking: $file"

        check_file_permissions "$file"
        check_shebang "$file"
        check_script_content "$file"
        check_function_security "$file"

    done < <(find "$PROJECT_ROOT" -type f -name "*.sh" -not -path "*/.git/*" -not -path "*/node_modules/*" -print0)

    echo
    echo "Security Analysis Complete"
    echo "========================="
    echo "Files checked: $files_checked"
    echo "Errors found: $issues_found"
    echo "Warnings found: $warnings_found"

    if [[ $issues_found -gt 0 ]]; then
        echo
        echo -e "${RED}❌ Security issues found that should be addressed${NC}"
        exit 1
    elif [[ $warnings_found -gt 0 ]]; then
        echo
        echo -e "${YELLOW}⚠️  Warnings found - review recommended${NC}"
        exit 0
    else
        echo
        echo -e "${GREEN}✅ No security issues found${NC}"
        exit 0
    fi
}

main "$@"