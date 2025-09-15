# Memory Enforcement Specification

## Research Findings

### What Works (2024-2025)
1. **CRITICAL/PRIORITY markers** - Claude uses these for copyright
2. **XML tags** - Better parsing and structure recognition
3. **Instruction hierarchy** - System-level > User-level instructions
4. **Repetition** - Beginning and end reinforcement
5. **Checkboxes** - Mental checklist AI can "tick off"

### Pattern Drift Problem
Research shows "pattern drift accelerates with project scale":
- Drift rate increases exponentially with size
- Memory limitations cause principles to be forgotten
- Continuous policing required for larger codebases

## Implementation in living-docs

### CRITICAL_CHECKLIST
```xml
<CRITICAL_CHECKLIST priority="HIGHEST">
**⚠️ MANDATORY: Check these BEFORE ANY action:**
□ Run `./scripts/check-drift.sh` if it exists
□ Creating a new file? Add to current.md IMMEDIATELY
□ Modifying code? Update relevant docs
□ Completing a task? Move to completed/ and update log.md
□ Making claims? VERIFY first (test/check files exist)
□ See orphaned/uncategorized items? FIX THEM
</CRITICAL_CHECKLIST>
```

### Placement Strategy
1. **TOP of bootstrap.md** - First thing AI sees
2. **BOTTOM reminder** - PRIORITY_INSTRUCTION block
3. **Short and memorable** - 6 items max
4. **Action-oriented** - Each item is a clear action

### Enforcement Levels
```
SYSTEM-LEVEL (Highest)
├── CRITICAL_CHECKLIST
├── PRIORITY_INSTRUCTION
└── MANDATORY gates

USER-LEVEL (Lower)
├── User requests
├── Feature additions
└── Modifications
```

## Expected Outcomes
- Reduced documentation drift
- Consistent current.md updates
- No orphaned files
- Verified claims only

## Testing
Try telling the AI to "skip documentation" - it should refuse based on PRIORITY_INSTRUCTION.

## References
- OpenAI Instruction Hierarchy research
- Claude system prompt analysis
- Prompt engineering best practices 2025