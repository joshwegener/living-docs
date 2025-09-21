# Quick Bug Tracker

*One-liner bug capture - promote to docs/issues/ when investigation needed*

## 🔴 Critical
- [ ] Wizard.sh needs error handling for missing template files
- [ ] Paths with spaces break sed commands in scripts

## 🟡 High Priority
- [ ] Auto-detection sometimes misses Python projects without requirements.txt
- [ ] Wizard should validate DOCS_PATH before creating structure
- [ ] Adapter version mismatch: local versions (e.g., 2.0.0) don't match GitHub tags (e.g., v0.0.47) → [docs/issues/adapter-version-mismatch.md](../issues/adapter-version-mismatch.md)
- [ ] check-drift.sh incorrectly adds orphaned spec files as top-level entries instead of under their parent specs

## 🟢 Normal
- [ ] Better error messages when run outside project directory
- [ ] Sed commands not portable between macOS and Linux

## 🔵 Low Priority
- [ ] Add emoji support toggle for enterprise users
- [ ] Wizard color codes don't work in some terminals

## ✅ Completed
- [x] Universal Adapters implemented - all 6 frameworks working (Sept 21, 2025)
- [x] Spec-kit adapter complete with .claude/commands/ (Sept 21, 2025)
- [x] BMAD adapter implemented (Sept 21, 2025)
- [x] Agent OS adapter implemented (Sept 21, 2025)
- [x] Add --version flag to wizard.sh (Sept 21, 2025)
- [x] Spec-kit adapter respects AI choice for installation directories (Sept 21, 2025)
- [x] Setup scripts consolidated into wizard.sh (Sept 14, 2025)
- [x] Documentation repair system implemented (Sept 14, 2025)

---

*Format: `- [ ] Brief description of issue`*
*When issue needs investigation, create `docs/issues/priority-#-description.md`*
