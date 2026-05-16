---
applyTo: '**/src/test/**/*.java'
description: 'JUnit 5 + Mockito unit testing conventions and the 90% line-coverage rule.'
---

# Testing Standards — AIDLC

## Coverage Target

**90% line coverage** measured by JaCoCo. The test-generator agent will iterate until met.

## Test Pyramid

| Layer | Tool | Volume |
|---|---|---|
| Unit | JUnit 5 + Mockito | 70% |
| Slice | `@WebMvcTest`, `@DataJpaTest` | 20% |
| Integration | Testcontainers + `@SpringBootTest` | 10% |

## Required Per Class

- **Controllers:** `@WebMvcTest`, mock service, cover every endpoint + every status code path.
- **Services:** Plain JUnit + Mockito, cover happy path + every branch + exception paths.
- **Repositories:** `@DataJpaTest` with H2 or Testcontainers Postgres, cover every custom query.
- **Entities:** Smoke test for equals/hashCode/toString contract (when overridden).

## Naming

```java
@Test
void shouldCreateOrder_whenInputIsValid() { ... }

@Test
void shouldThrowValidationException_whenAmountIsNegative() { ... }
```

## Assertions

- **AssertJ** for fluent assertions: `assertThat(...).isEqualTo(...)`.
- Never `assertTrue(true)` or comment-only test bodies.
- One logical assertion per test (multiple `assertThat` lines OK if they verify one outcome).

## Mocking Rules

- Mock collaborators only — never mock the system under test.
- Use `@Mock` + `@InjectMocks`, not manual mocking.
- Use `verify(...)` only when behavior is part of the contract — prefer state assertions.

## Forbidden

- `Thread.sleep(...)` in tests.
- Tests dependent on system clock without `Clock` injection.
- Tests touching real network / real DB without Testcontainers.
- `@Disabled` without a linked Jira ticket explaining why.

## JaCoCo Configuration (in `pom.xml`)

```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <executions>
    <execution><goals><goal>prepare-agent</goal></goals></execution>
    <execution>
      <id>report</id>
      <phase>test</phase>
      <goals><goal>report</goal></goals>
    </execution>
    <execution>
      <id>check</id>
      <goals><goal>check</goal></goals>
      <configuration>
        <rules>
          <rule>
            <element>BUNDLE</element>
            <limits>
              <limit>
                <counter>LINE</counter>
                <value>COVEREDRATIO</value>
                <minimum>0.90</minimum>
              </limit>
            </limits>
          </rule>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
```
