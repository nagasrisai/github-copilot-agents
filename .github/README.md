# AIDLC for Spring Boot Microservices

**AI-Driven Development Lifecycle** — a Copilot CLI–powered system that turns a Jira ticket (or an upgrade request) into a reviewed, scanned, tested, and shipped Pull Request — with explicit human checkpoints and **no internet dependency**.

This `.github/` folder is the deployable configuration. Drop it into any repository to give GitHub Copilot CLI the agents, prompts, skills, scripts, and workflows needed to drive the full pipeline.

---

## End-to-end flow (see `FLOW.md` for the full spec)

```
   Intake   Clone   [C2 Branch]   Analyze   [C3 Plan]   Code   Unit   E2E
     │        │         │            │         │          │      │     │
     ▼        ▼         ▼            ▼         ▼          ▼      ▼     ▼
   Sonar  →  Nexus  →  AI review  →  [C4 Approve]  →  Push  →  [C5 Target]  →  PR
```

Five human checkpoints (default: NO):

| # | When | What the user answers |
|---|---|---|
| C1 | Intake | `Run AIDLC on <ticket/upgrade>? [y/N]` |
| C2 | Branch | `Create branch '<name>' off '<base>'? [y/N]` |
| C3 | Plan | `Plan attached. Proceed? [y/N]` |
| C4 | Review | `Approve and push? [y/N]` |
| C5 | PR | `Target branch for PR? (e.g. main, develop)` |

---

## Folder layout

| Folder | Purpose |
|---|---|
| `FLOW.md` | Canonical end-to-end flow, stage specs, recovery matrix |
| `copilot-instructions.md` | Loaded automatically by Copilot CLI on every session |
| `CODEOWNERS` | Path-based review ownership for generated services |
| `agents/` | One markdown spec per specialized agent (12 agents) |
| `instructions/` | Offline knowledge base — Spring Boot, Java, JUnit, security, upgrade playbook, MCP wiring, checkpoint protocol |
| `prompts/` | Reusable prompt templates the agents invoke |
| `scripts/` | Bash drivers — `aidlc.sh`, `clone-and-branch.sh`, `request-review.sh`, `push-and-pr.sh`, `upgrade-precheck.sh`, `seed-jira.sh`, `validate-config.sh` |
| `skills/` | Capability summaries — what each agent knows how to do |
| `workflows/` | GitHub Actions YAML to drive the pipeline on PR / push / Jira webhook |

---

## Quick start

```bash
# 1. One-time setup (requires internet ONCE to seed local Maven repo)
.github/scripts/aidlc.sh bootstrap

# 2. Start an interactive run
.github/scripts/aidlc.sh start
#    -> asks: feature | bugfix | upgrade
#    -> asks: Jira ticket key or target Java / Spring Boot versions
#    -> asks: git URL of the target microservice repo
#    -> C1 confirm intake
#    -> clones repo (asks before clone)
#    -> C2 confirm branch creation
#    -> hands off to the orchestrator agent inside Copilot CLI

# 3. Resume an interrupted run
.github/scripts/aidlc.sh resume run-2026-05-15-001
```

The orchestrator agent (`agents/orchestrator.md`) takes over after stage 2 and drives stages 3-7 (analyze → code → unit tests → E2E → Sonar → Nexus → AI review). At stage 8 it calls `scripts/request-review.sh` for **C4**. On approval it calls `scripts/push-and-pr.sh` for **C5** and the final push + PR.

---

## Agents (12)

| Agent | Stage | Specialization |
|---|---|---|
| `orchestrator` | all | Coordinates agents, enforces checkpoints, owns run state |
| `repo-manager` | 1, 2, 9 | clone, branch, commit, push, PR — every git action |
| `jira-analyzer` | 0 | Requirement extraction, AC parsing (feature/bugfix only) |
| `architect` | 3 | Patterns, dependencies, service boundary |
| `code-generator` | 4 | Spring Boot 3.3 source (controller/service/repo/entity/dto) |
| `upgrade-agent` | 3, 4 | Java + Spring Boot version upgrades (Java 8→21, SB 2.x→3.3) |
| `test-generator` | 5 | JUnit 5 + Mockito, 90% line coverage |
| `e2e-test-generator` | 6 | Testcontainers + RestAssured, every endpoint covered |
| `sonar-reviewer` | 7a | SonarQube MCP triage, quality-gate enforcement |
| `nexus-scanner` | 7b | Nexus IQ MCP, critical-CVE blocker |
| `code-reviewer` | 7c | Architecture / security / performance review |
| `deployment-agent` | 9 | PR body composition, status labels |

---

## Offline mode

Every model in the pipeline operates **without internet access**. All reference material lives under `instructions/`. Maven runs with `-o`. MCP servers are local processes. See `instructions/offline-mode.md`.

---

## MCP servers (all on localhost)

| MCP Server | Purpose | Config |
|---|---|---|
| `sonarqube-mcp` | Quality scans, issue retrieval, quality gate | `instructions/mcp-sonarqube.md` |
| `nexus-iq-mcp` | Dependency vulnerability scanning | `instructions/mcp-nexus.md` |
| `jira-mcp` | Ticket retrieval and status updates | `instructions/mcp-jira.md` |
| `github-mcp` | PR creation, status checks (via `gh` CLI) | shipped with `gh` |

---

## Customization

- Change the global stack (Java/Spring Boot versions, coverage target): edit `copilot-instructions.md`.
- Retune a single agent: edit the matching file under `agents/`.
- Add a new upgrade path: extend `instructions/upgrade-playbook.md`. The `upgrade-agent` will refuse jumps not listed there.

---

## License

MIT — internal use.
