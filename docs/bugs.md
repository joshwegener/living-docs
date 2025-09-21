# Quick Bug Tracker

*One-liner bug capture - promote to docs/issues/ when investigation needed*

## 🔴 Critical
- [ ] Universal Adapters not implemented (framework exists but no actual adapters)
- [ ] Spec-kit adapter completely missing (no .claude/commands/)
- [ ] BMAD adapter not implemented
- [ ] Agent OS adapter not implemented
- [ ] Wizard.sh needs error handling for missing template files
- [ ] Paths with spaces break sed commands in scripts

## 🟡 High Priority
- [ ] Auto-detection sometimes misses Python projects without requirements.txt
- [ ] Wizard should validate DOCS_PATH before creating structure
- [ ] Adapter version mismatch: local versions (e.g., 2.0.0) don't match GitHub tags (e.g., v0.0.47) → [docs/issues/adapter-version-mismatch.md](../issues/adapter-version-mismatch.md)
- [ ] check-drift.sh incorrectly adds orphaned spec files as top-level entries instead of under their parent specs

## 🟢 Normal
- [ ] Add --version flag to wizard.sh
- [ ] Better error messages when run outside project directory
- [ ] Sed commands not portable between macOS and Linux

## 🔵 Low Priority
- [ ] Add emoji support toggle for enterprise users
- [ ] Wizard color codes don't work in some terminals

## ✅ Completed
- [x] Setup scripts consolidated into wizard.sh (Sept 14, 2025)
- [x] Documentation repair system implemented (Sept 14, 2025)

---

*Format: `- [ ] Brief description of issue`*
*When issue needs investigation, create `docs/issues/priority-#-description.md`*

- [ ] Update spec-kit adapter to install in AI-specific directories
- [ ] Research exact directory structures for Cursor, ChatGPT, Copilot
- [ ] Spec-kit adapter ignores AI choice (always installs to .claude/)
