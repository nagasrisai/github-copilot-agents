---
skill: nexus-integration
owners: [nexus-scanner]
mcp: nexus-iq-mcp
---

# Skill: Nexus IQ Integration

The capability to evaluate dependency risk and generate remediation patches via the Nexus IQ MCP server.

## Knows How To

- Submit `pom.xml` for evaluation via `mcp__nexus__evaluate`.
- Poll report until `complete`.
- Extract CVEs grouped by severity (critical / high / medium / low).
- Identify policy violations.
- For each fixable CVE, query the recommended version and assess semver impact.
- Generate `pom.xml` patch snippets with safe upgrades.
- Detect license risks (GPL / AGPL / SSPL in proprietary projects).

## Severity → Action

| Severity | Has fix? | Action |
|---|---|---|
| critical | yes | Generate patch, block PR |
| critical | no | Surface for security team, block PR |
| high | yes | Generate patch, block PR |
| high | no | Warn, allow with sign-off |
| medium | any | Warn |
| low | any | Log only |

## Inputs Required

- `applicationId` (Nexus IQ application key)
- Path to `pom.xml`
- Pipeline ID

## Outputs

- Report URL.
- Vulnerability list with remediation paths.
- pom.xml patch snippets.
- License risk list.

## Failure Modes

- MCP unreachable → 3× retry, then fail loudly.
- Evaluation stuck > 10 min → fail with timeout, do not proceed.
- Unknown component (Nexus has no data) → log and continue.

## See Also

`.github/instructions/mcp-nexus.md`
