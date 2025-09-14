# Spec-Kit Integration Design

**Status**: PLANNED
**Started**: Sept 14, 2025
**Owner**: TBD

## Objective
Design and implement integration with GitHub Spec-Kit for seamless GitHub workflow integration.

## Success Criteria
- [ ] Integration strategy documented
- [ ] Sync mechanism for Spec-Kit updates
- [ ] Templates merge cleanly with Spec-Kit
- [ ] No duplication between systems
- [ ] Clear value add from integration

## Design Considerations

### Integration Options
1. **Git Submodule**: Track Spec-Kit as submodule
2. **Copy & Customize**: Import and modify Spec-Kit templates
3. **Generator Script**: Dynamically merge Spec-Kit with our templates
4. **Package Dependency**: npm/pip package with Spec-Kit

### Proposed Approach
Use generator script that:
- Fetches latest Spec-Kit version
- Merges with living-docs templates
- Allows version pinning
- Generates project-specific configuration

### Integration Points
- **GitHub Issues** → `bugs.md` → `docs/issues/`
- **PR Templates** → Reference `docs/contributing/`
- **Actions/Workflows** → Update `docs/current.md`
- **Community Health** → Link to internal docs

## Next Steps
1. Research Spec-Kit structure and update patterns
2. Create proof-of-concept generator
3. Test with example project
4. Document integration process

## Questions
- How often does Spec-Kit update?
- Can we contribute back improvements?
- Should integration be optional or default?