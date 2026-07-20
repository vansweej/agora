---
name: go
description: >
  Use when working in a Go project or when the task involves Go code, modules,
  or goroutines. Triggers on: go, golang, go.mod, go.sum, goroutine,
  golangci-lint, gofmt, goimports.
license: MIT
compatibility: opencode
---

# Go

Language-specific rules for Go projects. Load this skill when working in any
repository with a `go.mod`.

## Core Principles

- Clarity over cleverness — the code's purpose and rationale must be clear
- Name length proportional to scope — short scopes get short names
- `gofmt` formatting is non-negotiable — all Go source must match its output
- Prefer the standard library over adding external dependencies
- Handle errors before proceeding (early return, no `else` after a terminal `if`)

## Error Handling

- `error` is always the last return value in a function signature
- Wrap errors with `fmt.Errorf("context: %w", err)` to preserve the error chain
- Inspect wrapped errors with `errors.Is` / `errors.As`
- Never discard errors with `_` without a comment explaining why it is safe
- Do not use in-band sentinel values (e.g. returning `-1` to signal failure)

## Concurrency

- Prefer channels over shared memory; document the lifetime of every goroutine
- Cancel `context.Context` explicitly — always respect cancellation
- Use `sync.WaitGroup` or `errgroup` for fan-out patterns
- Never start a goroutine without a clear shutdown path

## Idiomatic Go

- Use `MixedCaps` / `mixedCaps` — never `snake_case` or `SCREAMING_SNAKE_CASE`
  (a constant is `MaxLength`, not `MAX_LENGTH`)
- Short receiver names (1–2 letters, consistent per type)
- No `Get` prefix on getters — name by the noun directly (e.g. `Counts` not `GetCounts`)
- Package names: lowercase, single word, no underscores
- Initialisms keep one case: `URL`, `ID`, `DB`, `HTTP`

## Build & Tooling

- Run `go build ./...` and `go vet ./...` before declaring done
- Format with `gofmt -s -w .` and run `goimports`
- Run `golangci-lint run` and fix all findings
- Standard project layout: `cmd/` for binaries, package directories for libraries
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Testing

- Use the built-in `testing` package
- `testify/assert` is acceptable for richer assertions
- Write table-driven tests with `t.Run` subtests
- Target ≥ 90% coverage with `go test -coverprofile=coverage.out ./...`
- Use the `_test` package suffix for black-box tests

## Code Review

- Flag goroutines with no documented lifetime or shutdown path
- Flag errors discarded with `_` without justification
- Flag `panic` in library code (acceptable only in `main` or init)
- Flag non-`MixedCaps` names
- Flag exported symbols missing a doc comment

## Code Generation

- Always generate compilable code
- No `// TODO` stubs in production paths
- Include all `import` declarations
- Output `gofmt`-compliant formatting
- Begin every exported symbol's doc comment with the symbol name
  (e.g. `// Encode writes the JSON encoding of req to w.`)
