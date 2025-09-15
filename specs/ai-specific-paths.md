# AI-Specific Path Mapping for Spec-Kit

## Current Findings

Based on spec-kit's own scripts, the AI systems use different locations:

### Claude Code
- Commands: `.claude/commands/`
- Instructions: `CLAUDE.md` (root)
- Spec-kit creates: `/specify`, `/plan`, `/tasks` commands

### GitHub Copilot
- Commands: Unknown (needs research)
- Instructions: `.github/copilot-instructions.md`
- Spec-kit behavior: TBD

### Gemini CLI
- Commands: Unknown (needs research)
- Instructions: `GEMINI.md` (root)
- Spec-kit behavior: TBD

### Cursor AI
- Commands: `.cursor/` (assumed, needs verification)
- Instructions: Unknown
- Spec-kit behavior: Not mentioned in spec-kit

### ChatGPT
- Commands: Unknown
- Instructions: Unknown
- Spec-kit behavior: Not mentioned in spec-kit

## Proposed Solution

Update wizard.sh and spec-kit adapter to:

1. Map AI choice to correct paths:
```bash
case $AI_CHOICE in
    1) # Claude
        SPEC_COMMAND_DIR=".claude/commands"
        AI_INSTRUCTION_FILE="CLAUDE.md"
        ;;
    2) # ChatGPT
        SPEC_COMMAND_DIR=".chatgpt"  # TBD
        AI_INSTRUCTION_FILE="AI.md"
        ;;
    3) # GitHub Copilot
        SPEC_COMMAND_DIR=".github"  # TBD
        AI_INSTRUCTION_FILE=".github/copilot-instructions.md"
        ;;
    4) # Cursor
        SPEC_COMMAND_DIR=".cursor"  # TBD
        AI_INSTRUCTION_FILE="CURSOR.md"
        ;;
esac
```

2. Have spec-kit adapter use these paths when installing

3. Detection should check all known locations

## Action Items
- [ ] Research Cursor AI's expected directory structure
- [ ] Research ChatGPT's plugin/command structure
- [ ] Verify GitHub Copilot's command location
- [ ] Update wizard.sh with AI-specific paths
- [ ] Update spec-kit adapter to respect AI choice