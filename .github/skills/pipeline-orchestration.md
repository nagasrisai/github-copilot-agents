---
name: pipeline-orchestration
description: 'Stage sequencing, state persistence under .aidlc/runs/<runId>/, resumability, and recovery patterns. Used by the orchestrator agent.'
owners: [orchestrator]
---

# Skill: Pipeline Orchestration

The capability to drive the eight-stage AIDLC pipeline from Jira ticket to merged PR.

## Knows How To

- Resolve a Jira ticket key to a run.
- Sequence the 8 agents in order: `jira-analyzer` → `architect` → `code-generator` → `test-generator` → `sonar-reviewer` → `nexus-scanner` → `code-reviewer` → `deployment-agent`.
- Persist each stage output to `.aidlc/runs/<run-id>/<stage>.json`.
- Enforce blocking gates (quality gate fail, critical CVE, critical review finding).
- Retry transient failures with exponential backoff.
- Halt and post a Jira comment on permanent failures.
- Emit structured events to the AIDLC dashboard API.

## Run Directory Layout

```
.aidlc/runs/<run-id>/
├── input.json                 # original orchestrator input
├── jira-analyzer.json
├── architect.json
├── code-generator.json
├── test-generator.json
├── sonar-reviewer.json
├── nexus-scanner.json
├── code-reviewer.json
├── deployment-agent.json
├── orchestrator.log
└── status.json                # final {status, failedStage, prUrl}
```

## Decision Gates

| After stage | Halt condition |
|---|---|
| jira-analyzer | `openQuestions.length > 0` and `--strict` flag set |
| architect | Pattern not in {mvc, hexagonal, event_driven, cqrs} |
| code-generator | `compilationStatus != "passed"` after 3 retries |
| test-generator | `actualCoverage < targetCoverage` after 5 iterations |
| sonar-reviewer | `qualityGate == "failed"` |
| nexus-scanner | `blockingVulnerabilities.length > 0` |
| code-reviewer | Any `critical` finding |

## Retry Policy

Transient = HTTP 5xx, timeout, MCP unreachable.

```
attempt 1 → wait 1s
attempt 2 → wait 4s
attempt 3 → wait 16s
attempt 4 → fail
```
