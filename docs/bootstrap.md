# Bootstrap Router - living-docs AI Context System

<!-- This is a ROUTER, not a container. It loads only what's needed. -->

## 🎯 Core Gates (Always Loaded)
**@docs/gates.xml** - Mandatory compliance checks (immutable, cache-optimized)
**FIRST GATE**: Run `./scripts/build-context.sh` before any work

## 📍 Current Context
**@docs/context.md** - Dynamic context (auto-generated, includes active tasks)
**@docs/current.md** - Project dashboard (loaded if full status needed)

## 🧭 Conditional Documentation Loading

### By Task Type
```yaml
testing:
  trigger: [.test.*, .spec.*, jest, vitest, pytest]
  load: @procedures/testing.md

git_operations:
  trigger: [git, commit, push, pull, merge]
  load: @procedures/git.md

shell_scripts:
  trigger: [.sh, bash, sed, awk]
  load: @knowledge/macos-linux.md

bug_fixing:
  trigger: [bugs.md, fix, debug, error]
  load: [@bugs.md, @knowledge/gotchas.md]
```

### By Framework (Auto-detected from .living-docs.config)
```yaml
spec-kit:
  load: @rules/spec-kit-rules.md

aider:
  load: @rules/aider-rules.md

cursor:
  load: @rules/cursor-rules.md

agent-os:
  load: @rules/agent-os-rules.md
```

### Default Context
**@docs/minimal.md** - Loaded when no specific context detected

## 📊 Quick Status Checks
```bash
./scripts/check-drift.sh        # Check documentation drift
./scripts/build-context.sh      # Update dynamic context
ls docs/active/                 # Current work items
grep "^- \[ \]" docs/bugs.md   # Open bugs
tail -5 docs/log.md            # Recent updates
```

## 🚀 Common Operations

### Starting Work
1. Run drift check: `./scripts/check-drift.sh`
2. Build context: `./scripts/build-context.sh`
3. Check active work: `ls docs/active/`
4. Load relevant docs based on task

### Creating Files
1. Create the file
2. Update `docs/current.md` immediately
3. Run drift check to verify

### Completing Tasks
1. Mark complete in tasks.md if exists
2. Move docs/active/* to docs/completed/
3. Update docs/log.md with timestamp
4. Run drift check

## 🔗 Full Documentation Map
- **Core System**: @docs/current.md
- **Procedures**: docs/procedures/*.md (loaded on-demand)
- **Knowledge**: docs/knowledge/*.md (loaded by domain)
- **Rules**: docs/rules/*.md (loaded by framework)
- **Specs**: specs/*/spec.md (loaded when active)

## 💡 Token Optimization
- Initial load: ~300 tokens (vs 3300 old system)
- Additional docs loaded only when needed
- Run `./scripts/token-metrics.sh` to see usage

---
*Bootstrap Router v2.0 - Dynamic context loading for 75% token reduction*