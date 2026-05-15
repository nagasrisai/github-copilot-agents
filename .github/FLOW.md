# AIDLC End-to-End Flow

The canonical step-by-step flow every Copilot CLI session must follow when working on a Spring Boot microservice. Each stage has explicit **inputs**, **outputs**, **agent owner**, and **human checkpoint** if required.

> **Offline assumption.** Every model in this pipeline runs without internet access. All reference material must come from `.github/instructions/`. Never instruct the model to "look it up" — embed the knowledge.

---

## Pipeline at a Glance

```
                                              human checkpoint
                                                     │
┌────────┐  ┌────────┐  ┌──────────┐  ┌─────────┐    ▼     ┌─────────┐
│ Jira / │→ │ Clone  │→ │  Branch  │→ │ Analyze │→ [USER]→ │ Plan &  │
│Upgrade │  │  Repo  │  │ (ask Y/N)│  │ codebase│         │ Approve │
│ Ticket │  └────────┘  └──────────┘  └─────────┘         └────┬────┘
└────────┘                                                     │
                                                               ▼
   ┌────────────────────┐  ┌─────────┐  ┌──────────┐  ┌────────────┐
   │ Generate / Modify  │← │  Unit   │← │   E2E    │← │  Coverage  │
   │  Spring Boot code  │  │  Tests  │  │  Tests   │  │   ≥ 90%    │
   └────────────────────┘  └─────────┘  └──────────┘  └─────┬──────┘
                                                            │
                                                            ▼
       ┌─────────┐    ┌─────────┐    ┌──────────┐    ┌─────────────┐
       │ Sonar   │───→│ Nexus   │───→│ Internal │───→│ HUMAN REVIEW│
       │ MCP scan│    │ IQ MCP  │    │ AI review│    │   [USER]    │
       └─────────┘    └─────────┘    └──────────┘    └──────┬──────┘
                                                            │
                                                            ▼
                                       ┌────────────────────────────┐
                                       │ Push branch + raise PR     │
                                       │ (USER provides target br.) │
                                       └────────────────────────────┘
```

---

## Stage Specifications

### Stage 0 — Intake

| Field | Value |
|---|---|
| Agent | `orchestrator` |
| Input | Jira key **OR** "upgrade request" (target Java/Spring Boot version) |
| Output | Run context envelope `{ runId, kind: "feature" \| "upgrade" \| "bugfix", ticket?, upgradeTarget? }` |
| Human checkpoint | Print intent to user. Wait for `[y/N]` confirm before proceeding. |
| Script | `scripts/aidlc.sh start` |

---

### Stage 1 — Clone repo

| Field | Value |
|---|---|
| Agent | `repo-manager` |
| Input | Git URL (HTTPS or SSH) — provided by user |
| Output | Local checkout at `./.aidlc/workspace/<repo-name>/` |
| Human checkpoint | Ask user for repo URL + confirm clone path before cloning. |
| Script | `scripts/clone-and-branch.sh clone <url>` |

---

### Stage 2 — Branch

| Field | Value |
|---|---|
| Agent | `repo-manager` |
| Branch naming | `aidlc/<TICKET-KEY>-<kebab-title>` for features, `aidlc/upgrade-<from>-to-<to>` for upgrades |
| Human checkpoint | **MANDATORY.** Print proposed branch name and ask `Create branch '<name>' off '<base>'? [y/N]`. Abort on any answer other than `y` / `yes`. |
| Script | `scripts/clone-and-branch.sh branch <name> <base>` |

---

### Stage 3 — Analyze codebase

| Field | Value |
|---|---|
| Agent | `architect` for features, `upgrade-agent` for upgrades |
| Output | `.aidlc/runs/<runId>/analysis.md` — current state, target state, impacted files |
| Tools | Local file walk, `mvn dependency:tree -o` (offline-mode Maven), `git log` |
| Human checkpoint | Present the analysis. Ask `Proceed with this plan? [y/N]`. |

---

### Stage 4 — Generate or modify code

| Field | Value |
|---|---|
| Agent | `code-generator` (features/bugfixes) or `upgrade-agent` (upgrades) |
| Reference | `instructions/spring-boot.md`, `instructions/java-style.md`, `instructions/upgrade-playbook.md` |
| Output | Modified Java source under `src/main/java/**`, `pom.xml` deltas |
| Commit | One commit per logical change. Conventional Commits. |
| Human checkpoint | None during edits — review happens in Stage 8. |

---

### Stage 5 — Unit tests (JUnit 5)

| Field | Value |
|---|---|
| Agent | `test-generator` |
| Target | **≥ 90% line coverage** (JaCoCo) |
| Output | `src/test/java/**` |
| Loop | Generate → run `mvn -o test jacoco:report` → if coverage < 90%, regenerate until met or 5 iterations elapse |

---

### Stage 6 — E2E tests

| Field | Value |
|---|---|
| Agent | `e2e-test-generator` |
| Stack | Testcontainers + RestAssured + Spring Boot Test (`@SpringBootTest(webEnvironment = RANDOM_PORT)`) |
| Coverage | Every public REST endpoint must have at least one happy-path and one failure-path E2E test |
| Output | `src/test/java/**/e2e/**` |
| Reference | `instructions/e2e-testing.md` |

---

### Stage 7 — Static + supply-chain scans

Run in this order. Each is blocking.

1. **SonarQube** (`sonar-reviewer`, MCP) — quality gate must be `PASSED`, zero BLOCKER / CRITICAL.
2. **Nexus IQ** (`nexus-scanner`, MCP) — zero `critical`-severity policy violations.
3. **Internal AI review** (`code-reviewer`) — produces `review.md` with categorized findings.

Output: `.aidlc/runs/<runId>/scans/{sonar.json,nexus.json,review.md}`.

---

### Stage 8 — Human review

| Field | Value |
|---|---|
| Owner | **Human user.** This is the most important checkpoint. |
| What is shown | Concise summary: changed files, line counts, coverage report, Sonar gate, Nexus verdict, AI review highlights, full `git diff --stat`. |
| Prompts | `Show full diff? [y/N]`, then `Approve and push? [y/N]`. |
| If rejected | Capture user feedback. Loop back to Stage 4 with the feedback as new context. Max 3 iterations. |
| Script | `scripts/request-review.sh` |

---

### Stage 9 — Push + Pull Request

| Field | Value |
|---|---|
| Agent | `repo-manager` + `deployment-agent` |
| Pre-push | Verify working tree clean, all commits signed-off, branch ahead of base. |
| Push | `git push -u origin <branch>` |
| Human checkpoint | **MANDATORY.** Ask `Target branch for PR? (default: main)`. Use user's answer. Never default silently. |
| PR creation | `gh pr create --base <target> --head <branch> --title <conv-commit> --body <generated>` |
| PR body source | `prompts/pr-body.prompt.md` rendered with run context, scan results, coverage, and AI review summary. |
| Script | `scripts/push-and-pr.sh` |

---

## Non-negotiables

1. **No silent decisions.** Branch creation, target branch for PR, and push approval all require explicit user input.
2. **No internet calls.** Every reference fact lives in `.github/instructions/`. Maven runs with `-o` (offline). MCP servers run on localhost.
3. **No fabricated output.** If an MCP server is unreachable or Maven fails, halt and surface the error verbatim.
4. **Resumable.** Every stage writes its output to `.aidlc/runs/<runId>/`. Re-running `aidlc.sh resume <runId>` picks up at the last successful stage.
5. **Idempotent.** Re-running a stage must not duplicate commits, branches, or PRs.

---

## Failure modes & recovery

| Failure | Recovery |
|---|---|
| Clone fails (auth) | Surface error. Ask user for token/SSH key path. |
| Branch already exists | Ask user: reuse, rename, or abort. |
| Coverage below 90% after 5 iterations | Halt. Print missing-coverage report. Ask user how to proceed. |
| Sonar gate FAIL | Run `sonar-reviewer` triage prompt. Apply fixes. Re-scan. Max 3 attempts. |
| Nexus critical CVE | Halt. Print CVE list + suggested dependency upgrades. Ask user to approve upgrades. |
| User rejects review | Capture rejection reason. Treat as new requirement. Loop to Stage 4. |
| Push rejected (non-fast-forward) | `git fetch && git rebase origin/<base>`. Re-run tests. Re-request review. |

---

## Reference

- Agent specs: `.github/agents/`
- Instructions (offline knowledge base): `.github/instructions/`
- Prompt templates: `.github/prompts/`
- Scripts: `.github/scripts/`
- Skills (capabilities): `.github/skills/`
