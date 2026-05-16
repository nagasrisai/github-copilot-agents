---
applyTo: '**'
description: 'Self-contained offline reference for Java 8->21 and Spring Boot 2.x->3.x upgrade paths. The only source of truth for upgrade transformations.'
---

# Java & Spring Boot Upgrade Playbook (Offline Reference)

Complete reference for upgrading Java and Spring Boot versions **without internet access**. The `upgrade-agent` reads from this file; nothing here may require external lookup.

---

## Supported upgrade paths

| From | To | Difficulty | Reference section |
|---|---|---|---|
| Java 8 | Java 11 | Medium | [§J8→J11](#java-8--java-11) |
| Java 11 | Java 17 | Medium | [§J11→J17](#java-11--java-17) |
| Java 17 | Java 21 | Low | [§J17→J21](#java-17--java-21) |
| Spring Boot 2.5.x → 2.7.x | Same major | Low | [§SB2x→2.7](#spring-boot-25x--27x) |
| Spring Boot 2.7.x | Spring Boot 3.0.x | **High** | [§SB2.7→3.0](#spring-boot-27x--30x-major) |
| Spring Boot 3.0.x | 3.2.x | Medium | [§SB3.0→3.2](#spring-boot-30x--32x) |
| Spring Boot 3.2.x | 3.3.x | Low | [§SB3.2→3.3](#spring-boot-32x--33x) |

Always upgrade Java **first**, then Spring Boot. Never skip major Spring Boot versions.

---

## Algorithm (the upgrade-agent must follow this exactly)

```
1. SNAPSHOT
   - mvn -o dependency:tree > runs/<id>/before-deps.txt
   - java -version 2>&1 > runs/<id>/before-java.txt
   - record current spring-boot.version from pom.xml

2. PRECHECK
   - bash scripts/upgrade-precheck.sh <fromJava> <toJava> <fromSB> <toSB>
   - confirms required Maven plugins / JDKs are present in local toolchain

3. PLAN
   - load the matching section of this playbook
   - produce runs/<id>/upgrade-plan.md with: pom.xml edits, code rewrites,
     test rewrites, expected breaking changes for THIS codebase

4. HUMAN CHECKPOINT C3
   - present the plan, await user approval

5. APPLY (per upgrade step in plan)
   a. edit files
   b. mvn -o -B clean compile         (fix compile errors before moving on)
   c. mvn -o -B test                  (fix test failures)
   d. commit: "refactor(upgrade): <step description>"

6. VERIFY
   - mvn -o -B verify
   - jacoco line coverage must still be ≥ 90%
   - run E2E suite

7. SNAPSHOT AFTER
   - mvn -o dependency:tree > runs/<id>/after-deps.txt

8. PROCEED to Stage 7 (Sonar/Nexus/Review) of the main flow
```

If any step fails, halt and surface the error. Do not "fix forward" without a clear plan.

---

## Java 8 → Java 11

### pom.xml

```xml
<properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
    <java.version>11</java.version>
</properties>
```

### Mandatory dependency additions

Java 11 removed Java EE modules. Add explicit dependencies if used:

| Removed module | Replacement |
|---|---|
| `javax.xml.bind` (JAXB) | `org.glassfish.jaxb:jaxb-runtime` + `jakarta.xml.bind:jakarta.xml.bind-api` |
| `javax.activation` | `jakarta.activation:jakarta.activation-api` |
| `javax.annotation` | `jakarta.annotation:jakarta.annotation-api` |
| `javax.transaction` | `jakarta.transaction:jakarta.transaction-api` |
| `java.corba` | No replacement — refactor required |

### Code changes

- Replace `sun.misc.*`, `sun.reflect.*` usages — they're encapsulated. Use `MethodHandles` or `VarHandle`.
- `String.repeat(int)` is now available — replace manual loops.
- HTTP: prefer `java.net.http.HttpClient` over `HttpURLConnection`.

### Common compile errors

- `package javax.xml.bind does not exist` → add JAXB dependency.
- `package sun.misc does not exist` → use public API equivalents.

---

## Java 11 → Java 17

### pom.xml

```xml
<properties>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
    <java.version>17</java.version>
</properties>
```

Add `--add-opens` flags if reflection on JDK internals is used (common with older libraries like Lombok < 1.18.22, Mockito < 4.0):

```xml
<plugin>
  <artifactId>maven-surefire-plugin</artifactId>
  <configuration>
    <argLine>
      --add-opens java.base/java.lang=ALL-UNNAMED
      --add-opens java.base/java.util=ALL-UNNAMED
    </argLine>
  </configuration>
</plugin>
```

### Language features now available

- **Sealed classes** — use for closed hierarchies.
- **Pattern matching for `instanceof`** — replace explicit casts.
- **Records** — replace POJO DTOs.
- **Text blocks** — replace concatenated strings for SQL / JSON.
- **`switch` expressions** — replace `switch` statements where every branch returns.

The upgrade-agent **must** propose (not force) these idiom upgrades for high-traffic files. Show before/after diffs to the user.

### Library version floor

| Library | Minimum version for Java 17 |
|---|---|
| Mockito | 4.0.0 |
| Lombok | 1.18.22 |
| Jackson | 2.13.0 |
| Spring Framework | 5.3.x |
| Spring Boot | 2.5.6 |

---

## Java 17 → Java 21

### pom.xml

```xml
<properties>
    <maven.compiler.source>21</maven.compiler.source>
    <maven.compiler.target>21</maven.compiler.target>
    <java.version>21</java.version>
</properties>
```

Almost zero forced changes. Optional adoptions:

- **Virtual threads** (`Thread.ofVirtual().start(...)`) — for I/O-bound tasks.
- **Pattern matching for `switch`** (final, no longer preview).
- **Record patterns** (final).
- **Sequenced collections** (`SequencedCollection`, `getFirst()`, `getLast()`).

### Library floor

| Library | Minimum |
|---|---|
| Spring Boot | 3.2.0 (3.3.x recommended) |
| Mockito | 5.7.0 |
| Lombok | 1.18.30 |

---

## Spring Boot 2.5.x → 2.7.x

Same major, mostly safe.

### Notable deprecations

- `WebSecurityConfigurerAdapter` is deprecated — migrate to `SecurityFilterChain` bean.
- `@MockBean` usage with `@SpringBootTest` is fine but prefer `@MockitoBean` in newer versions.
- `spring.datasource.initialization-mode` → use `spring.sql.init.mode`.

### pom.xml

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.18</version>
</parent>
```

2.7.18 is the final 2.x. Stop here if you cannot do the 3.0 jump yet.

---

## Spring Boot 2.7.x → 3.0.x (MAJOR)

This is the **hardest** upgrade in the matrix. Read the whole section.

### Hard prerequisites

- Java 17 minimum.
- All Jakarta-incompatible libraries must have Jakarta-ready versions in the local Maven repo.

### Top breaking changes

#### 1. `javax.*` → `jakarta.*` (universal rename)

Every import of:
- `javax.servlet.*` → `jakarta.servlet.*`
- `javax.persistence.*` → `jakarta.persistence.*`
- `javax.validation.*` → `jakarta.validation.*`
- `javax.transaction.*` → `jakarta.transaction.*`
- `javax.annotation.PostConstruct/PreDestroy` → `jakarta.annotation.*`
- `javax.ws.rs.*` → `jakarta.ws.rs.*`

Mechanical refactor. The upgrade-agent runs this rewrite **per file**, commits per package, then compiles.

#### 2. Spring Security 6

- `WebSecurityConfigurerAdapter` is **removed**. Define a `SecurityFilterChain` bean:

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/public/**").permitAll()
            .anyRequest().authenticated())
        .httpBasic(Customizer.withDefaults())
        .csrf(csrf -> csrf.disable());
    return http.build();
}
```

- `authorizeRequests()` → `authorizeHttpRequests()`.
- `antMatchers()` → `requestMatchers()`.
- Method-level security: `@EnableMethodSecurity(prePostEnabled = true)` replaces `@EnableGlobalMethodSecurity`.

#### 3. Hibernate 6

- `org.hibernate.engine.spi.SharedSessionContractImplementor` parameter signatures changed in custom `UserType` implementations.
- `@Type(type = "json")` → `@JdbcTypeCode(SqlTypes.JSON)`.
- Native query result mappings: `List<Object[]>` ordering changed in some edge cases — re-verify.

#### 4. Configuration property migration

Run the Spring Boot migrator (offline-bundled in `tools/spring-boot-migrator.jar`) or apply manually:

| 2.7 property | 3.0 property |
|---|---|
| `spring.redis.*` | `spring.data.redis.*` |
| `spring.kafka.streams.cache-max-size-buffering` | `spring.kafka.streams.state-store-cache-max-size` |
| `server.servlet.session.persistent` | `server.servlet.session.persistent` (unchanged) |
| `management.metrics.export.*` | `management.<vendor>.metrics.export.*` |

#### 5. Trailing slash matching

Spring MVC no longer matches `/foo/` against a `/foo` mapping. Either:

- Add explicit mappings, or
- Set `mvc.setUseTrailingSlashMatch(true)` (deprecated but works) in a `WebMvcConfigurer`.

The upgrade-agent must scan controllers and surface every endpoint that could regress.

#### 6. Logback / SLF4J

- SLF4J 2.0 — providers auto-discovered via `META-INF/services` (no more `StaticLoggerBinder`).
- `logback.xml` syntax unchanged.

### Step-by-step order (do NOT reorder)

1. Java 17 confirmed.
2. Bump `<spring-boot.version>` to `3.0.13`.
3. Rename `javax.*` → `jakarta.*` package by package; commit after each compiles.
4. Migrate Spring Security config to `SecurityFilterChain`.
5. Fix Hibernate 6 changes (type registry, dialect classes).
6. Apply property migrations.
7. Run unit tests; fix failures.
8. Run E2E tests; fix failures.
9. Re-check coverage ≥ 90%.

---

## Spring Boot 3.0.x → 3.2.x

### Step

Bump version to `3.2.5`. Java 17 minimum (Java 21 supported).

### Notable changes

- Observation API (`io.micrometer.observation.*`) replaces older `@Timed` patterns.
- `RestClient` introduced in 3.2 — preferred over `RestTemplate` for new code. Do not auto-migrate existing `RestTemplate` usage.
- Spring Security 6.2 — `lambda DSL` is now the only style.

### Likely test fixes

- `@MockBean` continues to work; `@MockitoBean` introduced as future-proof alias.

---

## Spring Boot 3.2.x → 3.3.x

Low-risk. Bump to `3.3.5`. Notable:

- Virtual threads supported in Tomcat via `spring.threads.virtual.enabled=true` (requires Java 21).
- `RestClient.Builder` exposed as bean.
- Improvements to `@ConfigurationProperties` validation.

---

## Per-step commit template

Always one logical step per commit:

```
refactor(upgrade): rename javax.persistence to jakarta.persistence in entity package
refactor(upgrade): replace WebSecurityConfigurerAdapter with SecurityFilterChain
chore(upgrade): bump spring-boot.version to 3.0.13
```

Never combine the Java bump and the Spring Boot bump in one commit.

---

## What the upgrade-agent never does

- Never upgrades to a version not in the supported table above.
- Never downgrades Mockito, Jackson, or Lombok silently to make code compile — surfaces the version conflict.
- Never disables tests to make the build pass.
- Never modifies `pom.xml` outside the documented properties / dependencies for the upgrade.
- Never adds new business logic during an upgrade — purely mechanical.
