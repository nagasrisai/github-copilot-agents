# Prompt: Generate Spring Boot Service Layer

You are generating a single `@Service` class for an AIDLC microservice.

## Inputs

```
{{microservice}}  — service name
{{entity}}        — entity name in PascalCase
{{operations}}    — array of { name, input, output, description, transactional }
```

## Output

`src/main/java/com/example/{{microservice}}/service/{{entity}}Service.java`

## Template

```java
package com.example.{{microservice}}.service;

import com.example.{{microservice}}.dto.*;
import com.example.{{microservice}}.entity.{{entity}}Entity;
import com.example.{{microservice}}.exception.*;
import com.example.{{microservice}}.mapper.{{entity}}Mapper;
import com.example.{{microservice}}.repository.{{entity}}Repository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Business logic for {{entity}}.
 */
@Service
@Transactional(readOnly = true)
public class {{entity}}Service {

    private static final Logger log = LoggerFactory.getLogger({{entity}}Service.class);

    private final {{entity}}Repository repository;
    private final {{entity}}Mapper mapper;

    public {{entity}}Service({{entity}}Repository repository, {{entity}}Mapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    {{#each operations}}
    /**
     * {{description}}
     */
    {{#if transactional}}@Transactional{{/if}}
    public {{output}} {{name}}({{input}}) {
        log.info("{{name}} invoked");
        // implementation derived from architect spec
    }
    {{/each}}
}
```

## Rules

- Class-level `@Transactional(readOnly = true)` — override with `@Transactional` on writes.
- Always log INFO at method entry for write operations.
- Throw domain exceptions (`EntityNotFoundException`, `ValidationException`) — never wrap and rethrow.
- Use the mapper for entity↔DTO conversion — never convert inline.
- Never call other services' REST APIs directly; use a typed `@FeignClient` or `RestClient` defined in `config/`.
