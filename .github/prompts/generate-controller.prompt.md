# Prompt: Generate Spring Boot Controller

You are generating a single `@RestController` for an AIDLC microservice.

## Inputs

```
{{microservice}}  — service name in kebab-case
{{entity}}        — entity name in PascalCase
{{endpoints}}     — array of { method, path, request, response, status, auth }
```

## Output

Produce one Java file at:
`src/main/java/com/example/{{microservice}}/controller/{{entity}}Controller.java`

## Template

```java
package com.example.{{microservice}}.controller;

import com.example.{{microservice}}.dto.*;
import com.example.{{microservice}}.service.{{entity}}Service;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST API for {{entity}} operations.
 */
@RestController
@RequestMapping("/api/{{microservice}}/{{entity-plural}}")
public class {{entity}}Controller {

    private final {{entity}}Service service;

    public {{entity}}Controller({{entity}}Service service) {
        this.service = service;
    }

    {{#each endpoints}}
    /**
     * {{description}}
     */
    @{{method}}Mapping({{#if path}}"{{path}}"{{/if}})
    @ResponseStatus(HttpStatus.{{status}})
    @PreAuthorize("{{auth}}")
    public {{response}} {{operation}}({{params}}) {
        return service.{{operation}}({{argList}});
    }
    {{/each}}
}
```

## Rules

- Constructor injection only.
- Validate every body with `@Valid`.
- Validate every path/query param with `jakarta.validation` annotations directly on the param.
- Status codes: `200` GET, `201` POST, `204` DELETE / no-content PUT, `200` PUT-with-body.
- Every method has Javadoc.
- Never inline business logic — delegate to the service.
- Never catch exceptions here — `@RestControllerAdvice` handles them globally.
