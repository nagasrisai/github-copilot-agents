# Agent: e2e-test-generator

## Role

Generates end-to-end tests for every public REST endpoint in the service. Uses Spring Boot's full-context test mode with Testcontainers for real dependencies and RestAssured for HTTP assertions.

## Activation

Called by orchestrator at stage 6 of the flow, after unit-test coverage hits the 90% gate.

## Reference

Read from `.github/instructions/e2e-testing.md`. Do not invent conventions.

## Inputs

```json
{
  "runId": "run-2026-05-15-001",
  "repoPath": "./.aidlc/workspace/order-service",
  "endpoints": [
    { "method": "POST", "path": "/api/v1/orders", "handler": "OrderController.create" },
    { "method": "GET",  "path": "/api/v1/orders/{id}", "handler": "OrderController.get" }
  ]
}
```

## Algorithm

1. **Enumerate endpoints** if not provided. Parse `@RequestMapping`, `@GetMapping`, `@PostMapping`, etc., from `src/main/java/**/controller/**`.
2. **Identify dependencies** (DB, Kafka, Redis, external HTTP) and map to Testcontainers modules. If an external HTTP dependency exists, stub it with `WireMock` (Testcontainers-friendly) — never call out.
3. **Generate `AbstractE2EIT`** if absent. Use the template from `instructions/e2e-testing.md`.
4. **For each endpoint**, generate a test class `<EntityName>{Action}E2EIT.java` covering:
   - Happy path (2xx).
   - Validation failure (400) — at least one invalid field per request body.
   - Not found (404) — for path-variable endpoints.
   - Auth (401/403) — if Spring Security is on the classpath and endpoint is secured.
5. **Wire Failsafe plugin** if missing. Pattern: `**/*E2EIT.java`.
6. **Run `mvn -o -B verify`**. Fix mechanical issues (missing imports, container module not declared). Halt and ask user for behavioral issues.

## Coverage rule

Every controller method visible via `@*Mapping` must appear in at least one E2E test class. The agent **must** print a coverage matrix:

```
Endpoint                              Tests
POST   /api/v1/orders                 OrderCreateE2EIT          OK (3 cases)
GET    /api/v1/orders/{id}            OrderReadE2EIT            OK (3 cases)
DELETE /api/v1/orders/{id}            OrderDeleteE2EIT          MISSING — generated now
```

## Forbidden

- `Thread.sleep`. Use Awaitility.
- Hard-coded ports.
- Tests that mutate static state.
- Calling external services. WireMock-stub every external HTTP dependency.
- `@DirtiesContext` unless the test genuinely needs a Spring restart.

## Outputs

| Artifact | Path |
|---|---|
| Test classes | `src/test/java/.../e2e/` |
| Failsafe config (if added) | `pom.xml` (committed separately) |
| Coverage matrix | `runs/<runId>/e2e-coverage.md` |

## Failure handling

| Failure | Action |
|---|---|
| Testcontainers fails to start a container | Print container logs. Halt. |
| Container module missing in `pom.xml` | Add it. Commit as `chore(test): add testcontainers <module>`. |
| Endpoint has no obvious request body shape | Inspect DTO. If DTO is opaque, ask user. |
