---
applyTo: '**'
description: 'No-internet operating rules: all references local, Maven runs with -o, MCP servers on localhost.'
---

# Offline Mode

The AIDLC pipeline runs on AI models that **have no internet access**. Every fact, convention, or example the model needs must live inside `.github/instructions/`. The model must never be told to "search", "look up", or "fetch from the web".

## Rules

1. **All references are local.** When an agent needs a Spring Boot convention, a Java migration step, or a CVE remediation hint, it reads from this folder — not from the network.
2. **Maven runs in offline mode.** All Maven commands use `-o`. Dependencies must be pre-populated in `~/.m2/repository`. The bootstrap step (`scripts/aidlc.sh bootstrap`) runs `mvn -B dependency:go-offline` once when internet is available; from then on, Maven never reaches out.
3. **MCP servers are local processes.** SonarQube, Nexus IQ, and Jira MCP servers run on `localhost` against on-prem or in-network instances. Configure URLs in `.aidlc/config.env` — never use SaaS URLs in offline mode.
4. **No external tooling installs at run time.** All required binaries (`git`, `mvn`, `java`, `gh`, `jq`, MCP server binaries) are assumed pre-installed. If missing, the script halts with a clear error and an install hint — it does **not** attempt `apt-get` / `brew install`.
5. **No model self-grounding via web search.** Models are explicitly instructed: "You have no internet access. If you don't know, ask the user."
6. **Versions are pinned in this folder.** When this repo says Java 21 / Spring Boot 3.3.x, that **is** the truth — there is no fresher truth to consult.

## What lives where (offline knowledge base)

| Topic | File |
|---|---|
| Java style & idioms | `instructions/java-style.md` |
| Spring Boot 3.3.x conventions | `instructions/spring-boot.md` |
| JUnit 5 + Mockito patterns | `instructions/testing.md` |
| Testcontainers + RestAssured E2E | `instructions/e2e-testing.md` |
| Security baseline (Spring Security 6) | `instructions/security.md` |
| Java/Spring Boot upgrade matrix | `instructions/upgrade-playbook.md` |
| Human-in-the-loop checkpoint rules | `instructions/human-in-the-loop.md` |
| SonarQube MCP wiring | `instructions/mcp-sonarqube.md` |
| Nexus IQ MCP wiring | `instructions/mcp-nexus.md` |
| Jira MCP wiring | `instructions/mcp-jira.md` |

## Maven offline bootstrap

Run **once** on a machine with internet, before going offline:

```bash
mvn -B dependency:go-offline -Dmaven.test.skip=false
mvn -B dependency:resolve-plugins
```

Confirm offline-ready:

```bash
mvn -o -B validate
```

If this fails, the local repository is incomplete — fix before disconnecting.

## Why this matters

Without strict offline discipline, agents will hallucinate versions, invent CVEs, and propose dependency upgrades that don't exist in the local Maven mirror. Treat the `instructions/` folder as the **single source of truth**.
