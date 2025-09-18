#!/bin/bash
# Contract: Compliance Review Service (Phase 2)
# Purpose: Independent review of rule compliance

# Contract: review_compliance()
# Input: $1 = git diff or file list to review
# Output: JSON result with pass/fail and violations
# Example Output:
# {
#   "result": "FAIL",
#   "violations": [
#     {"gate": "TDD_TESTS_FIRST", "file": "src/feature.js", "line": 45},
#     {"gate": "UPDATE_TASKS_MD", "task": 5, "status": "not_updated"}
#   ]
# }
review_compliance() {
    local changes="$1"
    echo "CONTRACT_NOT_IMPLEMENTED"
}

# Contract: spawn_review_terminal()
# Input: $1 = review context (git diff)
# Output: PID of spawned terminal process
# Behavior:
#   - Opens new terminal window
#   - Loads ONLY review agent + diff
#   - No access to main context
spawn_review_terminal() {
    local context="$1"
    echo "CONTRACT_NOT_IMPLEMENTED"
}

# Contract: check_gate()
# Input: $1 = gate_id, $2 = context
# Output: "PASS" or "FAIL: reason"
# Example: check_gate "TDD_TESTS_FIRST" "$(git diff)"
check_gate() {
    local gate_id="$1"
    local context="$2"
    echo "CONTRACT_NOT_IMPLEMENTED"
}

# Contract: get_active_gates()
# Input: None
# Output: JSON array of active gates from all rule files
# Example: [
#   {"id": "TDD_TESTS_FIRST", "framework": "spec-kit", "phase": "testing"},
#   {"id": "UPDATE_CONVENTIONS", "framework": "aider", "phase": "implementation"}
# ]
get_active_gates() {
    echo "CONTRACT_NOT_IMPLEMENTED"
}

# Contract: audit_review()
# Input: $1 = review_result, $2 = timestamp
# Output: "SUCCESS" or error message
# Behavior: Logs review result to audit trail
audit_review() {
    local result="$1"
    local timestamp="$2"
    echo "CONTRACT_NOT_IMPLEMENTED"
}