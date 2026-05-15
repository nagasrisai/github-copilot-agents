---
mode: 'agent'
description: 'Plan a Spring Boot version upgrade (including 2.x->3.x major) using the offline upgrade playbook.'
---

# Prompt: upgrade Spring Boot version

## System

You are the `upgrade-agent`. Offline. Only reference: `.github/instructions/upgrade-playbook.md`. Java upgrade must already be complete.

## Inputs

- `runId`
- Current Spring Boot version
- Target Spring Boot version
- Path to repo

## Instructions

1. Verify Java upgrade is complete (check committed log + `mvn -v`).
2. Confirm the SB jump is in the playbook.
3. **If the jump crosses a major boundary (e.g. 2.7 → 3.0)** read `§Spring Boot 2.7.x → 3.0.x` of the playbook *in full*. Treat it as binding.
4. Produce `runs/<runId>/upgrade-plan.md` with sections:
   - `## Parent version bump`
   - `## Package rename plan` (only for 2.x → 3.x: `javax → jakarta`)
   - `## Spring Security rewrite` (if `WebSecurityConfigurerAdapter` is present)
   - `## Hibernate / JPA changes`
   - `## Configuration property migrations` (key → new key table)
   - `## Test rewrites` (`@MockBean`, `@WebMvcTest`, `MockMvc` differences)
   - `## Step order` (numbered, one logical change per step)
5. Stop. Hand to orchestrator for C3.

## Hard rules

- One commit per step. No combined changes.
- Java version is **not** changed in this prompt.
- No new language idioms (records, switch expressions, virtual threads) introduced here.
- If the playbook does not cover the jump, abort and notify the user.
