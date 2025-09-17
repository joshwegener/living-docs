# Path Rewriting System for Multi-Spec Adapters

**Status**: 🟡 In Development
**Version**: 0.1.0
**Created**: 2025-09-16

## Problem Statement

Different spec frameworks hardcode different directory paths:
- BMAD expects `docs/specs/`
- Agent-OS expects `.agent-os/specs/`
- Spec-kit expects `memory/` and `specs/`
- User wants everything in `.claude/` or custom location

Without path rewriting, we get:
- File conflicts between frameworks
- Scattered documentation across multiple directories
- Frameworks that don't respect user preferences
- Broken references in templates and scripts

## Solution: Dynamic Path Rewriting During Installation

### Core Concept

Transform framework paths to user-selected paths at installation time:
```
Framework says: "Store in docs/specs/feature.md"
User selected:  ".claude"
Result:        "Store in .claude/specs/feature.md"
```

### Path Variables

```bash
# Set by wizard based on user selection
LIVING_DOCS_PATH=".claude"          # Or "docs", ".github", etc.
AI_PATH="$LIVING_DOCS_PATH"         # AI assistant files location
SPECS_PATH="$LIVING_DOCS_PATH/specs"
MEMORY_PATH="$LIVING_DOCS_PATH/memory"
SCRIPTS_PATH="$LIVING_DOCS_PATH/scripts"
```

### Dated Specs Structure

Following Agent-OS pattern for all frameworks:
```
.claude/specs/
├── 2025-09-16-authentication/
│   ├── spec.md
│   ├── plan.md
│   ├── tasks.md
│   └── research.md
├── 2025-09-17-payment-gateway/
│   ├── spec.md
│   └── architecture.md
└── 2025-09-18-database-migration/
    └── spec.md
```

Benefits:
- Chronological ordering
- Clear history of specifications
- No naming conflicts
- Easy archival of old specs

### Path Mapping Configuration

Each adapter includes `path-map.yml`:

```yaml
# adapters/bmad-method/path-map.yml
name: bmad-method
version: 1.0.0

# Define path replacements
path_replacements:
  - pattern: "docs/"
    replace_with: "{{LIVING_DOCS_PATH}}/"
  - pattern: ".bmad/"
    replace_with: "{{AI_PATH}}/bmad/"
  - pattern: "specs/"
    replace_with: "{{SPECS_PATH}}/"
  - pattern: "memory/"
    replace_with: "{{MEMORY_PATH}}/"

# Files that need path rewriting
files_to_rewrite:
  - "**/*.md"
  - "**/*.sh"
  - "**/*.yml"
  - "**/*.json"
  - "**/package.json"

# Commands that need path updates
commands_to_update:
  - pattern: "cd docs/specs"
    replace_with: "cd {{SPECS_PATH}}"
  - pattern: "mkdir -p .bmad"
    replace_with: "mkdir -p {{AI_PATH}}/bmad"
```

### Rewriting Engine

```bash
#!/bin/bash
# Core rewriting function in wizard.sh

rewrite_paths() {
    local adapter_dir="$1"
    local target_dir="$2"
    local path_map="$adapter_dir/path-map.yml"

    # Load user's path preferences
    source .living-docs.config

    # Parse path-map.yml and apply replacements
    while IFS= read -r file; do
        # Use sed with proper escaping for macOS/Linux compatibility
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' \
                -e "s|docs/|${LIVING_DOCS_PATH}/|g" \
                -e "s|\.bmad/|${AI_PATH}/bmad/|g" \
                -e "s|specs/|${SPECS_PATH}/|g" \
                "$file"
        else
            sed -i \
                -e "s|docs/|${LIVING_DOCS_PATH}/|g" \
                -e "s|\.bmad/|${AI_PATH}/bmad/|g" \
                -e "s|specs/|${SPECS_PATH}/|g" \
                "$file"
        fi
    done < <(find "$target_dir" -type f \( -name "*.md" -o -name "*.sh" \))
}
```

### Installation Flow

1. **User Selection**
   ```
   Where should specs and AI files be stored?
   1) .claude/      (Recommended for Claude)
   2) .github/      (GitHub-friendly)
   3) docs/         (Traditional)
   4) .docs/        (Hidden)
   5) Custom path
   ```

2. **Path Configuration**
   ```bash
   # Save to .living-docs.config
   echo "LIVING_DOCS_PATH=\".claude\"" >> .living-docs.config
   echo "AI_PATH=\".claude\"" >> .living-docs.config
   echo "SPECS_PATH=\".claude/specs\"" >> .living-docs.config
   ```

3. **Copy Templates**
   ```bash
   cp -r "$adapter_dir/templates/"* "$temp_dir/"
   ```

4. **Apply Path Rewriting**
   ```bash
   rewrite_paths "$adapter_dir" "$temp_dir"
   ```

5. **Move to Final Location**
   ```bash
   mv "$temp_dir/"* "$project_root/$LIVING_DOCS_PATH/"
   ```

### Example Transformations

#### Before (BMAD template):
```markdown
# Task: Implement Authentication

Store the specification in `docs/specs/authentication.md`

Run the planning script:
```bash
cd docs && ./plan.sh
```
```

#### After (with .claude selection):
```markdown
# Task: Implement Authentication

Store the specification in `.claude/specs/authentication.md`

Run the planning script:
```bash
cd .claude && ./plan.sh
```
```

### Conflict Resolution

When multiple adapters want the same file:
```yaml
# adapters/spec-kit/path-map.yml
conflicts:
  - file: "memory/constitution.md"
    strategy: "merge"  # or "skip", "overwrite", "rename"
```

### Update Handling

During updates:
1. Detect current paths from `.living-docs.config`
2. Back up customized files
3. Apply new templates with same path rewriting
4. Restore customizations

### Testing Matrix

| Adapter | Default Path | .claude | .github | docs/ | Custom |
|---------|-------------|---------|---------|--------|--------|
| spec-kit | specs/ | ✓ | ✓ | ✓ | ✓ |
| bmad | docs/ | ✓ | ✓ | ✓ | ✓ |
| agent-os | .agent-os/ | ✓ | ✓ | ✓ | ✓ |
| aider | ./ | ✓ | ✓ | ✓ | ✓ |
| cursor | ./ | N/A | N/A | N/A | N/A |
| continue | ./ | N/A | N/A | N/A | N/A |

### Implementation Checklist

- [ ] Create rewrite_paths function
- [ ] Test macOS sed compatibility
- [ ] Test Linux sed compatibility
- [ ] Create path-map.yml for each adapter
- [ ] Update wizard.sh path selection UI
- [ ] Test all combinations
- [ ] Handle special characters in paths
- [ ] Document path variables for users

### Edge Cases

1. **Existing files**: Check before overwriting
2. **Symlinks**: Follow or preserve?
3. **Absolute paths**: Convert to relative
4. **Windows paths**: Future consideration
5. **Spaces in paths**: Proper quoting

## Decision

Implement dynamic path rewriting with dated specs structure. Start with lightweight adapters (aider, cursor) as proof of concept.