---
name: python
description: >
  Use when working in a Python project or when the task involves Python code,
  uv, Ruff, mypy, or pytest. Triggers on: python, uv, ruff, mypy, pytest,
  pyproject.toml, py, pydantic, fastapi.
license: MIT
compatibility: opencode
---

# Python

Language-specific rules for Python projects. Load this skill when working in
any repository with a `pyproject.toml`.

## Core Principles

- Explicit over implicit — make behaviour clear in code
- `pyproject.toml` is the single source of truth for config and dependencies
- Use `uv` for all dependency and virtual-environment management
- One public concept per module

## Error Handling

- Raise specific exception types; never use a bare `except:`
- Use `contextlib.suppress` for deliberate, intentional suppression
- Prefer typed `dataclass` / `pydantic` models over raw `dict` for structured
  data and error states in larger systems
- Never swallow exceptions silently — always log, handle, or re-raise

## Idiomatic Python

- `snake_case` for functions and variables; `PascalCase` for classes;
  `UPPER_SNAKE_CASE` for constants; `_private` prefix for internal names
- Type-annotate every function signature (parameters and return type)
- Prefer `dataclass` / `pydantic` over raw `dict` for structured data
- Guard module-level entry code with `if __name__ == "__main__":`

## Tooling

- Use `uv` for dependency management and virtual environments:
  `uv add`, `uv run`, `uv sync`
- Run `ruff check` and `ruff format` before declaring done
  (these replace `flake8`, `black`, and `isort`)
- Run `mypy` and fix all reported type errors
- Always run inside the Nix dev shell if a `flake.nix` is present:
  `nix develop --command <cmd>`

## Testing

- Use `pytest` as the test runner
- Measure coverage with `pytest-cov` and target ≥ 90%
- Use `@pytest.mark.parametrize` for table-driven tests
- Isolate external dependencies with `unittest.mock` / `pytest-mock`
- Name tests as observable behaviour: `test_returns_error_on_empty_input`

## Code Review

- Flag bare `except:` clauses
- Flag untyped function signatures
- Flag mutable default arguments (e.g. `def f(x=[])`)
- Flag missing `if __name__ == "__main__":` guard in runnable scripts

## Code Generation

- Always generate runnable code
- No `pass` stubs in production paths
- Include all `import` statements at the top of the file
- Add a docstring to every public module, class, and function
