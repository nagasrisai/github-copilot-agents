---
name: java-upgrade
description: 'Java and Spring Boot version upgrades via the offline upgrade playbook. Mechanical rewrites only.'
---

# Skill: java-upgrade

What the `upgrade-agent` knows how to do for Java + Spring Boot version migrations.

## Capabilities

- Parse `pom.xml` and extract current Java + Spring Boot versions.
- Walk imports across `src/main/java/**` and `src/test/java/**`.
- Apply mechanical rewrites from the playbook (`javax → jakarta`, `WebSecurityConfigurerAdapter → SecurityFilterChain`, property key migrations).
- Map deprecated API to replacement API (Spring Boot 2.x → 3.x).
- Run `mvn -o -B clean compile` + `mvn -o -B test` after every step.
- Produce per-step commits with Conventional Commits.
- Generate a before/after dependency tree and a compatibility report.

## Reference

`instructions/upgrade-playbook.md` is the only source of truth for which transformations are allowed at which version jump.

## Boundaries

- Never adopts new language features as part of an upgrade.
- Never changes business behavior.
- Never disables tests.
- Halts and asks the user when the playbook doesn't cover the requested jump.

## Outputs

- `upgrade-plan.md`
- `upgrade-report.md`
- `before-deps.txt`, `after-deps.txt`
- per-step git commits on the working branch
