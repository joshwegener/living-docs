#!/bin/bash
set -euo pipefail

# Create a new feature specification directory
# Usage: ./create-new-feature.sh [feature-number] [feature-name]

set -e

# Get the directory where specs should be created
SPECS_DIR="docs/specs"

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 [feature-number] [feature-name]"
    echo "Example: $0 01 user-authentication"
    exit 1
fi

FEATURE_NUMBER="$1"
FEATURE_NAME="$2"
FEATURE_DIR="$SPECS_DIR/${FEATURE_NUMBER}-${FEATURE_NAME}"

# Check if directory already exists
if [ -d "$FEATURE_DIR" ]; then
    echo "Error: Feature directory already exists: $FEATURE_DIR"
    exit 1
fi

# Create feature directory
echo "Creating feature directory: $FEATURE_DIR"
mkdir -p "$FEATURE_DIR"

# Create spec.md template
cat > "$FEATURE_DIR/spec.md" << 'EOF'
# Specification: [Feature Name]

## Overview
Brief description of the feature.

## Requirements
- Requirement 1
- Requirement 2
- Requirement 3

## User Stories
As a [type of user], I want [goal] so that [reason].

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

## Technical Design
Describe the technical approach.

## API Design
Define any APIs if applicable.

## Data Model
Describe data structures and database schema.

## Security Considerations
List security requirements and considerations.

## Performance Requirements
Define performance expectations.

## Testing Strategy
Outline testing approach.
EOF

# Create plan.md template
cat > "$FEATURE_DIR/plan.md" << 'EOF'
# Implementation Plan: [Feature Name]

## Overview
Summary of implementation approach.

## Architecture
Describe system architecture changes.

## Dependencies
- Dependency 1
- Dependency 2

## Implementation Phases
1. Phase 1: [Description]
2. Phase 2: [Description]
3. Phase 3: [Description]

## Risk Assessment
| Risk | Impact | Mitigation |
|------|--------|------------|
| Risk 1 | High | Mitigation strategy |

## Timeline
- Week 1: [Tasks]
- Week 2: [Tasks]
EOF

# Create tasks.md template
cat > "$FEATURE_DIR/tasks.md" << 'EOF'
# Task Breakdown: [Feature Name]

## Prerequisites
- [ ] Prerequisite 1
- [ ] Prerequisite 2

## Implementation Tasks
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]
- [ ] Task 3: [Description]

## Testing Tasks
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Perform manual testing

## Documentation Tasks
- [ ] Update API documentation
- [ ] Update user guide
- [ ] Create examples

## Review Tasks
- [ ] Code review
- [ ] Security review
- [ ] Performance review
EOF

# Create research.md template
cat > "$FEATURE_DIR/research.md" << 'EOF'
# Research: [Feature Name]

## Background
Context and background information.

## Existing Solutions
Research on how others solve this problem.

## Technologies Considered
- Option 1: Pros/Cons
- Option 2: Pros/Cons

## Decision
Chosen approach and rationale.

## References
- [Link 1](URL)
- [Link 2](URL)
EOF

echo "✅ Feature directory created successfully!"
echo ""
echo "Created files:"
echo "  - $FEATURE_DIR/spec.md"
echo "  - $FEATURE_DIR/plan.md"
echo "  - $FEATURE_DIR/tasks.md"
echo "  - $FEATURE_DIR/research.md"
echo ""
echo "Next steps:"
echo "1. Edit the specification files"
echo "2. Review with team or AI assistant"
echo "3. Begin implementation"