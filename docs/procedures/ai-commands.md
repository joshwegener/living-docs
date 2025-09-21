# AI Command Installation System

## Problem Solved
Different AI assistants expect commands in different locations:
- Claude: `.claude/commands/`
- Cursor: `.cursor/commands/`
- Aider: `.aider/commands/`

But adapters install to a generic location like `.living-docs/memory/commands/`.

## Solution
Automatic AI detection and command copying during adapter installation.

## Components

### 1. AI Detection (`adapters/common/ai-detect.sh`)
- Detects which AI assistants are in use
- Checks for signature files/directories
- Returns list of detected AIs

### 2. Command Installation
- Copies commands from adapter location to AI-specific directories
- Tracks installations in `.living-docs.manifest`
- Handles special cases (e.g., .claude path)

### 3. Adapter Integration
Adapters that include commands should:
1. Source `ai-detect.sh`
2. Call `install_ai_commands` after copying templates
3. Handle path rewriting with placeholders

## Usage Example

```bash
# In adapter install.sh
source "$ADAPTER_DIR/../common/ai-detect.sh"
install_ai_commands "$PROJECT_ROOT/$MEMORY_PATH/commands" "$PROJECT_ROOT"
```

## Supported AI Assistants
- Claude (.claude/commands/)
- Cursor (.cursor/commands/)
- Aider (.aider/commands/)
- Continue (.continue/commands/)
- Agent-OS (.agent-os/commands/)

## Future Improvements
- Add support for more AI assistants
- Implement update tracking for changed commands
- Add uninstall cleanup via manifest