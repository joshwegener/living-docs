#!/bin/bash
# Spawn Review Terminal - Open isolated terminal for compliance review

# spawn_review_terminal() - Open new terminal with review context
# Input: $1 = review context (git diff)
# Output: PID of spawned terminal process or error
spawn_review_terminal() {
    local context="$1"
    local review_script=$(mktemp)

    # Create temporary review script
    cat > "$review_script" << 'EOF'
#!/bin/bash
echo "==================================="
echo "   COMPLIANCE REVIEW (ISOLATED)    "
echo "==================================="
echo ""
echo "Review the following changes for compliance:"
echo ""
EOF

    echo "cat << 'DIFF_END'" >> "$review_script"
    echo "$context" >> "$review_script"
    echo "DIFF_END" >> "$review_script"

    cat >> "$review_script" << 'EOF'
echo ""
echo "==================================="
echo "Checking against gates..."
echo ""

# Source compliance review
if [ -f "scripts/compliance/compliance-review.sh" ]; then
    source scripts/compliance/compliance-review.sh
    result=$(review_compliance "$1")
    echo "$result" | python3 -m json.tool 2>/dev/null || echo "$result"
else
    echo "ERROR: compliance-review.sh not found"
fi

echo ""
echo "Review complete. Close this window to continue."
read -p "Press Enter to exit..."
EOF

    chmod +x "$review_script"

    # Detect platform and spawn terminal
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [ -z "$DISPLAY" ] && [ -z "$TERM_PROGRAM" ]; then
            echo "ERROR: No display available for terminal spawn"
            return 1
        fi

        # Use osascript to open Terminal.app
        osascript << EOF 2>/dev/null &
            tell application "Terminal"
                activate
                do script "bash $review_script; rm $review_script"
            end tell
EOF
        local pid=$!
        echo "$pid"

    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if [ -z "$DISPLAY" ]; then
            echo "ERROR: No DISPLAY variable set"
            return 1
        fi

        # Try different terminal emulators
        if command -v gnome-terminal >/dev/null 2>&1; then
            gnome-terminal -- bash -c "$review_script; rm $review_script; read -p 'Press Enter to close...'" &
            echo "$!"
        elif command -v xterm >/dev/null 2>&1; then
            xterm -e "$review_script; rm $review_script; read -p 'Press Enter to close...'" &
            echo "$!"
        elif command -v konsole >/dev/null 2>&1; then
            konsole -e bash -c "$review_script; rm $review_script; read -p 'Press Enter to close...'" &
            echo "$!"
        else
            echo "ERROR: No supported terminal emulator found"
            return 1
        fi

    else
        echo "ERROR: Platform not supported for terminal spawning"
        return 1
    fi
}

# If called directly with arguments, run the function
if [ "${BASH_SOURCE[0]}" = "${0}" ] && [ $# -gt 0 ]; then
    spawn_review_terminal "$@"
fi