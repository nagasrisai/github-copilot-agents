# Spring Boot Conventions — AIDLC

## Version

- Spring Boot **3.3.x**
- Spring Framework 6.1.x
- Jakarta EE 10 (`jakarta.*` imports, never `javax.*`)

## Controllers

- Annotate with `@RestController` (not `@Controller`).
- Base path: `/api/<service-name>` defined via `@RequestMapping`.
- Each method declares its full path and HTTP verb explicitly.
- Request bodies validated with `@Valid`.
- Return `ResponseEntity<T>` for non-200 paths; otherwise return the DTO directly.

```java
@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final OrderService service;

    public OrderController(OrderService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public OrderDto create(@Valid @RequestBody CreateOrderRequest request) {
        return service.create(request);
    }
}
```

## Services

- `@Service` + `@Transactional` at class level for write-heavy services.
- Read-only methods annotated with `@Transactional(readOnly = true)`.
- No persistence calls from controllers.

## Repositories

- Extend `JpaRepository<Entity, ID>`.
- Custom queries via `@Query` JPQL — never raw SQL unless absolutely necessary.

## Entities

- `@Entity` + explicit `@Table(name = "...")`.
- `@Id @GeneratedValue(strategy = GenerationType.IDENTITY)`.
- `@Version` for optimistic locking on aggregate roots.
- Audit columns (`createdAt`, `updatedAt`) via `@EntityListeners(AuditingEntityListener.class)`.

## Exception Handling

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ApiError> notFound(EntityNotFoundException ex) {
        return ResponseEntity.status(NOT_FOUND).body(new ApiError("NOT_FOUND", ex.getMessage()));
    }
}
```

## Configuration

- Use `@ConfigurationProperties` records for typed config — no `@Value`.
- Profiles: `dev`, `test`, `staging`, `prod` in `application-<profile>.yml`.

## Observability

- Micrometer + OpenTelemetry auto-config enabled.
- Every service exposes `/actuator/health`, `/actuator/metrics`, `/actuator/prometheus`.
- Custom counters via `MeterRegistry` injection.

## Required Dependencies (baseline `pom.xml`)

```
spring-boot-starter-web
spring-boot-starter-data-jpa
spring-boot-starter-validation
spring-boot-starter-actuator
spring-boot-starter-security
micrometer-registry-prometheus
io.opentelemetry:opentelemetry-spring-boot-starter
org.flywaydb:flyway-core
org.postgresql:postgresql
spring-boot-starter-test (test scope)
org.testcontainers:postgresql (test scope)
```
