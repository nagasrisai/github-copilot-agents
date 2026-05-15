# Java Style Guide — AIDLC Generated Services

Applies to all generated code under `**/src/main/java/`.

## Language Level

- **Java 21** — use records, pattern matching, sealed types, switch expressions, text blocks.
- No use of preview features.

## Naming

| Element | Convention | Example |
|---|---|---|
| Package | lowercase, dot-separated | `com.example.orderservice.controller` |
| Class | PascalCase | `OrderController` |
| Interface | PascalCase, no `I` prefix | `OrderRepository` |
| Method | camelCase, verb-first | `createOrder`, `findById` |
| Constant | UPPER_SNAKE | `MAX_RETRIES` |
| Field | camelCase | `orderRepository` |

## Patterns

- **Immutability by default.** Use `record` for DTOs, `final` for fields.
- **Constructor injection only.** Field injection is forbidden.
- **No null returns** for collections — return `List.of()` / `Optional.empty()`.
- **No checked exceptions** in new code — use `RuntimeException` subclasses or `Result` types.

## Forbidden

- Lombok (`@Data`, `@Builder`, etc.).
- Static singletons (`Holder` pattern). Use Spring DI.
- `System.out.println` — use SLF4J.
- Wildcard imports.
- `var` in public API signatures.

## Required

- `@Override` annotation on every override.
- Javadoc on every public method describing intent, params, return, throws.
- Explicit `package-info.java` per package documenting purpose.

## File Layout

```
src/main/java/com/example/<service>/
├── controller/        REST controllers
├── service/           Business logic
├── repository/        JPA repositories
├── entity/            JPA entities
├── dto/               Request/response records
├── mapper/            Entity ↔ DTO mappers
├── config/            Spring config classes
├── exception/         Custom exceptions + advice
└── Application.java   Spring Boot main class
```
