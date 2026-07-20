---
name: typescript
description: >
  TypeScript and Bun conventions for this project: formatting (Biome),
  naming, imports, type rules, error handling, and test structure.
  Triggers on: typescript, ts, bun, biome, test, interface, type, Result.
license: MIT
compatibility: opencode
---

# TypeScript

## Formatting (enforced by Biome)

- 2-space indentation
- Semicolons: **always**
- Double quotes for strings
- Trailing commas in multi-line constructs
- Max line width: 100 characters

## Naming Conventions

| Element               | Convention      | Example                         |
|-----------------------|-----------------|---------------------------------|
| Files and directories | `kebab-case`    | `model-router/select-model.ts`  |
| Functions and vars    | `camelCase`     | `selectModel`, `eventId`        |
| Types and interfaces  | `PascalCase`    | `AIRequestEvent`, `AIAction`    |
| Type aliases          | `PascalCase`    | `AIModeHint`                    |
| Constants             | `UPPER_SNAKE`   | `MAX_RETRIES`, `DEFAULT_MODEL`  |
| Enums                 | `PascalCase`    | `ModelTier.Local`               |
| Test files            | `*.test.ts`     | `select-model.test.ts`          |

## Imports

Order imports in this sequence, separated by blank lines:

1. External packages — `import { z } from "zod";`
2. Workspace aliases — `import { ... } from "@ai-coding/shared";`
3. Relative imports — `import { selectModel } from "./select-model";`

Use **named exports** exclusively. Default exports are forbidden.

```typescript
// Good
export function selectModel(event: AIRequestEvent, mode: AIModeHint): string { ... }

// Bad — never use default exports
export default function selectModel(...) { ... }
```

## TypeScript

- Enable `strict: true` in `tsconfig.json`
- Always annotate function parameters and return types explicitly
- Use `type` for unions and aliases; use `interface` for object shapes
- Use `readonly` for properties that must not be reassigned after construction
- Avoid `any`; use `unknown` when the type is truly unknown
- Avoid type assertions (`as`); prefer type guards or narrowing

```typescript
// Good — fully typed, named export, early returns
export function resolveModelForRole(role: ModelRole, profile: ModelProfile): string {
  return profile.roles[role];
}
```

## Error Handling

- Define typed error classes or discriminated unions for error states
- Never swallow errors silently
- Use early-return guard clauses to reduce nesting
- For functions that can fail predictably, prefer the `Result` pattern:

```typescript
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };

function parseEvent(raw: unknown): Result<AIRequestEvent> {
  if (!isValidEvent(raw)) {
    return { ok: false, error: new Error("Invalid event shape") };
  }
  return { ok: true, value: raw };
}
```

## Comments

- Use `//` for inline explanations of *why*, not *what*
- Use JSDoc (`/** ... */`) on all exported functions and types

## Testing Conventions

- Co-locate test files next to source: `select-model.test.ts` beside `select-model.ts`
- Use Bun's built-in test runner (`bun:test`) — not Jest, Vitest, or any other
- Structure tests with `describe` / `it` blocks
- One logical assertion per `it` block when practical
- Name tests as observable behavior: `"returns local model in editor mode"`

```typescript
import { describe, expect, it } from "bun:test";

import { LOCAL_PROFILE } from "@ai-system/config/model-profiles";

import { resolveModelForRole } from "./model-profiles";

describe("resolveModelForRole", () => {
  it("returns gemma4:26b for planner in local", () => {
    expect(resolveModelForRole("planner", LOCAL_PROFILE)).toBe("gemma4:26b");
  });

  it("returns gemma4:26b for implementer in local", () => {
    expect(resolveModelForRole("implementer", LOCAL_PROFILE)).toBe("gemma4:26b");
  });
});
```
