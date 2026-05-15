---
applyTo: '**'
description: 'Configuration and tool list for the SonarQube MCP server (localhost).'
---

# SonarQube MCP Configuration

The `sonarqube-mcp` server exposes SonarQube to Copilot CLI for scan orchestration and issue retrieval.

## Connection

Set in `~/.config/gh-copilot/mcp.json`:

```json
{
  "mcpServers": {
    "sonarqube-mcp": {
      "command": "npx",
      "args": ["-y", "@sonarqube/mcp-server"],
      "env": {
        "SONAR_HOST_URL": "${SONAR_HOST_URL}",
        "SONAR_TOKEN": "${SONAR_TOKEN}"
      }
    }
  }
}
```

Required environment variables:

| Var | Purpose |
|---|---|
| `SONAR_HOST_URL` | e.g. `https://sonarqube.example.com` |
| `SONAR_TOKEN` | User token with `Execute Analysis` + `Browse` permissions |

## Tools

| Tool | Purpose |
|---|---|
| `mcp__sonarqube__scan` | Trigger an analysis on a given project + branch |
| `mcp__sonarqube__quality_gate` | Get current quality gate status (`OK` / `ERROR` / `WARN`) |
| `mcp__sonarqube__issues` | List issues with filters (severity, type, status) |
| `mcp__sonarqube__metrics` | Coverage, duplications, complexity, technical debt |
| `mcp__sonarqube__measures` | Per-component metric values |

## Quality Profile

The AIDLC quality profile is `aidlc-java-strict`. Set per-project via:

```bash
curl -u "$SONAR_TOKEN:" -X POST \
  "$SONAR_HOST_URL/api/qualityprofiles/add_project" \
  -d "language=java&qualityProfile=aidlc-java-strict&project=<projectKey>"
```

## Quality Gate Definition (`aidlc-strict`)

| Metric | Operator | Threshold |
|---|---|---|
| New Coverage | < | 90% |
| Duplicated Lines (%) | > | 3% |
| Maintainability Rating | worse than | A |
| Reliability Rating | worse than | A |
| Security Rating | worse than | A |
| Security Hotspots Reviewed | < | 100% |
