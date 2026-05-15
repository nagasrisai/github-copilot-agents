---
skill: spring-boot-codegen
owners: [code-generator]
---

# Skill: Spring Boot Code Generation

The capability to scaffold a complete Spring Boot 3.x microservice from a structured architecture spec.

## Knows How To

- Generate Maven project layout (`pom.xml`, `src/main/java`, `src/main/resources`, `src/test/java`).
- Author controllers, services, repositories, entities, DTOs, mappers, config classes, exception handlers.
- Wire Spring Security with JWT resource server defaults.
- Configure Flyway migrations from the architect's entity spec.
- Generate `application.yml` per profile (`dev`, `test`, `staging`, `prod`).
- Validate by running `mvn -q compile` and iterating on errors.

## Inputs Required

- Architecture spec (output of `architect` agent).
- Microservice name in kebab-case.
- Base package (default `com.example.<service-name-camel>`).

## Outputs

- File tree under `<microservice>/`.
- `pom.xml` with explicit dependency list.
- Compilation report.

## Standards Enforced

See:
- `.github/instructions/java-style.md`
- `.github/instructions/spring-boot.md`
- `.github/instructions/security.md`

## Prompt Templates Used

- `.github/prompts/generate-controller.prompt.md`
- `.github/prompts/generate-service.prompt.md`
- `.github/prompts/generate-entity.prompt.md`

## Failure Modes

- Compilation fails → retry with error context up to 3×.
- Dependency conflict → surface to orchestrator, do not auto-resolve.
- Ambiguous architecture spec → return to architect with `openQuestions`.
