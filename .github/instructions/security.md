---
applyTo: '**/*.java'
description: 'Spring Security 6 baseline: SecurityFilterChain, input validation, parameterized queries, secret handling.'
---

# Security Baseline — AIDLC

Every AIDLC-generated service ships with this baseline. Departures require a documented exception in the PR description.

## Authentication & Authorization

- **Spring Security on every service** — never disabled.
- **JWT bearer auth** by default; resource server config via `oauth2ResourceServer().jwt(...)`.
- **Method-level authorization** with `@PreAuthorize` on every controller method (or class-level if uniform).
- **Public endpoints** must be explicitly whitelisted in the `SecurityFilterChain`.

## Secrets

- Never hard-coded in source.
- Read via `@ConfigurationProperties` from env vars: `${ENV_VAR_NAME}`.
- Never logged — sanitize via `org.springframework.boot.logging.LoggingSystem` masking patterns.

## Input Validation

- Every request DTO field annotated (`@NotNull`, `@Size`, `@Email`, `@Pattern`, `@Positive`).
- Controller params validated with `@Valid` / `@Validated`.
- Bean Validation errors caught by `GlobalExceptionHandler` → 400 with structured `ApiError`.

## Injection Defense

- **SQL:** JPA / JPQL only — no string concatenation, no native queries with user input.
- **HTML/JS:** `@RestController` only — no Thymeleaf / JSP rendering of user input.
- **OS commands:** forbidden in generated services.
- **Deserialization:** Jackson with `FAIL_ON_UNKNOWN_PROPERTIES = true`; no polymorphic deserialization without explicit type validators.

## Transport

- TLS 1.2+ enforced — no HTTP listeners.
- HSTS header in every response.
- CORS configured per service — no `*` origins in production.

## Headers (set via Spring Security)

```
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Referrer-Policy: no-referrer
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## Audit Logging

- Every authentication event logged with user ID, IP, user-agent, success/failure.
- Every write operation logged at INFO with actor + entity ID.
- Logs structured JSON via Logback `LogstashEncoder`.

## Dependency Posture

- Nexus IQ scan must pass with **zero critical CVEs** (see `agents/nexus-scanner.md`).
- Dependabot enabled on every generated repo.
- Quarterly dependency refresh enforced via scheduled workflow.
