# AIDLC for Spring Boot Microservices

**AI-Driven Development Lifecycle** — a Copilot CLI–powered system that turns Jira tickets into production-ready Spring Boot microservices with tests, quality gates, vulnerability scans, and reviews.

This `.github/` folder is the **deployable configuration** for the AIDLC system. Drop it into any repository to give GitHub Copilot CLI the agents, prompts, skills, and workflows needed to drive the full pipeline.

---

## Pipeline Overview

```
Jira Ticket
   │
   ▼
[1] Jira Analysis        →  extract requirements & acceptance criteria
[2] Architecture Review  →  pick patterns, dependencies, service boundaries
[3] Code Generation      →  Spring Boot 3.x source (controller/service/repo/entity/dto)
[4] Test Generation      →  JUnit 5 + Mockito targeting 90% line coverage
[5] SonarQube Scan       →  via SonarQube MCP — quality gate must pass
[6] Nexus IQ Scan        →  via Nexus MCP — block on critical CVEs
[7] Code Review          →  AI architect + security + performance review
[8] Deploy               →  open PR with full report
```

---

## Folder Layout

| Folder | Purpose |
|---|---|
| `agents/` | One markdown file per specialized AI agent (9 agents). Each defines role, inputs, outputs, tools, and guardrails. |
| `instructions/` | Cross-cutting rules: Java style, Spring Boot conventions, security baselines, testing standards. |
| `prompts/` | Reusable prompt templates invoked by agents (e.g. `generate-controller.prompt.md`). |
| `scripts/` | Helper shell scripts to run agents locally or in CI (`run-pipeline.sh`, `seed-jira.sh`). |
| `skills/` | Capability definitions — what each agent *knows how to do* (MCP wiring, JaCoCo parsing, etc.). |
| `workflows/` | GitHub Actions YAML to drive the pipeline on PR / push / Jira webhook. |
| `CODEOWNERS` | Path-based review ownership across the generated service. |
| `copilot-instructions.md` | Top-level Copilot CLI configuration — loaded automatically on every session. |

---

## Quick Start with Copilot CLI

```bash
# 1. Authenticate
gh auth login
gh extension install github/gh-copilot

# 2. Run the full AIDLC pipeline on a Jira ticket
gh copilot run aidlc:pipeline --ticket PROJ-1234

# 3. Run a single stage
gh copilot run aidlc:codegen     --ticket PROJ-1234
gh copilot run aidlc:tests       --service order-service --coverage 90
gh copilot run aidlc:sonar       --service order-service
gh copilot run aidlc:nexus       --service order-service
gh copilot run aidlc:review      --pr 42
```

All commands map to the workflows in `.github/workflows/` and orchestrate the agents in `.github/agents/`.

---

## MCP Servers Required

| MCP Server | Purpose | Config |
|---|---|---|
| `sonarqube-mcp` | Quality scans, issue retrieval, quality gate status | `instructions/mcp-sonarqube.md` |
| `nexus-iq-mcp` | Dependency vulnerability scanning, policy evaluation | `instructions/mcp-nexus.md` |
| `jira-mcp` | Ticket retrieval and status updates | `instructions/mcp-jira.md` |
| `github-mcp` | PR creation, branch management, status checks | built-in via `gh` CLI |

---

## Agents at a Glance

| Agent | Stage | Model | Specialization |
|---|---|---|---|
| `jira-analyzer` | 1 | gpt-4o | Requirement extraction, AC parsing |
| `architect` | 2 | gpt-4o | Patterns (hexagonal / MVC / CQRS), boundaries |
| `code-generator` | 3 | claude-sonnet-4.5 | Spring Boot 3.x, Java 21 |
| `test-generator` | 4 | claude-sonnet-4.5 | JUnit 5, Mockito, 90% coverage |
| `sonar-reviewer` | 5 | gpt-4o-mini | SonarQube MCP, issue triage |
| `nexus-scanner` | 6 | gpt-4o-mini | Nexus IQ MCP, CVE evaluation |
| `code-reviewer` | 7 | gpt-4o | Architecture, security, performance review |
| `deployment-agent` | 8 | gpt-4o-mini | PR open, branch protection, release notes |
| `orchestrator` | — | gpt-4o | Coordinates all agents, manages handoffs |

---

## Customization

Edit `copilot-instructions.md` to change global rules (Java version, Spring Boot version, coverage target).
Edit individual `agents/*.md` to retune any single agent's behavior.

---

## License

MIT — internal use.
