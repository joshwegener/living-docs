# Spec 003: Documentation Optimization

## Problem
Current documentation system loads 3300+ tokens before any work begins, violating 2025 best practices for AI agent efficiency.

## Solution
Implement 3-layer architecture with dynamic context loading, reducing initial token load by 75%.

## Goals
1. Reduce initial token load from 3300 to 800 tokens
2. Achieve 80%+ KV-cache hit rate
3. Load only relevant documentation for current task
4. Maintain all existing gates and compliance checks

## Architecture

### Layer 1: Immutable Core (100 tokens)
- GATES.xml - Binary pass/fail checks only
- Never changes, enables KV-cache optimization

### Layer 2: Context Router (50 tokens)
- bootstrap.md becomes a router, not container
- Detects context and loads appropriate docs

### Layer 3: Dynamic Context (200 tokens)
- CONTEXT.md generated based on current work
- Includes only relevant information

### Layer 4: On-Demand Resources
- procedures/ - Loaded when specific tasks detected
- knowledge/ - Loaded for domain-specific work
- rules/ - Loaded only if framework active

## Implementation Phases

### Phase 1: Core Extraction
- Extract gates to GATES.xml
- Create MINIMAL.md for default context
- Test with existing bootstrap

### Phase 2: Router Pattern
- Convert bootstrap.md to router
- Implement conditional loading
- Create context detection

### Phase 3: Optimization
- Add metrics tracking
- Optimize information density
- Document patterns

## Success Metrics
- 75% reduction in initial tokens
- 10x cost reduction via caching
- No regression in task completion
- 2x faster initial response time