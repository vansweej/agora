---
name: haskell
description: >
  Use when working in a Haskell project or when the task involves Haskell code,
  Stack, Cabal, or GHC. Triggers on: haskell, stack, cabal, ghc, hlint, ormolu,
  hspec, quickcheck, stack.yaml, .cabal.
license: MIT
compatibility: opencode
---

# Haskell

Language-specific rules for Haskell projects. Load this skill when working in
any repository that uses Stack or Cabal.

## Core Principles

- Strictly separate IO from pure logic — keep `do` blocks thin and focused
- Prefer total functions over partial ones; avoid `head`, `tail`, or `fromJust`
  without a guard or case expression
- Favour immutability by default
- Keep functions short — ideally a few lines each
- Derive `Show`, `Eq`, `Ord` where appropriate

## Error Handling

- Use `Maybe` for absent values and `Either` for recoverable errors
- Avoid `error` in library code — it panics at runtime
- Use `ExceptT` / `MonadError` in monad stacks for effectful error handling
- Never silently discard a `Left` or `Nothing` — always propagate or handle explicitly

## Performance & Memory

- Prefer `Data.Text` over `String` for production text processing
- Use strict record fields (`!`) to avoid space leaks
- Use `seq` / `deepseq` deliberately, not by reflex
- Profile before optimizing; do not guess at bottlenecks

## Idiomatic Haskell

- `lowerCamelCase` for functions and values; `UpperCamelCase` for types,
  constructors, and type classes; `SCREAMING_SNAKE_CASE` for constants
- Use `$` and `.` to reduce parentheses and improve readability
- Prefer `map`, `filter`, `foldr` over list comprehensions when the
  higher-order version is clearer
- Use `where` for local bindings; keep the `where` block minimal
- Import `Data.Map` and `Data.Set` qualified to avoid name clashes

## Code Quality & Tooling

- Run `stack build` and `stack test` before declaring done
- Run `ormolu` (or `fourmolu`) and fix all formatting issues
- Run `hlint` and fix all suggestions
- `cabal` is an acceptable alternative to `stack`
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Testing

- Use `hspec` for unit tests and `QuickCheck` for property-based testing
- Place test files under `test/`
- Target ≥ 90% coverage measured with `hpc` (via `stack test --coverage`)
- Name specs as observable behaviour: `"returns error on empty input"`

## Code Review

- Flag `head`, `tail`, `fromJust`, and `fromLeft` without a guard or case
- Flag missing type signatures on exported functions
- Flag `unsafePerformIO` without a `-- SAFETY:` comment explaining the invariant
- Flag commented-out or dead code — remove it instead

## Code Generation

- Always generate compilable code
- No `undefined` or stub bindings in production paths
- Supply type signatures for all top-level functions
- Include all necessary `import` statements — do not rely on transitive imports
- Put a Haddock comment (`-- |`) on every exported function and data type
