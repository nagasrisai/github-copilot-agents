---
applyTo: '**'
description: 'Configuration and tool list for the Nexus IQ MCP server (localhost).'
---

# Nexus IQ MCP Configuration

The `nexus-iq-mcp` server exposes Sonatype Nexus IQ to Copilot CLI for dependency vulnerability and policy evaluation.

## Connection

```json
{
  "mcpServers": {
    "nexus-iq-mcp": {
      "command": "npx",
      "args": ["-y", "@sonatype/nexus-iq-mcp"],
      "env": {
        "NEXUS_IQ_URL": "${NEXUS_IQ_URL}",
        "NEXUS_IQ_USER": "${NEXUS_IQ_USER}",
        "NEXUS_IQ_TOKEN": "${NEXUS_IQ_TOKEN}",
        "NEXUS_IQ_STAGE": "build"
      }
    }
  }
}
```

Required environment variables:

| Var | Purpose |
|---|---|
| `NEXUS_IQ_URL` | e.g. `https://nexus-iq.example.com` |
| `NEXUS_IQ_USER` | Service account username |
| `NEXUS_IQ_TOKEN` | User token |
| `NEXUS_IQ_STAGE` | `build`, `stage-release`, or `release` |

## Tools

| Tool | Purpose |
|---|---|
| `mcp__nexus__evaluate` | Trigger a policy evaluation against a `pom.xml` or build artifact |
| `mcp__nexus__report` | Fetch a completed evaluation report by ID |
| `mcp__nexus__policy_violations` | List policy violations grouped by severity |
| `mcp__nexus__component_details` | Lookup CVE / license / occurrence data for a single component |
| `mcp__nexus__waivers` | List or request policy waivers |

## Severity Mapping

The MCP returns severity scores 0–10. AIDLC maps them as follows:

| Score | Severity | Pipeline action |
|---|---|---|
| 9.0 – 10.0 | `critical` | **Block PR** |
| 7.0 – 8.9  | `high`     | Block PR if a fix exists; warn otherwise |
| 4.0 – 6.9  | `medium`   | Warn |
| 0.1 – 3.9  | `low`      | Log only |

## Policy

The AIDLC policy is `aidlc-default`:

- Block on any unfixed `critical` CVE.
- Block on any new `high` CVE introduced by this PR.
- Block on GPL / AGPL / SSPL license in proprietary projects.
- Warn on copyleft licenses (LGPL, MPL).
