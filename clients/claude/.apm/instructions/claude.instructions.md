---
description: General AI-OS rules that apply to all work in Claude Code, regardless of language or project.
---

# Project Rules

- Always run build tools in the Nix development shell (`nix develop . --command <cmd>`)
  when a `flake.nix` is present.
- Prefer the Result pattern for error handling.
- Use named exports only.
- Follow conventional commits for commit messages.
- Always run typecheck, lint, and tests before considering work complete.

## Real-work turns

- When the user brings real work — a task, feature, bug, investigation, or
  plan request — tell them to run `/workflow-explore`. It drives the complete
  explore → plan ↔ spar → stored-plan workflow.
- Do not half-run that workflow or substitute an ad-hoc grounding-then-freeform
  plan: do not invoke `explore` or another specialist outside
  `/workflow-explore`. Either the user invokes the skill, or answer as an
  ordinary turn.
- This does NOT apply to bare factual questions, quick lookups, or casual
  chat — answer those directly.
- See the `workflow-explore` skill for the full procedure.
