# Archived Skills

This directory contains deprecated skills that have been consolidated or replaced.

## Purpose

Skills are moved here when they:
1. **Duplicate functionality** - Another skill provides the same capabilities
2. **Are superseded** - A newer skill or framework replaces them
3. **Follow framework pattern** - Generic framework skills now provide their functionality

## Archived Skills

| Skill | Archived Date | Replacement | Reason |
|-------|---------------|-------------|--------|
| `nextjs-complete-setup` | 2026-03-22 | `nextjs-standard-setup` | Redundant - was combination of standard-setup + tsdoc-documentor |
| `python-docstring-generator` | 2026-03-22 | `docstring-generator` | Redundant - generic skill already covers Python (PEP 257) |
| `nextjs-tsdoc-documentor` | 2026-03-22 | `docstring-generator` | Redundant - generic skill already covers TypeScript (TSDoc) |

## Framework Pattern

The repository now uses a framework pattern where generic skills provide core functionality:

- **`docstring-generator`** - Multi-language docstrings (Python, TypeScript, Java, C#)
- **`linting-workflow`** - Extended by `python-ruff-linter`, `javascript-eslint-linter`
- **`test-generator-framework`** - Extended by `python-pytest-creator`, `nextjs-unit-test-creator`

## Related Issues

- GitHub Issue #127 - Phase 1: Consolidate direct duplicate skills
- GitHub Issue #128 - Phase 2: Workflow overlaps
- GitHub Issue #129 - Phase 3: Code quality framework
- GitHub Issue #130 - Phase 4: Cleanup and synchronization
