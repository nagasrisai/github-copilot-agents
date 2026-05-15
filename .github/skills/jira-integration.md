---
skill: jira-integration
owners: [jira-analyzer, orchestrator, deployment-agent]
mcp: jira-mcp
---

# Skill: Jira Integration

The capability to read Jira tickets, parse acceptance criteria, and drive ticket status across the pipeline.

## Knows How To

- Fetch a ticket via `mcp__jira__get_ticket` and parse fields, custom fields, attachments.
- Parse acceptance criteria from a multi-line text field — supports bullet, numbered, and Given-When-Then formats.
- Detect target microservice from the `Microservice` custom field, labels, or component values.
- Transition ticket status via `mcp__jira__update_status`.
- Add comments with pipeline run summaries via `mcp__jira__add_comment`.
- Link the GitHub PR via `mcp__jira__link_pr`.

## AC Parsing Heuristics

1. Look for the `Acceptance Criteria` custom field first.
2. Fall back to description sections headed `Acceptance Criteria`, `AC:`, or `## AC`.
3. Split on:
   - Bullets (`- `, `* `, `• `)
   - Numbered lists (`1.`, `1)`)
   - `Given ... When ... Then ...` blocks (kept as single AC)
4. Strip surrounding whitespace and trailing periods.
5. Drop blank lines and headers.

## Status Transitions Driven

| Trigger | Transition |
|---|---|
| Orchestrator run start | `To Do` → `In Progress` |
| Pipeline success → PR opened | `In Progress` → `In Review` |
| Pipeline failure (quality gate / CVE / review) | `In Progress` → `Blocked` |

The `In Review` → `Done` transition is handled by the repository's PR-merge workflow, not by AIDLC.

## See Also

`.github/instructions/mcp-jira.md`
