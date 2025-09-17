# Minimal Impact Fix

**Completed**: Sept 14, 2025 | **Duration**: 20 minutes | **Agent**: DEV

## Objective
Ensure minimal impact on user projects when they choose subdirectory documentation paths.

## Problem
When users selected `.github/docs/` or `.claude/docs/`, we were still creating bugs.md and ideas.md in the root directory, defeating the purpose of tucking documentation away.

## Solution
Modified wizard.sh to intelligently place files:
- If docs path is `docs` or `.docs`: bugs.md and ideas.md go in root (traditional)
- If docs path is a subdirectory: bugs.md and ideas.md go in that subdirectory
- CLAUDE.md/AI.md/PROJECT.md always stays in root as the entry point

## Key Changes
- Added logic to determine `$BUGS_FILE` and `$IDEAS_FILE` locations
- Updated all references throughout wizard.sh to use variables
- Updated bootstrap.md template to use correct paths

## Result
✅ Achieved true minimal impact:
- Root: Just one file (CLAUDE.md) with one line
- Subdirectory: Everything else neatly organized
- Perfect for teams wanting clean root directories