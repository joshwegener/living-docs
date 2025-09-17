# agent-os Framework Rules

## Gate: PRODUCT_SPEC_FIRST
**Phase**: PLANNING
**Enforcement**: MANDATORY
**Condition**: Product spec must exist before implementation

Requirements:
- Create product overview in `.agent-os/product/`
- Define success metrics upfront
- Document user stories
- Specify acceptance criteria

Failure message: "VIOLATION: No product spec found. Create product overview first."

## Gate: AGENT_ARCHITECTURE
**Phase**: DESIGN
**Enforcement**: MANDATORY

agent-os requirements:
1. Design agents as autonomous units
2. Define clear agent boundaries
3. Document agent interactions
4. Specify agent capabilities

## Gate: STANDARDS_COMPLIANCE
**Phase**: IMPLEMENTATION
**Enforcement**: MANDATORY
**Condition**: Follow coding standards in `.agent-os/standards/`

Requirements:
- Follow language-specific standards
- Use approved patterns
- Maintain consistent style
- Document deviations with justification

Failure message: "VIOLATION: Code doesn't follow .agent-os/standards/"

## Workflow: agent-os Development

```bash
# 1. Create dated spec
./.agent-os/scripts/new-spec.sh "Feature Name"

# 2. Define product vision
cat > .agent-os/product/feature-overview.md << 'EOF'
# Feature Overview
## Vision
## Success Metrics
## User Stories
EOF

# 3. Design agents
cat > .agent-os/agents/feature-agent.md << 'EOF'
# Feature Agent
## Capabilities
## Boundaries
## Interactions
EOF

# 4. Implement with standards
# Follow .agent-os/standards/coding-standards.md

# 5. Track in living-docs
mv docs/active/feature.md docs/completed/$(date +%Y-%m-%d)-feature.md
```

## Agent Design Principles
- **Autonomy**: Agents operate independently
- **Clarity**: Clear inputs and outputs
- **Composability**: Agents combine for complex tasks
- **Observability**: Agents log their actions
- **Reliability**: Agents handle failures gracefully

## Standards Structure
```
.agent-os/
├── product/
│   ├── product-overview.md
│   └── success-metrics.md
├── standards/
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── documentation-standards.md
├── agents/
│   └── [agent-definitions]
└── scripts/
    └── new-spec.sh
```

## Integration with living-docs
- Specs in both .agent-os/ and docs/specs/
- Track agent development in docs/active/
- Document agent interactions
- Maintain standards through living-docs