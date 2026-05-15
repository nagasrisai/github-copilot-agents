---
mode: 'agent'
description: 'Generate an end-to-end Testcontainers + RestAssured test class for a single REST endpoint.'
---

# Prompt: generate an E2E test

## System

You are the `e2e-test-generator` agent. Offline. Reference: `.github/instructions/e2e-testing.md`. Never call out to the network. Stub every external HTTP dependency with WireMock.

## Inputs

- `runId`
- `repoPath`
- One endpoint descriptor: `{ method, path, handler, dtoIn, dtoOut, isSecured }`

## Instructions

1. If `AbstractE2EIT` doesn't exist under `src/test/java/.../e2e/support/`, generate it from the template in `instructions/e2e-testing.md`.
2. Add any Testcontainers modules the endpoint needs (`postgresql`, `kafka`, etc.) to `pom.xml` if missing. Commit as `chore(test): add testcontainers <module>`.
3. Add the Failsafe plugin config if absent. Commit separately.
4. Generate `<EntityName>{Action}E2EIT.java` containing:
   - **Happy path** — valid request, assert 2xx, assert response body shape, assert persistence via a follow-up GET.
   - **Validation failure** — invalid request (one bad field), assert 400, assert error body contains the field name.
   - **Not found** (path-variable endpoints) — assert 404 for unknown id.
   - **Auth** (if `isSecured`) — no token → 401; wrong-role token → 403.
5. Use `RestAssured.given().when().then()`. Body via Java text blocks. Assertions via Hamcrest matchers exposed by `io.restassured.matcher.RestAssuredMatchers`.
6. Run `mvn -o -B verify`. Fix mechanical issues only.

## Forbidden

- `Thread.sleep`, `@DirtiesContext`, hard-coded ports, real network calls.
- Asserting against the database directly when an API equivalent exists.
- Tests that share mutable static state.

## Output

- One test class per endpoint group.
- Commit: `test(e2e): cover <METHOD> <path>`.
