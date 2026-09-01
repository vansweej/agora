---
name: ruby
description: >
  Use when working in a Ruby project or when the task involves Ruby code,
  Bundler, RuboCop, or RSpec. Triggers on: ruby, rb, gem, Gemfile, bundler,
  rubocop, rspec, minitest, rake, sorbet.
---

<!-- DO NOT EDIT — generated from .apm/skills/ruby/SKILL.md by agora/renderers/opencode-to-claude.md -->

# Ruby

Language-specific rules for Ruby projects. Load this skill when working in
any repository with a `Gemfile`.

## Core Principles

- Convention over configuration
- Favour expressiveness and readability over cleverness
- Keep methods short (< 10 lines preferred)
- One public responsibility per class

## Error Handling

- Raise specific exception classes; never rescue `Exception` (use `StandardError`)
- Avoid bare `rescue` without specifying the exception type
- Use custom exception hierarchies for domain-specific errors
- Never silently swallow errors — always log, handle, or re-raise

## Idiomatic Ruby

- `snake_case` for methods and variables; `PascalCase` for classes/modules;
  `UPPER_SNAKE_CASE` for constants
- Prefer symbols over strings for hash keys
- Use `frozen_string_literal: true` magic comment at the top of every file
- Prefer blocks, `map`, `select`, `reject` over manual loops
- Use guard clauses for early returns
- Prefer `&&` / `||` over `and` / `or` in boolean expressions
- Use `%w[]` and `%i[]` for word and symbol arrays

## Typing (Sorbet / RBS)

- Add Sorbet `sig` annotations or RBS type signatures when the project uses them
- Prefer `T.nilable(X)` over unchecked nil access
- Use `T::Struct` for value objects when Sorbet is available

## Tooling

- Use `bundler` for dependency management: `bundle add`, `bundle exec`
- Run `rubocop -A` before declaring done; fix all offences
- Run `bundle exec rspec` or `bundle exec rake test` for tests
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Testing

- Use RSpec or Minitest (follow the project's existing choice)
- Measure coverage with `simplecov` and target >= 90%
- Use `let` / `let!` for lazy/eager setup in RSpec
- Use `context` blocks to group scenarios; `describe` for the unit under test
- Name examples as observable behaviour: `it "returns an error when input is empty"`
- Isolate external dependencies with doubles/mocks

## Code Review

- Flag bare `rescue` without a specific exception class
- Flag methods longer than 15 lines
- Flag missing `frozen_string_literal: true`
- Flag mutable constants (should be frozen)
- Check that `rubocop` passes cleanly

## Code Generation

- Always generate runnable code
- No `raise NotImplementedError` stubs in production paths
- Include all necessary `require` statements at the top
- Prefer keyword arguments for methods with more than 2 parameters
