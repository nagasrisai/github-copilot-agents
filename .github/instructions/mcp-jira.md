# Jira MCP Configuration

The `jira-mcp` server exposes Jira Cloud / Data Center to Copilot CLI for ticket retrieval and status updates.

## Connection

```json
{
  "mcpServers": {
    "jira-mcp": {
      "command": "npx",
      "args": ["-y", "@atlassian/jira-mcp"],
      "env": {
        "JIRA_BASE_URL": "${JIRA_BASE_URL}",
        "JIRA_EMAIL": "${JIRA_EMAIL}",
        "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
      }
    }
  }
}
```

| Var | Purpose |
|---|---|
| `JIRA_BASE_URL` | e.g. `https://your-org.atlassian.net` |
| `JIRA_EMAIL` | Service account email |
| `JIRA_API_TOKEN` | Generated at https://id.atlassian.com/manage-profile/security/api-tokens |

## Tools

| Tool | Purpose |
|---|---|
| `mcp__jira__get_ticket` | Fetch a ticket by key — fields, description, AC, attachments |
| `mcp__jira__list_tickets` | Search via JQL |
| `mcp__jira__update_status` | Transition ticket (`To Do` → `In Progress` → `In Review` → `Done`) |
| `mcp__jira__add_comment` | Append a comment |
| `mcp__jira__link_pr` | Add a remote link to the GitHub PR |

## Status Mapping

AIDLC drives ticket status as follows:

| Pipeline event | Jira transition |
|---|---|
| `orchestrator` starts run | `To Do` → `In Progress` |
| Pipeline succeeds, PR opened | `In Progress` → `In Review` |
| PR merged | `In Review` → `Done` (handled by repo workflow) |
| Pipeline fails on quality gate | `In Progress` → `Blocked` |

## Required Custom Fields

Read by `jira-analyzer`:

| Field | Type | Use |
|---|---|---|
| Microservice | Single-select | Maps ticket to target service |
| Acceptance Criteria | Multi-line text | Parsed for AC bullets |
| Architecture Pattern (optional) | Single-select | Overrides architect default |
