#!/bin/bash
# Living-Docs Objective Verification System
# Prevents confirmation bias by requiring proof before claims

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verification function
verify() {
    local claim_type="$1"
    local target="$2"

    echo -e "${YELLOW}VERIFYING:${NC} ${claim_type} for '${target}'"
    echo "----------------------------------------"

    case "$claim_type" in
        "adapter-works")
            echo "Testing adapter: ${target}"
            local adapter_file="adapters/${target}.sh"
            local test_dir="/tmp/living-docs-adapter-test-$$"
            local failures=0

            # Step 1: Check adapter file exists
            if [[ ! -f "$adapter_file" ]]; then
                echo -e "${RED}❌ FAIL:${NC} No adapter at $adapter_file"
                return 1
            fi
            echo -e "  ✓ Adapter file exists"

            # Step 2: Check adapter is executable
            if [[ ! -x "$adapter_file" ]]; then
                echo -e "${RED}❌ FAIL:${NC} Adapter not executable"
                ((failures++))
            else
                echo -e "  ✓ Adapter is executable"
            fi

            # Step 3: Test adapter execution
            mkdir -p "$test_dir"
            cd "$test_dir"

            # Create minimal test environment
            echo "Testing ${target} adapter functionality..."
            case "$target" in
                "spec-kit")
                    # Test spec-kit adapter creates GitHub structure
                    if bash "$OLDPWD/$adapter_file" --test 2>&1; then
                        # Verify it created expected files
                        if [[ -d ".github/ISSUE_TEMPLATE" ]] && [[ -f ".github/PULL_REQUEST_TEMPLATE.md" ]]; then
                            echo -e "  ✓ Creates GitHub spec-kit structure"
                        else
                            echo -e "${RED}  ✗ Missing GitHub structure${NC}"
                            ((failures++))
                        fi
                    else
                        echo -e "${RED}  ✗ Adapter execution failed${NC}"
                        ((failures++))
                    fi
                    ;;

                "bmad")
                    # Test BMAD adapter creates method structure
                    if bash "$OLDPWD/$adapter_file" --test 2>&1; then
                        if [[ -d ".bmad" ]] && [[ -f ".bmad/config.yaml" ]]; then
                            echo -e "  ✓ Creates BMAD structure"
                        else
                            echo -e "${RED}  ✗ Missing BMAD structure${NC}"
                            ((failures++))
                        fi
                    else
                        echo -e "${RED}  ✗ Adapter execution failed${NC}"
                        ((failures++))
                    fi
                    ;;

                *)
                    # Generic adapter test
                    if bash "$OLDPWD/$adapter_file" --test 2>&1; then
                        echo -e "  ✓ Adapter executes without error"
                    else
                        echo -e "${RED}  ✗ Adapter execution failed${NC}"
                        ((failures++))
                    fi
                    ;;
            esac

            # Step 4: Check documentation exists
            cd "$OLDPWD"
            if [[ -f "docs/adapters/${target}.md" ]]; then
                echo -e "  ✓ Documentation exists"

                # Verify documentation has required sections
                if grep -q "## Installation" "docs/adapters/${target}.md" && \
                   grep -q "## Usage" "docs/adapters/${target}.md" && \
                   grep -q "## Configuration" "docs/adapters/${target}.md"; then
                    echo -e "  ✓ Documentation complete"
                else
                    echo -e "${RED}  ✗ Documentation missing required sections${NC}"
                    ((failures++))
                fi
            else
                echo -e "${RED}  ✗ No documentation at docs/adapters/${target}.md${NC}"
                ((failures++))
            fi

            # Cleanup
            rm -rf "$test_dir"

            if [[ $failures -eq 0 ]]; then
                echo -e "${GREEN}✅ PASS:${NC} Adapter '${target}' fully functional"
                return 0
            else
                echo -e "${RED}❌ FAIL:${NC} Adapter '${target}' has $failures issues"
                return 1
            fi
            ;;

        "feature-complete")
            echo "Validating feature: ${target}"
            local failures=0

            # Step 1: Check if moved to completed/
            if ls docs/completed/*${target}* 2>/dev/null | grep -q .; then
                echo -e "  ✓ Feature in completed/"
                local completed_file=$(ls docs/completed/*${target}* | head -1)
            else
                echo -e "${RED}  ✗ Feature not in completed/${NC}"
                if ls docs/active/*${target}* 2>/dev/null | grep -q .; then
                    echo -e "${YELLOW}    Still in active/${NC}"
                fi
                ((failures++))
            fi

            # Step 2: Test the actual feature
            case "$target" in
                "wizard")
                    echo "Testing wizard functionality..."
                    local test_dir="/tmp/wizard-test-$$"
                    mkdir -p "$test_dir"
                    cd "$test_dir"

                    # Test wizard execution
                    if echo -e "1\n1\n1\n" | bash "$OLDPWD/wizard.sh" 2>&1 | grep -q "successfully"; then
                        echo -e "  ✓ Wizard executes successfully"
                    else
                        echo -e "${RED}  ✗ Wizard execution failed${NC}"
                        ((failures++))
                    fi

                    # Check if wizard created expected structure
                    if [[ -f "docs/current.md" ]] || [[ -f ".claude/docs/current.md" ]]; then
                        echo -e "  ✓ Wizard creates documentation structure"
                    else
                        echo -e "${RED}  ✗ Wizard doesn't create expected files${NC}"
                        ((failures++))
                    fi

                    cd "$OLDPWD"
                    rm -rf "$test_dir"
                    ;;

                "testing")
                    # Verify testing framework exists and works
                    if [[ -f "test.sh" ]] && [[ -x "test.sh" ]]; then
                        echo -e "  ✓ Test script exists and is executable"

                        # Run a simple test
                        if ./test.sh basic 2>&1 | grep -q -E "(PASS|pass|✓)"; then
                            echo -e "  ✓ Tests execute successfully"
                        else
                            echo -e "${RED}  ✗ Test execution failed${NC}"
                            ((failures++))
                        fi
                    else
                        echo -e "${RED}  ✗ No executable test.sh found${NC}"
                        ((failures++))
                    fi
                    ;;

                "bootstrap")
                    # Verify bootstrap is properly integrated
                    if [[ -f "docs/bootstrap.md" ]]; then
                        echo -e "  ✓ Bootstrap documentation exists"

                        # Check if CLAUDE.md references bootstrap
                        if grep -q "bootstrap.md" CLAUDE.md 2>/dev/null; then
                            echo -e "  ✓ Bootstrap referenced in CLAUDE.md"
                        else
                            echo -e "${RED}  ✗ Bootstrap not referenced in CLAUDE.md${NC}"
                            ((failures++))
                        fi
                    else
                        echo -e "${RED}  ✗ No bootstrap.md found${NC}"
                        ((failures++))
                    fi
                    ;;

                *)
                    echo -e "${YELLOW}  ⚠ Generic feature - checking documentation only${NC}"
                    ;;
            esac

            # Step 3: Verify documentation completeness
            if [[ -n "$completed_file" ]]; then
                if grep -q "Status.*Complete" "$completed_file" 2>/dev/null || \
                   grep -q "✅" "$completed_file" 2>/dev/null; then
                    echo -e "  ✓ Documentation marked as complete"
                else
                    echo -e "${YELLOW}  ⚠ Documentation doesn't explicitly mark completion${NC}"
                fi
            fi

            if [[ $failures -eq 0 ]]; then
                echo -e "${GREEN}✅ PASS:${NC} Feature '${target}' verified complete"
                return 0
            else
                echo -e "${RED}❌ FAIL:${NC} Feature '${target}' has $failures issues"
                return 1
            fi
            ;;

        "bug-fixed")
            if grep -q "\[x\].*${target}" bugs.md 2>/dev/null; then
                echo -e "${GREEN}✅ PASS:${NC} Bug '${target}' marked as fixed in bugs.md"
                grep "${target}" bugs.md
                return 0
            else
                echo -e "${RED}❌ FAIL:${NC} Bug '${target}' not marked as fixed"
                grep "${target}" bugs.md 2>/dev/null || echo "  Bug not found in bugs.md"
                return 1
            fi
            ;;

        "tests-pass")
            if [[ -f "test.sh" ]]; then
                echo "Running tests for '${target}'..."
                if ./test.sh "${target}" 2>&1; then
                    echo -e "${GREEN}✅ PASS:${NC} Tests passed"
                    return 0
                else
                    echo -e "${RED}❌ FAIL:${NC} Tests failed"
                    return 1
                fi
            else
                echo -e "${RED}❌ FAIL:${NC} No test.sh found"
                return 1
            fi
            ;;

        "wizard-works")
            echo "End-to-end testing of wizard.sh..."
            local temp_dir="/tmp/living-docs-e2e-$$"
            local failures=0
            mkdir -p "$temp_dir"

            # Save current directory
            local original_dir="$PWD"
            cd "$temp_dir"

            # Test 1: New project installation
            echo "Test 1: New project installation"
            mkdir new-project && cd new-project
            if echo -e "1\n1\n1\n" | bash "$original_dir/wizard.sh" 2>&1 | tee wizard.log | grep -q "success"; then
                echo -e "  ✓ Wizard completes for new project"

                # Verify structure created
                if [[ -f "docs/current.md" ]] || [[ -f ".claude/docs/current.md" ]]; then
                    echo -e "  ✓ Documentation structure created"
                else
                    echo -e "${RED}  ✗ No documentation structure${NC}"
                    ((failures++))
                fi
            else
                echo -e "${RED}  ✗ Wizard failed for new project${NC}"
                cat wizard.log | tail -20
                ((failures++))
            fi
            cd ..

            # Test 2: Existing project repair
            echo "Test 2: Existing project repair"
            mkdir existing-project && cd existing-project
            git init >/dev/null 2>&1
            echo "# Test Project" > README.md

            if echo -e "2\n1\n" | bash "$original_dir/wizard.sh" 2>&1 | grep -q -E "(success|repair|updated)"; then
                echo -e "  ✓ Wizard repairs existing project"
            else
                echo -e "${RED}  ✗ Wizard failed for existing project${NC}"
                ((failures++))
            fi
            cd ..

            # Test 3: Path with spaces handling
            echo "Test 3: Path with spaces"
            mkdir "project with spaces" && cd "project with spaces"
            if bash "$original_dir/wizard.sh" --test 2>&1 | grep -q -E "(success|completed)"; then
                echo -e "  ✓ Handles paths with spaces"
            else
                echo -e "${YELLOW}  ⚠ May have issues with spaces in paths${NC}"
            fi
            cd ..

            # Test 4: Cross-platform sed compatibility
            echo "Test 4: Sed compatibility check"
            if grep -q "sed -i ''" "$original_dir/wizard.sh"; then
                echo -e "  ✓ Uses macOS-compatible sed syntax"
            elif grep -q 'sed -i""' "$original_dir/wizard.sh"; then
                echo -e "  ✓ Uses cross-platform sed syntax"
            else
                echo -e "${YELLOW}  ⚠ May have sed portability issues${NC}"
            fi

            # Cleanup
            cd "$original_dir"
            rm -rf "$temp_dir"

            if [[ $failures -eq 0 ]]; then
                echo -e "${GREEN}✅ PASS:${NC} Wizard fully functional"
                return 0
            else
                echo -e "${RED}❌ FAIL:${NC} Wizard has $failures critical issues"
                return 1
            fi
            ;;

        "portability-check")
            echo "Checking sed portability..."
            local issues=0

            # Check for sed -i without quotes (macOS incompatible)
            if grep -r "sed -i [^']" *.sh 2>/dev/null | grep -v "sed -i ''"; then
                echo -e "${RED}❌ ISSUE:${NC} Found sed -i without '' for macOS"
                ((issues++))
            fi

            # Check for paths with spaces
            if grep -r 'DOCS_PATH=.*[[:space:]]' *.sh 2>/dev/null; then
                echo -e "${RED}❌ ISSUE:${NC} Found paths with spaces (not quoted)"
                ((issues++))
            fi

            if [[ $issues -eq 0 ]]; then
                echo -e "${GREEN}✅ PASS:${NC} No portability issues found"
                return 0
            else
                echo -e "${RED}❌ FAIL:${NC} Found $issues portability issues"
                return 1
            fi
            ;;

        *)
            echo -e "${RED}Unknown verification type:${NC} $claim_type"
            echo "Available types:"
            echo "  adapter-works <name>      - Test adapter execution and docs"
            echo "  feature-complete <name>   - Verify feature works and documented"
            echo "  bug-fixed <pattern>       - Verify bug marked as fixed"
            echo "  tests-pass <component>    - Run and verify tests"
            echo "  wizard-works              - Full E2E wizard testing"
            echo "  portability-check         - Check for cross-platform issues"
            return 1
            ;;
    esac
}

# Gate function - blocks until verification passes
gate() {
    local claim_type="$1"
    local target="$2"

    echo -e "${YELLOW}=== VERIFICATION GATE ===${NC}"
    echo "This is a mandatory checkpoint. Work cannot proceed without PASS."
    echo ""

    if verify "$claim_type" "$target"; then
        echo ""
        echo -e "${GREEN}=== GATE PASSED ===${NC}"
        echo "Verification successful. You may proceed."
        return 0
    else
        echo ""
        echo -e "${RED}=== GATE FAILED ===${NC}"
        echo "Verification failed. Fix the issue before proceeding."
        echo ""
        echo "To bypass (NOT RECOMMENDED):"
        echo "  export SKIP_VERIFICATION=1"

        if [[ "$SKIP_VERIFICATION" == "1" ]]; then
            echo -e "${YELLOW}WARNING: Verification skipped by override${NC}"
            return 0
        fi

        return 1
    fi
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <verification-type> [target]"
        echo ""
        echo "Verification types:"
        echo "  adapter-exists <name>     - Verify adapter implementation"
        echo "  feature-complete <name>   - Verify feature completion"
        echo "  bug-fixed <pattern>       - Verify bug fix"
        echo "  tests-pass <component>    - Run tests"
        echo "  wizard-works              - Test wizard"
        echo "  portability-check         - Check cross-platform compatibility"
        echo ""
        echo "Gate mode (blocks on failure):"
        echo "  $0 gate <type> [target]"
        exit 1
    fi

    if [[ "$1" == "gate" ]]; then
        shift
        gate "$@"
    else
        verify "$@"
    fi
fi