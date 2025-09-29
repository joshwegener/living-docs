#!/bin/bash
set -euo pipefail
# Tracker Lifecycle Management - Manage spec implementation trackers

# create_tracker() - Create a new spec tracker file
# Input: $1 = spec_number, $2 = spec_name, $3 = framework
# Output: Path to created tracker file
create_tracker() {
    local spec_number="$1"
    local spec_name="$2"
    local framework="$3"

    local tracker_file="docs/active/${spec_number}-${spec_name}-tracker.md"
    local current_date=$(date +%Y-%m-%d)

    # Create the tracker with YAML frontmatter
    cat > "$tracker_file" << EOF
---
spec: /docs/specs/${spec_number}-${spec_name}/
status: planning
current_phase: 0
started: ${current_date}
framework: ${framework}
tasks_completed: []
---

# ${spec_name} Implementation

Tracking implementation of ${spec_name} spec using ${framework}.

## Current Status
- Phase: Planning
- Next: Create plan.md

## Progress Log
- ${current_date}: Tracker created
EOF

    echo "$tracker_file"
}

# update_tracker_status() - Update the status of a tracker
# Input: $1 = tracker_file, $2 = new_status
# Output: "SUCCESS" or error message
update_tracker_status() {
    local tracker_file="$1"
    local new_status="$2"

    if [ ! -f "$tracker_file" ]; then
        echo "ERROR: Tracker file not found: $tracker_file"
        return 1
    fi

    # Validate status
    case "$new_status" in
        planning|implementing|testing|completed|blocked|failed)
            ;;
        *)
            echo "ERROR: Invalid status: $new_status"
            return 1
            ;;
    esac

    # Update the status in YAML frontmatter
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^status: .*/status: ${new_status}/" "$tracker_file"
    else
        sed -i "s/^status: .*/status: ${new_status}/" "$tracker_file"
    fi

    echo "SUCCESS"
}

# update_tracker_phase() - Update the current phase
# Input: $1 = tracker_file, $2 = phase_number
# Output: "SUCCESS" or error message
update_tracker_phase() {
    local tracker_file="$1"
    local phase="$2"

    if [ ! -f "$tracker_file" ]; then
        echo "ERROR: Tracker file not found: $tracker_file"
        return 1
    fi

    # Validate phase
    if ! [[ "$phase" =~ ^[0-4]$ ]]; then
        echo "ERROR: Invalid phase: $phase (must be 0-4)"
        return 1
    fi

    # Update the phase in YAML frontmatter
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^current_phase: .*/current_phase: ${phase}/" "$tracker_file"
    else
        sed -i "s/^current_phase: .*/current_phase: ${phase}/" "$tracker_file"
    fi

    echo "SUCCESS"
}

# complete_tracker() - Mark tracker as completed and move to completed folder
# Input: $1 = tracker_file
# Output: Path to moved file in docs/completed/
complete_tracker() {
    local tracker_file="$1"

    if [ ! -f "$tracker_file" ]; then
        echo "ERROR: Tracker file not found: $tracker_file"
        return 1
    fi

    # Update status to completed
    update_tracker_status "$tracker_file" "completed" >/dev/null

    # Generate new filename with date prefix
    local basename=$(basename "$tracker_file")
    local date_prefix=$(date +%Y-%m-%d)
    local completed_file="docs/completed/${date_prefix}-${basename#*-}"

    # Move the file
    mv "$tracker_file" "$completed_file"
    echo "$completed_file"
}

# list_active_trackers() - List all active tracker files
# Input: None
# Output: Newline-separated list of active tracker files
list_active_trackers() {
    if [ -d "docs/active" ]; then
        find docs/active -name "*-tracker.md" -type f 2>/dev/null
    fi
}

# get_tracker_info() - Extract tracker metadata as JSON
# Input: $1 = tracker_file
# Output: JSON object with tracker metadata
get_tracker_info() {
    local tracker_file="$1"

    if [ ! -f "$tracker_file" ]; then
        echo "ERROR: Tracker file not found: $tracker_file"
        return 1
    fi

    # Extract YAML frontmatter fields
    local spec=$(grep "^spec:" "$tracker_file" | cut -d' ' -f2-)
    local status=$(grep "^status:" "$tracker_file" | cut -d' ' -f2)
    local phase=$(grep "^current_phase:" "$tracker_file" | cut -d' ' -f2)
    local framework=$(grep "^framework:" "$tracker_file" | cut -d' ' -f2)

    # Extract spec name from path
    local spec_name=$(echo "$spec" | sed 's/.*\/\([^\/]*\)\//\1/')

    # Output as JSON
    cat << EOF
{
  "spec": "${spec_name}",
  "status": "${status}",
  "phase": ${phase},
  "framework": "${framework}"
}
EOF
}