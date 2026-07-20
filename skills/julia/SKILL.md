---
name: julia
description: >
  Use when working in a Julia project or when the task involves Julia code,
  Pkg, or the Julia REPL. Triggers on: julia, pkg, Project.toml, Manifest.toml,
  juliaformatter, runtests.jl, test.jl.
license: MIT
compatibility: opencode
---

# Julia

Language-specific rules for Julia projects. Load this skill when working in
any repository with a `Project.toml`.

## Core Principles

- Write functions, not top-level scripts — top-level code bypasses the
  optimizing compiler
- Pass arguments rather than mutating global variables
- Use 4-space indentation
- Append `!` to the names of functions that mutate their arguments
  (e.g. `sort!`, `push!`)

## Error Handling

- Don't overuse `try/catch` — it is better to avoid errors than to catch them
- Prefer `Union{T, Nothing}` returning `nothing` for absent values
- Use `@assert` only for internal invariants, not for user-facing validation
- Never silence errors silently — always propagate or handle

## Performance

- Use `@code_warntype` to detect type instabilities
- Avoid untyped global variables (or mark them `const`)
- Preallocate with `similar` or `zeros` in hot loops
- Benchmark with `BenchmarkTools.@benchmark` before optimizing
- Use `Revise.jl` during interactive development for fast iteration

## Idiomatic Julia

- `lowercase` / `snake_case` for functions; `UpperCamelCase` for types and modules
- Avoid overly-concrete type annotations in function signatures — prefer
  abstract types like `Integer`, `AbstractArray` for genericity (duck typing)
- Avoid type piracy — do not extend Base methods on types you do not own
- Don't parenthesize `if` / `while` conditions
- Don't overuse `...` splatting

## Tooling

- Run tests with: `julia --project=. -e "using Pkg; Pkg.test()"`
- Format all code with `JuliaFormatter.format(".")` before declaring done
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Testing

- Use the standard `Test` library (`@test`, `@testset`)
- Place the test entry point at `test/runtests.jl`
- Target ≥ 90% coverage with `Coverage.jl`
- Name each `@testset` after the function or module under test

## Code Review

- Flag untyped (non-`const`) global variables
- Flag type piracy — extending methods on types from other packages
- Flag `eval` called inside a function or macro
- Flag mutating functions missing the `!` suffix
- Flag overly-specific argument types that needlessly restrict callers

## Code Generation

- Always generate runnable code
- No placeholder function bodies in production paths
- Include all `using` / `import` statements
- Add a docstring (`"""..."""`) above every exported function and type
