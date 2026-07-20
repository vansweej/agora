---
name: rust
description: >
  Use when working in a Rust project or when the task involves Rust code,
  cargo, crates, or Cargo.toml. Triggers on: rust, cargo, crate, Cargo.toml,
  rustc, clippy, tarpaulin, rustfmt.
license: MIT
compatibility: opencode
---

# Rust

Language-specific rules for Rust projects. Load this skill when working in
any repository that uses Cargo.

## Core Principles

- Prefer ownership and borrowing over cloning
- Avoid `unwrap()` and `expect()` in production code — use `?` or handle explicitly
- Use `Result<T, E>` and `Option<T>` for error handling
- Favor immutability by default (`let` over `let mut`)
- Keep functions small and composable

## Error Handling

- Use the `?` operator for propagation
- Define custom error types when needed (e.g. with `thiserror`)
- Avoid panics in library code
- Never silently discard errors — always propagate or handle

## Performance & Memory

- Avoid unnecessary heap allocations
- Prefer slices (`&[T]`, `&str`) over owned collections when borrowing suffices
- Avoid cloning unless necessary — prefer borrowing
- Profile before optimizing; do not guess at bottlenecks

## Idiomatic Rust

- Use `match` for exhaustive pattern matching
- Follow Rust naming conventions: `snake_case` for functions/variables,
  `PascalCase` for types, `SCREAMING_SNAKE_CASE` for constants
- Implement common traits where appropriate: `Debug`, `Clone`, `Default`,
  `Display`, `From`/`Into`
- Prefer iterators and combinators over manual loops

## Concurrency & Async

- Prefer `async`/`await` for async code
- Avoid shared mutable state; use message passing (channels) over locks where possible
- Use `Arc<Mutex<T>>` only when shared ownership with mutation is truly required
- Document `Send`/`Sync` bounds clearly

## Code Quality & Tooling

- Run `cargo fmt` before declaring done; fix all formatting issues
- Run `cargo clippy -- -D warnings` before declaring done; fix all warnings
- Run `cargo tarpaulin` and target ≥ 90% coverage
- Exclude UI and GPU/CUDA functions from coverage with `#[cfg(not(tarpaulin_include))]`
- Always run inside the Nix dev shell if a `flake.nix` is present: `nix develop --command <cmd>`

## Safety

- Minimize `unsafe` usage
- Every `unsafe` block must have a `// SAFETY:` comment explaining the invariant upheld
- Prefer safe abstractions over raw pointer manipulation

## Testing

- Use `#[cfg(test)]` modules for unit tests; keep integration tests under `tests/`
- Run `cargo tarpaulin` after writing tests; target ≥ 90% coverage
- Use `cargo test -- --nocapture` when debugging test output
- Name tests as observable behaviour: `fn returns_error_on_empty_input()`

## Code Review

- Flag any `unwrap()` or `expect()` in production code (not in tests)
- Flag `unsafe` blocks missing a `// SAFETY:` comment
- Check for clippy warnings: unnecessary clones, unused results, etc.
- Verify `cargo tarpaulin` coverage is not regressing below 90%

## Code Generation

- Always generate compilable code
- Avoid placeholders or `todo!()` stubs in production paths
- Prefer clarity over cleverness
- Include all necessary `use` imports — do not rely on implicit prelude items beyond the standard prelude
