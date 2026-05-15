# End-to-End Testing for Spring Boot Microservices (Offline Reference)

Conventions for writing E2E tests that boot the full Spring context, run against real dependencies via Testcontainers, and exercise REST endpoints with RestAssured.

## Stack

| Concern | Library | Version |
|---|---|---|
| Test framework | JUnit 5 (Jupiter) | 5.10.x |
| Spring test support | `spring-boot-starter-test` | (managed by parent) |
| HTTP client | RestAssured | 5.4.x |
| Containers | Testcontainers (`postgresql`, `kafka`, `redis`, etc.) | 1.19.x |
| Assertions | AssertJ | 3.24.x |

## Required dependencies (already managed in Spring Boot parent unless noted)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>io.rest-assured</groupId>
    <artifactId>rest-assured</artifactId>
    <version>5.4.0</version>
    <scope>test</scope>
</dependency>
```

## Folder layout

```
src/test/java/
  com/example/orderservice/
    unit/         <- existing @Test JUnit unit tests
    integration/  <- slice tests (@WebMvcTest, @DataJpaTest)
    e2e/          <- full-context, container-backed E2E tests
      OrderCrudE2EIT.java
      OrderValidationE2EIT.java
      support/
        AbstractE2EIT.java
        PostgresExtension.java
```

E2E test class names end in `E2EIT` so the `failsafe` plugin picks them up via `*IT` and they run only in the integration phase.

## Base class

```java
package com.example.orderservice.e2e.support;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.TestInstance;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
public abstract class AbstractE2EIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("orders")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry r) {
        r.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        r.add("spring.datasource.username", POSTGRES::getUsername);
        r.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @LocalServerPort
    int port;

    @BeforeAll
    void configureRestAssured() {
        RestAssured.port = port;
        RestAssured.basePath = "/api/v1";
    }
}
```

## Test template

Every public REST endpoint must have:

1. One happy-path test.
2. One validation-failure test (400).
3. One not-found test where applicable (404).
4. One auth-failure test if the endpoint is secured (401 or 403).

```java
class OrderCrudE2EIT extends AbstractE2EIT {

    @Test
    void createOrder_returns201AndPersists() {
        Long id = given()
            .contentType(JSON)
            .body("""
                {"sku":"SKU-1","quantity":2}
                """)
        .when()
            .post("/orders")
        .then()
            .statusCode(201)
            .body("id", notNullValue())
            .extract().jsonPath().getLong("id");

        given().when().get("/orders/{id}", id)
        .then()
            .statusCode(200)
            .body("sku", equalTo("SKU-1"));
    }

    @Test
    void createOrder_withNegativeQuantity_returns400() {
        given()
            .contentType(JSON)
            .body("""
                {"sku":"SKU-1","quantity":-1}
                """)
        .when()
            .post("/orders")
        .then()
            .statusCode(400)
            .body("errors.quantity", notNullValue());
    }
}
```

## Conventions

1. **One container fixture per test class** — share via base class; do not start containers per method.
2. **Use Testcontainers reuse mode** (`testcontainers.reuse.enable=true` in `~/.testcontainers.properties`) for local speed; CI runs fresh.
3. **No `@DirtiesContext` unless absolutely necessary** — it forces a full Spring reload.
4. **Database is reset per test method** via `@Sql(scripts = "/cleanup.sql", executionPhase = BEFORE_TEST_METHOD)` or per-test transactional rollback (`@Transactional` on test class).
5. **Never use `Thread.sleep`** — use Awaitility for asynchronous assertions.
6. **No hard-coded ports.** `@LocalServerPort` + RestAssured.
7. **Test data builders, not fixtures.** Inline domain object builders in `e2e/support/` keep tests readable.

## Coverage rule for E2E

Unit-test coverage rule (90% line) measures only unit tests. E2E tests are **not** counted in the JaCoCo threshold but **every public REST endpoint** must have at least one E2E test. This is checked by `scripts/validate-config.sh` parsing controller mappings vs E2E test names.

## Failsafe wiring (pom.xml)

```xml
<plugin>
    <artifactId>maven-failsafe-plugin</artifactId>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
                <goal>verify</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <includes>
            <include>**/*E2EIT.java</include>
        </includes>
    </configuration>
</plugin>
```

Run E2E with `mvn -o -B verify`.
