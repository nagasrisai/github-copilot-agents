---
mode: 'agent'
description: 'Generate a JPA entity with appropriate annotations and constraints.'
---

# Prompt: Generate JPA Entity + Repository + DTOs

You are generating the persistence layer for one aggregate.

## Inputs

```
{{microservice}}  — service name
{{entity}}        — entity name in PascalCase
{{table}}         — snake_case table name
{{fields}}        — array of { name, javaType, columnName, nullable, length, validation }
{{relationships}} — array of { type: OneToMany|ManyToOne|ManyToMany, target, cascade, fetch }
```

## Output Files

1. `entity/{{entity}}Entity.java`
2. `repository/{{entity}}Repository.java`
3. `dto/Create{{entity}}Request.java` (record)
4. `dto/Update{{entity}}Request.java` (record)
5. `dto/{{entity}}Dto.java` (record — response shape)
6. `mapper/{{entity}}Mapper.java`

## Entity Template

```java
@Entity
@Table(name = "{{table}}")
@EntityListeners(AuditingEntityListener.class)
public class {{entity}}Entity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    {{#each fields}}
    @Column(name = "{{columnName}}", nullable = {{nullable}}{{#if length}}, length = {{length}}{{/if}})
    private {{javaType}} {{name}};
    {{/each}}

    @Version
    private Long version;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // getters, setters, equals (id only), hashCode (id only)
}
```

## Repository Template

```java
public interface {{entity}}Repository extends JpaRepository<{{entity}}Entity, Long> {
    // custom finders inferred from architect's queries spec
}
```

## DTO Template (record)

```java
public record {{entity}}Dto(
    Long id,
    {{#each fields}}{{javaType}} {{name}},{{/each}}
    Instant createdAt,
    Instant updatedAt
) {}
```

## Rules

- All DTOs are records.
- Equals/hashCode on entities compare ID only (avoid Set/HashCode bugs).
- Never expose the entity directly from a controller — always map to DTO.
- `@Version` field for optimistic locking.
- Audit columns auto-managed via `AuditingEntityListener`.
- Validation annotations on the *request* DTOs, not the entity.
