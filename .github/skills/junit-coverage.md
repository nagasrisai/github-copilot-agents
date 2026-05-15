---
skill: junit-coverage
owners: [test-generator]
---

# Skill: JUnit 5 + JaCoCo Coverage Targeting

The capability to drive a Spring Boot test suite to ≥ 90% line coverage via iterative test generation.

## Knows How To

- Author JUnit 5 + Mockito tests against controllers, services, repositories, mappers.
- Use `@WebMvcTest`, `@DataJpaTest`, `@SpringBootTest`, Testcontainers correctly.
- Run `mvn -q test jacoco:report`.
- Parse `target/site/jacoco/jacoco.csv` and `jacoco.xml`.
- Identify uncovered lines and branches per class.
- Generate additional tests targeting uncovered branches.
- Detect untestable code (e.g., private constructors of utility classes) and mark as excluded.

## Iteration Loop

1. Generate initial test suite from source.
2. Run tests + JaCoCo.
3. If line coverage < target:
   - For each class below target, list uncovered branches.
   - Generate one new test per uncovered branch.
   - Goto step 2.
4. Cap at 5 iterations; surface unreachable branches.

## Inputs Required

- Generated source tree.
- Target coverage (default 90).
- Codegen run ID for traceability.

## Outputs

- `src/test/java/...` test files.
- JaCoCo report.
- Iteration count and final coverage %.

## Forbidden

- Reducing the target to pass.
- Excluding classes from coverage without explicit justification.
- Stubbed assertions (`assertTrue(true)`).
