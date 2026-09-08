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
  plan request — load and drive it through the `workflow-explore` skill. Ground
  via the `explore` subagent before answering; never emit an ungrounded or
  hallucinated plan.
- Do not substitute an ad-hoc investigation or ask whether to proceed: follow
  the skill's procedure through its confirm gate.
- This does NOT apply to bare factual questions, quick lookups, or casual
  chat — answer those directly.
- See the `workflow-explore` skill for the full procedure; do not restate it
  here.
