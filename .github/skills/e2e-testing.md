# Skill: e2e-testing

What the `e2e-test-generator` agent knows how to do.

## Capabilities

- Enumerate controllers + endpoints from `@*Mapping` annotations.
- Build the per-class Testcontainers fixture (Postgres / Kafka / Redis as needed).
- Wire `AbstractE2EIT` base class if absent.
- Generate happy-path, validation-failure, not-found, and auth tests.
- Add Failsafe plugin config to `pom.xml` if missing.
- Stub external HTTP dependencies with WireMock containers.
- Produce a coverage matrix mapping endpoint → test class.

## Reference

`instructions/e2e-testing.md` defines the stack, layout, and conventions.

## Boundaries

- Never makes a real network call from a test.
- Never uses `Thread.sleep`, `@DirtiesContext` (unless required), or hard-coded ports.
- Never asserts implementation details (DB rows directly) when an API assertion is available.

## Outputs

- `src/test/java/**/e2e/*E2EIT.java`
- Optional `pom.xml` Failsafe plugin block
- `runs/<runId>/e2e-coverage.md`
