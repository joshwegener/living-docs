# Ideas Backlog

*One-liner idea capture - expand to specs when ready to implement*

## 🚀 Features
- [ ] **Command namespace prefixing**: Prefix adapter commands with adapter name (e.g., `speckit_implement.md`) to avoid overwriting user commands
  - spec-kit needs prefixing (currently uses generic names like implement.md, plan.md)
  - BMAD already prefixes their commands (bmad-plan.md, etc.)
  - Need to check other adapters for conflicts
  - Consider making prefix optional/configurable per adapter
- [ ] **Claude Agents support**: Add support for `.claude/agents/` directory installation
  - Detect and install agent templates from adapters
  - Similar to command installation but for agent definitions
  - Track in manifest for updates/removal
- [ ] Add adapter removal/uninstall feature to wizard (tracks custom directories, cleans up completely)
- [ ] **URGENT**: Safer adapter installation: clone to ./tmp/<adapter-name>/, grep for hardcoded paths, sed to rewrite, move files, rm -rf ./tmp/
  - spec-kit v0.0.47 has "scripts/bash/" paths in commands/*.md that break with custom SCRIPTS_PATH
  - Need to rewrite: scripts/bash/ → {{SCRIPTS_PATH}}/bash/ in all command files
  - Also check: memory paths, spec paths, any .spec references
- [ ] Path validation: scan upstream repos for hardcoded paths (like .spec) that need rewriting for custom dirs
- [ ] Adapter update detection: diff current vs upstream, show what changed, smart merge preserving path rewrites
- [ ] Convert more docs to XML format for 5x information density (procedures, knowledge, rules)
- [ ] Auto-generate current.md from directory structure
- [ ] GitHub Actions for daily spec-kit updates
- [ ] VSCode extension for living-docs navigation
- [ ] Web dashboard for documentation visualization
- [ ] AI chat interface for querying project docs
- [ ] Automatic PR description generation from completed tasks
- [ ] Integration with Notion/Obsidian for cross-platform docs
- [ ] Docker container with pre-configured living-docs
- [ ] CLI tool for quick operations (ld add-bug, ld complete-task)
- [ ] Automated documentation health scoring
- [ ] Integration with JIRA/Linear/Asana
- [ ] Multi-language support for global teams
- [ ] Documentation versioning tied to git tags
- [ ] Automatic changelog generation from completed tasks

## 🔧 Improvements
- [ ] Reduce bootstrap.md bloat - move non-critical sections to linked docs (under 200 lines)
- [ ] Wizard should remember previous choices
- [ ] Add undo/rollback functionality
- [ ] Create living-docs doctor command for health checks
- [ ] Add documentation linting rules
- [ ] Support for monorepos with multiple projects
- [ ] Template marketplace for different project types

## 🎯 Strategic
- [ ] Create living-docs certification program
- [ ] Build community contributors program
- [ ] Partner with AI companies for official integration
- [ ] Create enterprise support tier
- [ ] Develop metrics/analytics for documentation usage

---
*When ready to implement, move to docs/active/ with full spec*