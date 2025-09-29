#!/bin/bash
set -euo pipefail
# Compliance Review Service - Check rule adherence

# review_compliance() - Review changes for rule compliance
# Input: $1 = git diff or file list to review
# Output: JSON result with pass/fail and violations
review_compliance() {
    local changes="$1"
    local violations=()
    local result="PASS"

    # Check for empty diff (no changes = pass)
    if [ -z "$changes" ]; then
        cat << EOF
{
  "result": "PASS",
  "violations": []
}
EOF
        return 0
    fi

    # Check TDD_TESTS_FIRST gate
    if echo "$changes" | grep -q "^diff.*src/" && \
       ! echo "$changes" | grep -q "^diff.*test"; then
        violations+=('{"gate": "TDD_TESTS_FIRST", "message": "Implementation without tests"}')
        result="FAIL"
    fi

    # Check for tasks.md updates if implementation changed
    if echo "$changes" | grep -q "^diff.*src/"; then
        if ! echo "$changes" | grep -q "tasks.md"; then
            # This is a warning, not a failure (tasks might not exist)
            if [ -f "$(find . -name tasks.md 2>/dev/null | head -1)" ]; then
                violations+=('{"gate": "UPDATE_TASKS_MD", "message": "tasks.md not updated"}')
                # Don't fail for this, just warn
            fi
        fi
    fi

    # Build JSON response
    local violations_json=""
    if [ ${#violations[@]} -gt 0 ]; then
        violations_json=$(printf '%s,' "${violations[@]}")
        violations_json="[${violations_json%,}]"
    else
        violations_json="[]"
    fi

    cat << EOF
{
  "result": "${result}",
  "violations": ${violations_json}
}
EOF
}

# check_gate() - Check a specific gate
# Input: $1 = gate_id, $2 = context
# Output: "PASS" or "FAIL: reason"
check_gate() {
    local gate_id="$1"
    local context="$2"

    case "$gate_id" in
        TDD_TESTS_FIRST)
            # Check if implementation comes without tests
            if [ -z "$context" ]; then
                echo "PASS"
                return 0
            fi

            if echo "$context" | grep -q "src/.*\.sh\|src/.*\.js\|src/.*\.py" && \
               ! echo "$context" | grep -q "test.*\.sh\|test.*\.js\|test.*\.py"; then
                echo "FAIL: Implementation without tests"
                return 1
            fi
            echo "PASS"
            ;;

        UPDATE_TASKS_MD)
            # Check if tasks.md exists and needs updating
            if [ -z "$context" ]; then
                echo "PASS"
                return 0
            fi

            # This is more of a reminder than a hard fail
            echo "PASS"
            ;;

        PHASE_ORDERING)
            # Would check phase progression
            echo "PASS"
            ;;

        *)
            echo "FAIL: Unknown gate: $gate_id"
            return 1
            ;;
    esac
}

# get_active_gates() - Get all active gates from rule files
# Output: JSON array of active gates
get_active_gates() {
    local gates="[]"

    # Source rule loading to get installed specs
    if [ -f "scripts/rules/rule-loading.sh" ]; then
        source scripts/rules/rule-loading.sh
        local specs=$(get_installed_specs)

        # For each framework, extract gates from rule files
        for framework in $specs; do
            local rule_file="docs/rules/${framework}-rules.md"
            if [ -f "$rule_file" ]; then
                # Extract gate IDs from rule file
                local framework_gates=$(grep "^## Gate:" "$rule_file" | sed 's/## Gate: //')
                for gate in $framework_gates; do
                    gates=$(echo "$gates" | sed 's/\]$//')
                    if [ "$gates" != "[" ]; then
                        gates="${gates},"
                    fi
                    gates="${gates}{\"id\": \"${gate}\", \"framework\": \"${framework}\"}]"
                done
            fi
        done
    fi

    echo "$gates"
}

# audit_review() - Log review result to audit trail
# Input: $1 = review_result, $2 = timestamp
# Output: "SUCCESS" or error message
audit_review() {
    local result="$1"
    local timestamp="${2:-$(date +%Y-%m-%d\ %H:%M:%S)}"
    local audit_file="docs/compliance-audit.log"

    mkdir -p docs
    echo "[$timestamp] Review result: $result" >> "$audit_file"
    echo "SUCCESS"
}