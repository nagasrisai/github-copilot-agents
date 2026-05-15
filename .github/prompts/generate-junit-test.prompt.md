---
mode: 'agent'
description: 'Generate JUnit 5 + Mockito unit tests for a target class, aiming for high line coverage.'
---

# Prompt: Generate JUnit 5 Test Class

You are generating a single test class to maximize line coverage of one production class.

## Inputs

```
{{className}}      — fully qualified class under test
{{classType}}      — controller | service | repository | mapper | config
{{sourceCode}}     — full source of the class under test
{{uncoveredLines}} — (on iteration N≥2) list of uncovered line numbers from JaCoCo
```

## Output

`src/test/java/<package>/{{simpleName}}Test.java`

## Strategy by Class Type

### Controller (`@WebMvcTest`)

```java
@WebMvcTest({{simpleName}}.class)
class {{simpleName}}Test {
    @Autowired private MockMvc mockMvc;
    @MockBean private {{ServiceClass}} service;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void shouldReturn201_whenCreateRequestIsValid() throws Exception { ... }

    @Test
    void shouldReturn400_whenRequestBodyFailsValidation() throws Exception { ... }

    @Test
    void shouldReturn404_whenEntityNotFound() throws Exception { ... }
}
```

### Service (Mockito)

```java
@ExtendWith(MockitoExtension.class)
class {{simpleName}}Test {
    @Mock private {{RepoClass}} repository;
    @Mock private {{MapperClass}} mapper;
    @InjectMocks private {{simpleName}} service;

    @Test
    void shouldReturnEntity_whenFoundById() { ... }

    @Test
    void shouldThrowEntityNotFoundException_whenIdMissing() { ... }
}
```

### Repository (`@DataJpaTest` + Testcontainers)

```java
@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class {{simpleName}}Test {
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void props(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired private {{simpleName}} repository;
    // tests
}
```

## Coverage Rules

- Cover **every branch** of every `if` / `switch` / ternary.
- Cover **every exception path** thrown by the class.
- Cover **every public method** with at least 1 happy + 1 sad test.
- Boundary values: empty collections, nulls (where legal), max lengths, negative numbers.

## Forbidden

- `assertTrue(true)` or comment-only test methods.
- `Thread.sleep(...)`.
- Real HTTP / real DB outside Testcontainers.
- `@Disabled` without a linked ticket.
