# Project Rules

- Always run build tools in the Nix development shell (`nix develop . --command <cmd>`)
  when a `flake.nix` is present.
- Prefer the Result pattern for error handling.
- Use named exports only.
- Follow conventional commits for commit messages.
- Always run typecheck, lint, and tests before considering work complete.
