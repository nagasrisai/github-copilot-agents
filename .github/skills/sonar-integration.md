---
name: sonar-integration
description: 'SonarQube MCP integration. Used by sonar-reviewer to scan, fetch issues, and evaluate the quality gate.'
owners: [sonar-reviewer]
mcp: sonarqube-mcp
---

# Skill: SonarQube Integration

The capability to drive SonarQube scans and triage results via the SonarQube MCP server.

## Knows How To

- Trigger an analysis via `mcp__sonarqube__scan`.
- Poll for completion and quality gate state.
- Fetch issues filtered by severity, type, component, status.
- Classify issues as `fix-required`, `auto-fixable`, `false-positive`, or `accept`.
- For known auto-fixable rule keys (e.g. `java:S1192`, `java:S1118`, `java:S1186`), generate the patch.
- Surface blockers to the orchestrator with sufficient context for human review.

## Auto-Fixable Rule Patterns

| Rule key | Description | Fix |
|---|---|---|
| `java:S1192` | Duplicate string literal | Extract to private constant |
| `java:S1118` | Utility class with public ctor | Make ctor private |
| `java:S1186` | Empty method | Add log statement or `throw UnsupportedOperationException` |
| `java:S2293` | Diamond operator missing | Use diamond `<>` |
| `java:S1481` | Unused local variable | Remove |

## Inputs Required

- `projectKey`
- `branch` (or `pullRequest`)
- `pipelineId` for traceability

## Outputs

- Quality gate status.
- Issue list with classifications.
- Blocking issue list.
- Auto-fix patches.

## See Also

`.github/instructions/mcp-sonarqube.md` for connection + tool reference.
